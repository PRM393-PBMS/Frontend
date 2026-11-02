import 'dart:collection';

import 'lot_layout.dart';

/// Sơ đồ admin vẽ (cùng định dạng backend `floor-layout.ts`): lưới w×h, các ô có nội dung.
class TileCell {
  final int x;
  final int y;
  final String t;
  final String? dir;
  final String? code;
  final String? slotId;
  final String? name;
  final String? gateType;
  final String? gateId;
  final String? to;
  final int cap;

  const TileCell({
    required this.x,
    required this.y,
    required this.t,
    this.dir,
    this.code,
    this.slotId,
    this.name,
    this.gateType,
    this.gateId,
    this.to,
    this.cap = 0,
  });

  bool get isDrivable => t == 'road' || t == 'gate' || t == 'ramp';
  bool get isEntryGate => t == 'gate' && gateType != 'Exit';

  factory TileCell.fromJson(Map<String, dynamic> j) => TileCell(
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        t: '${j['t'] ?? ''}',
        dir: j['dir'] as String?,
        code: j['code'] as String?,
        slotId: j['slotId'] as String?,
        name: j['name'] as String?,
        gateType: j['gateType'] as String?,
        gateId: j['gateId'] as String?,
        to: j['to'] as String?,
        cap: (j['cap'] as num?)?.toInt() ?? 0,
      );
}

class TileFloor {
  final String floorId;
  final String floorName;
  final bool isResident;
  final int w;
  final int h;
  final List<TileCell> cells;
  late final Map<(int, int), TileCell> _at = {for (final c in cells) (c.x, c.y): c};

  TileFloor({
    required this.floorId,
    required this.floorName,
    required this.isResident,
    required this.w,
    required this.h,
    required this.cells,
  });

  TileCell? at(int x, int y) => _at[(x, y)];
  int get level => floorLevel(floorName);

  /// Phần tử từ `GET /api/FloorLayout/parking/:id`.
  static TileFloor? fromJson(Map<String, dynamic> j) {
    final layout = j['layout'];
    if (layout is! Map) return null;
    final cells = (layout['cells'] as List? ?? const [])
        .whereType<Map>()
        .map((c) => TileCell.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    return TileFloor(
      floorId: '${j['floorId'] ?? ''}',
      floorName: '${j['floorName'] ?? ''}',
      isResident: j['isResident'] == true,
      w: (layout['w'] as num?)?.toInt() ?? 0,
      h: (layout['h'] as num?)?.toInt() ?? 0,
      cells: cells,
    );
  }
}

/// Một bước trên đường đi: tầng + ô lưới.
typedef PathNode = ({String floorId, int x, int y});

const _dirs = {'N': (0, -1), 'E': (1, 0), 'S': (0, 1), 'W': (-1, 0)};
const _opposite = {'N': 'S', 'E': 'W', 'S': 'N', 'W': 'E'};
const _order = ['N', 'E', 'S', 'W'];

bool _canMove(TileCell? from, TileCell? to, String d) {
  if (from == null || to == null || !from.isDrivable || !to.isDrivable) return false;
  if (from.dir != null && from.dir != d) return false;
  return to.dir != _opposite[d];
}

/// Đường đi trong bãi theo sơ đồ admin vẽ: các tầng xếp từ dưới lên, tìm đường trên lối đi (đúng chiều lối một chiều),
/// qua dốc giữa các tầng.
class TileLot {
  final List<TileFloor> floors;

  TileLot(List<TileFloor> floors)
      : floors = [...floors]..sort((a, b) {
          final byLevel = a.level.compareTo(b.level);
          return byLevel != 0 ? byLevel : a.floorName.compareTo(b.floorName);
        });

  TileFloor? floor(String id) => floors.where((f) => f.floorId == id).firstOrNull;

  ({TileFloor floor, TileCell cell})? findSlot(String code) {
    final c = code.trim().toUpperCase();
    for (final f in floors) {
      for (final cell in f.cells) {
        if (cell.t == 'slot' && (cell.code ?? '').toUpperCase() == c) return (floor: f, cell: cell);
      }
    }
    return null;
  }

  /// Các ô dốc ở tầng [to] mà dốc (from, cell) dẫn sang: ưu tiên dốc trỏ ngược về tầng cũ.
  Iterable<PathNode> _rampExits(TileFloor from, TileCell ramp) {
    final dest = floor(ramp.to ?? '');
    if (dest == null) return const [];
    final ramps = dest.cells.where((c) => c.t == 'ramp').toList();
    final back = ramps.where((c) => c.to == from.floorId).toList();
    return (back.isNotEmpty ? back : ramps).map((c) => (floorId: dest.floorId, x: c.x, y: c.y));
  }

  /// BFS từ các cổng vào (hoặc cổng tên [gateName]) tới ô lối đi đầu tiên thoả [isGoal]. Trả đường đi (ô đầu là cổng).
  List<PathNode>? route({String? gateName, required bool Function(TileFloor floor, int x, int y) isGoal}) {
    final starts = <PathNode>[
      for (final f in floors)
        for (final c in f.cells)
          if (c.isEntryGate && (gateName == null || (c.name ?? '').toLowerCase() == gateName.toLowerCase()))
            (floorId: f.floorId, x: c.x, y: c.y),
    ];
    if (starts.isEmpty && gateName != null) return route(isGoal: isGoal);
    final prev = <PathNode, PathNode?>{for (final s in starts) s: null};
    final queue = Queue<PathNode>.of(starts);
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      final f = floor(cur.floorId)!;
      if (isGoal(f, cur.x, cur.y)) {
        final path = <PathNode>[];
        PathNode? n = cur;
        while (n != null) {
          path.add(n);
          n = prev[n];
        }
        return path.reversed.toList();
      }
      final here = f.at(cur.x, cur.y);
      final next = <PathNode>[
        for (final d in _order)
          if (_canMove(here, f.at(cur.x + _dirs[d]!.$1, cur.y + _dirs[d]!.$2), d))
            (floorId: f.floorId, x: cur.x + _dirs[d]!.$1, y: cur.y + _dirs[d]!.$2),
        if (here?.t == 'ramp') ..._rampExits(f, here!),
      ];
      for (final n in next) {
        if (prev.containsKey(n)) continue;
        prev[n] = cur;
        queue.add(n);
      }
    }
    return null;
  }

  /// Ô lối đi cạnh ô (x, y)?
  static bool beside(int x, int y, int tx, int ty) => (x - tx).abs() + (y - ty).abs() == 1;
}

/// Kết quả chỉ đường theo sơ đồ thật: đường đi (lối đi) và ô đích.
class TileGuide {
  final List<PathNode> path;
  final TileFloor? floor;
  final TileCell? slot;
  final List<String> steps;

  const TileGuide({this.path = const [], this.floor, this.slot, required this.steps});
}

/// [targetSlotCode]: ô của lượt gửi. Không có thì dẫn tới ô trống gần cổng nhất cho loại xe ([car]),
/// vì hệ thống phân ô khi xe qua cổng nên chỉ là gợi ý khu.
TileGuide buildTileGuide(
  TileLot lot, {
  String? targetSlotCode,
  String? entryGateName,
  bool car = true,
  Map<String, String> slotStatus = const {},
  Set<String> carSlotIds = const {},
}) {
  if (targetSlotCode != null && targetSlotCode.isNotEmpty) {
    final target = lot.findSlot(targetSlotCode);
    if (target == null) {
      return TileGuide(steps: ['Không tìm thấy ô $targetSlotCode trên sơ đồ. Hỏi nhân viên tại cổng để được hướng dẫn.']);
    }
    final path = lot.route(
      gateName: entryGateName,
      isGoal: (f, x, y) => f.floorId == target.floor.floorId && TileLot.beside(x, y, target.cell.x, target.cell.y),
    );
    if (path == null) {
      return TileGuide(floor: target.floor, slot: target.cell, steps: [
        'Ô ${target.cell.code} ở ${target.floor.floorName}. Sơ đồ chưa có lối đi tới ô này, hỏi nhân viên để được hướng dẫn.',
      ]);
    }
    return TileGuide(
      path: path,
      floor: target.floor,
      slot: target.cell,
      steps: describePath(lot, path, target.cell, entered: entryGateName != null),
    );
  }

  bool fits(TileCell c, TileFloor f) {
    if (f.isResident) return false;
    if (!car) return c.t == 'moto' || (c.t == 'slot' && !carSlotIds.contains(c.slotId));
    return c.t == 'slot' && (carSlotIds.isEmpty || carSlotIds.contains(c.slotId)) && slotStatus[c.slotId] == 'available';
  }

  TileCell? goal;
  TileFloor? goalFloor;
  final path = lot.route(
    gateName: entryGateName,
    isGoal: (f, x, y) {
      for (final (dx, dy) in _dirs.values) {
        final c = f.at(x + dx, y + dy);
        if (c != null && fits(c, f)) {
          goal = c;
          goalFloor = f;
          return true;
        }
      }
      return false;
    },
  );
  if (path == null || goal == null) {
    return TileGuide(steps: ['Bãi hiện không còn chỗ trống cho ${car ? 'ô tô' : 'xe máy'} có lối đi tới.']);
  }
  final steps = describePath(lot, path, goal!, entered: entryGateName != null);
  steps[steps.length - 1] = car
      ? 'Ô trống gần cổng nhất: ${goal!.code} (${goalFloor!.floorName}). Hệ thống phân ô khi xe qua cổng; mở lại sơ đồ từ lượt gửi để xem đúng ô.'
      : 'Đỗ vào khu xe máy ở ${goalFloor!.floorName}.';
  return TileGuide(path: path, floor: goalFloor, slot: goal!.t == 'slot' ? goal : null, steps: steps);
}

/// Lời chỉ đường từ đường đi: vào cổng, đi thẳng N ô, rẽ trái/phải, theo dốc lên/xuống tầng, ô ở bên tay nào.
List<String> describePath(TileLot lot, List<PathNode> path, TileCell target, {bool entered = false}) {
  final first = lot.floor(path.first.floorId)!;
  final gate = first.at(path.first.x, path.first.y);
  final steps = <String>[
    entered
        ? 'Bạn đã vào bãi qua ${gate?.name ?? 'cổng'} (${first.floorName}).'
        : 'Vào bãi qua ${gate?.name ?? 'cổng vào'} (${first.floorName}).',
  ];
  String? heading;
  var run = 0;
  void flush() {
    if (run > 0) steps.add('${steps.length == 1 ? 'Đi' : 'Đi tiếp'} $run ô.');
    run = 0;
  }

  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1], b = path[i];
    if (a.floorId != b.floorId) {
      flush();
      final from = lot.floor(a.floorId)!, to = lot.floor(b.floorId)!;
      steps.add('Theo dốc ${to.level >= from.level ? 'lên' : 'xuống'} ${to.floorName}.');
      heading = null;
      continue;
    }
    final d = _order.firstWhere((k) => _dirs[k] == (b.x - a.x, b.y - a.y));
    if (heading != null && d != heading) {
      flush();
      steps.add(_turn(heading, d));
    }
    heading = d;
    run++;
  }
  flush();
  final last = path.last;
  final toSlot = _order.firstWhere((k) => _dirs[k] == (target.x - last.x, target.y - last.y), orElse: () => 'N');
  final side = heading == null ? 'ngay cạnh' : _side(heading, toSlot);
  steps.add('Ô ${target.code ?? ''} ở $side. Đỗ vào ô này.');
  return steps;
}

String _turn(String from, String to) {
  final diff = (_order.indexOf(to) - _order.indexOf(from) + 4) % 4;
  return diff == 1 ? 'Rẽ phải.' : diff == 3 ? 'Rẽ trái.' : 'Quay đầu.';
}

String _side(String heading, String toSlot) {
  final diff = (_order.indexOf(toSlot) - _order.indexOf(heading) + 4) % 4;
  return switch (diff) { 0 => 'phía trước', 1 => 'bên tay phải', 3 => 'bên tay trái', _ => 'phía sau' };
}

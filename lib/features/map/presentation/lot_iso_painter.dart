import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/lot_layout.dart';

/// Màu ô theo trạng thái (dùng chung cho chú thích).
class LotColors {
  LotColors._();
  static const free = Color(0xFF10B981);
  static const occupied = Color(0xFF94A3B8);
  static const assigned = Color(0xFF8B5CF6);
  static const other = Color(0xFFF59E0B);
  static const target = Color(0xFFDC2626);
  static const route = Color(0xFF087B8C);
  static const slab = Color(0xFFF1F5F9);
  static const slabSide = Color(0xFFCBD5E1);
  static const aisle = Color(0xFFE2E8F0);

  static Color of(LayoutSlot s) => s.isFree
      ? free
      : s.isOccupied
          ? occupied
          : s.isAssigned
              ? assigned
              : other;
}

/// Chế độ chọn ô trên sơ đồ (vd. ô cố định khi đăng ký vé tháng): ô không chọn được vẽ mờ,
/// ô đang chọn tô đỏ; bộ vẽ ghi vùng của từng ô vào [hits] để biết khách chạm ô nào.
class SlotPickOptions {
  final String? selectedSlotId;
  final bool Function(String slotId) pickable;
  final List<(Path, String)> hits = [];

  SlotPickOptions({this.selectedSlotId, required this.pickable});

  /// Ô chọn được dưới điểm chạm; ô vẽ sau nằm trên nên xét từ cuối danh sách.
  String? slotAt(Offset point) {
    for (final (path, id) in hits.reversed) {
      if (path.contains(point) && pickable(id)) return id;
    }
    return null;
  }

  static const faded = Color(0xFFE2E8F0);
}

/// Vùng khối ô (mặt trên + hai mặt trước) để nhận chạm.
Path boxHitPath(Offset Function(double dx, double dy, double z) q, double w, double h) => Path()
  ..addPolygon([q(0, 0, h), q(w, 0, h), q(w, 0, 0), q(w, w, 0), q(0, w, 0), q(0, w, h)], true);

/// Toạ độ lưới của một tầng: lối đi chính dọc mép trái (x âm), mỗi hàng ô có lối đi phía trước.
/// Khu dài quá [perRow] ô thì xuống hàng.
class FloorGrid {
  static const perRow = 10;
  static const spine = 1.2;
  static const rowDepth = 1.0;
  static const aisle = 0.9;

  /// Mỗi hàng: (khu, các ô trong hàng, vị trí y của hàng).
  final List<(LayoutZone, List<LayoutSlot>, double)> rows;
  final int cols;

  FloorGrid._(this.rows, this.cols);

  factory FloorGrid.of(LayoutFloor floor) {
    final rows = <(LayoutZone, List<LayoutSlot>, double)>[];
    var y = aisle;
    var cols = 4;
    for (final z in floor.zones) {
      for (var i = 0; i < z.slots.length; i += perRow) {
        final part = z.slots.sublist(i, math.min(i + perRow, z.slots.length));
        rows.add((z, part, y));
        cols = math.max(cols, part.length);
        y += rowDepth + aisle;
      }
    }
    return FloorGrid._(rows, cols);
  }

  double get depth => rows.isEmpty ? 4 : rows.last.$3 + rowDepth + 0.4;

  /// Ô (cột, hàng) của [slot] nếu có trên tầng.
  (int col, double y)? cellOf(LayoutSlot slot) {
    for (final r in rows) {
      final i = r.$2.indexOf(slot);
      if (i >= 0) return (i, r.$3);
    }
    return null;
  }
}

/// Vẽ bãi kiểu isometric: các tầng chồng lên nhau (dưới trước), tầng đang chọn vẽ đủ ô,
/// tầng khác chỉ vẽ sàn mờ. Đường đi: cổng -> (dốc lên/xuống) -> lối đi chính -> lối đi của hàng -> ô.
class LotIsoPainter extends CustomPainter {
  final LotLayout lot;
  final String selectedFloorId;
  final LotGuide? guide;

  /// 0..1 lặp lại: nhấp nháy ô đích và chạy vạch đường đi.
  final double t;
  final SlotPickOptions? pick;

  LotIsoPainter({required this.lot, required this.selectedFloorId, this.guide, this.t = 0, this.pick});

  static const _cos = 0.8660254;
  static const _sin = 0.5;
  static const _levelGap = 3.4;
  static const _boxH = 0.32;

  late double _scale;
  late Offset _origin;
  late double _width;
  late double _depth;

  Offset _p(double x, double y, int level, [double z = 0]) => _origin +
      Offset((x - y) * _cos * _scale, ((x + y) * _sin - level * _levelGap - z) * _scale);

  @override
  void paint(Canvas canvas, Size size) {
    if (lot.floors.isEmpty) return;
    final grids = {for (final f in lot.floors) f.id: FloorGrid.of(f)};
    // Mọi tầng cùng khung để chồng thẳng hàng.
    _width = grids.values.map((g) => g.cols.toDouble()).reduce(math.max) + 0.4;
    _depth = grids.values.map((g) => g.depth).reduce(math.max);
    final n = lot.floors.length;

    // Khung bao (đơn vị lưới) rồi co giãn cho vừa.
    final minX = -_depth * _cos - FloorGrid.spine * _cos;
    final maxX = _width * _cos;
    final minY = -(n - 1) * _levelGap - 1.2;
    final maxY = (_width + _depth) * _sin + 0.6;
    _scale = math.min(size.width / (maxX - minX), size.height / (maxY - minY)) * 0.94;
    _origin = Offset(
      (size.width - (maxX - minX) * _scale) / 2 - minX * _scale,
      (size.height - (maxY - minY) * _scale) / 2 - minY * _scale,
    );

    final selectedIndex = lot.floors.indexWhere((f) => f.id == selectedFloorId);
    for (var i = 0; i < n; i++) {
      final f = lot.floors[i];
      final selected = i == selectedIndex;
      final above = selectedIndex >= 0 && i > selectedIndex;
      _slab(canvas, i, selected: selected, faded: above);
      _label(canvas, f.name, _p(-FloorGrid.spine + 0.3, _depth - 0.2, i), selected);
      if (selected) _floorContent(canvas, f, grids[f.id]!, i);
    }
    _gates(canvas, selectedIndex);
    _route(canvas, grids);
  }

  void _poly(Canvas canvas, List<Offset> pts, Paint paint) {
    canvas.drawPath(Path()..addPolygon(pts, true), paint);
  }

  void _slab(Canvas canvas, int level, {required bool selected, required bool faded}) {
    const x0 = -FloorGrid.spine;
    final top = [_p(x0, 0, level), _p(_width, 0, level), _p(_width, _depth, level), _p(x0, _depth, level)];
    const thick = 0.35;
    final alpha = faded ? 0.18 : (selected ? 1.0 : 0.55);
    _poly(canvas, [top[3], top[2], _p(_width, _depth, level, -thick), _p(x0, _depth, level, -thick)],
        Paint()..color = LotColors.slabSide.withValues(alpha: alpha));
    _poly(canvas, [top[1], top[2], _p(_width, _depth, level, -thick), _p(_width, 0, level, -thick)],
        Paint()..color = LotColors.slabSide.withValues(alpha: alpha * 0.8));
    _poly(canvas, top, Paint()..color = (selected ? Colors.white : LotColors.slab).withValues(alpha: alpha));
    _poly(canvas, top, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.6 : 1
      ..color = (selected ? LotColors.route : LotColors.slabSide).withValues(alpha: faded ? 0.35 : 1));
    if (selected) {
      // Lối đi chính dọc mép trái.
      _poly(canvas, [_p(x0, 0, level), _p(0, 0, level), _p(0, _depth, level), _p(x0, _depth, level)],
          Paint()..color = LotColors.aisle);
    }
  }

  void _floorContent(Canvas canvas, LayoutFloor f, FloorGrid grid, int level) {
    if (!f.hasSlots) {
      _label(canvas, '${f.vehicleTypeName ?? 'Khu'} · còn ${f.free}/${f.total} chỗ',
          _p(_width / 2, _depth / 2, level), true, center: true);
      return;
    }
    final target = guide?.floor?.id == f.id ? guide?.slot : null;
    pick?.hits.clear();
    Offset? targetTop;
    LayoutZone? prevZone;
    for (final (zone, slots, y) in grid.rows) {
      // Lối đi phía trước hàng.
      _poly(canvas, [_p(0, y - FloorGrid.aisle + 0.1, level), _p(_width, y - FloorGrid.aisle + 0.1, level),
        _p(_width, y - 0.05, level), _p(0, y - 0.05, level)], Paint()..color = LotColors.aisle.withValues(alpha: 0.6));
      if (zone.name.isNotEmpty && zone != prevZone) {
        _label(canvas, zone.name, _p(-FloorGrid.spine / 2, y + 0.5, level), true, center: true, bold: true);
      }
      prevZone = zone;
      for (var c = 0; c < slots.length; c++) {
        final s = slots[c];
        final p = pick;
        final chosen = p != null ? s.id == p.selectedSlotId : s == target;
        final color = p != null && !p.pickable(s.id) ? SlotPickOptions.faded : LotColors.of(s);
        final top = _box(canvas, c.toDouble() + 0.08, y + 0.08, level, color, highlight: chosen, hitId: s.id);
        if (chosen) targetTop = top;
      }
    }
    if (targetTop != null) _marker(canvas, targetTop);
    // Mã ô khi đủ chỗ để đọc.
    if (_scale >= 22) {
      for (final (_, slots, y) in grid.rows) {
        for (var c = 0; c < slots.length; c++) {
          _label(canvas, slots[c].code, _p(c + 0.5, y + 0.5, level, _boxH), false, center: true, size: 8, dark: true);
        }
      }
    }
  }

  /// Vẽ khối ô, trả tâm mặt trên.
  Offset _box(Canvas canvas, double x, double y, int level, Color color, {bool highlight = false, String? hitId}) {
    const w = 0.84;
    final h = highlight ? _boxH * (1.4 + 0.4 * math.sin(t * 2 * math.pi)) : _boxH;
    final c = highlight ? LotColors.target : color;
    Offset q(double dx, double dy, double z) => _p(x + dx, y + dy, level, z);
    if (pick != null && hitId != null) pick!.hits.add((boxHitPath(q, w, h), hitId));
    _poly(canvas, [q(0, w, 0), q(w, w, 0), q(w, w, h), q(0, w, h)], Paint()..color = Color.lerp(c, Colors.black, 0.25)!);
    _poly(canvas, [q(w, 0, 0), q(w, w, 0), q(w, w, h), q(w, 0, h)], Paint()..color = Color.lerp(c, Colors.black, 0.12)!);
    _poly(canvas, [q(0, 0, h), q(w, 0, h), q(w, w, h), q(0, w, h)], Paint()..color = c);
    return q(w / 2, w / 2, h);
  }

  /// Vòng sáng và ghim của ô đích, vẽ sau mọi ô để không bị ô phía trước che.
  void _marker(Canvas canvas, Offset center) {
    canvas.drawCircle(center, _scale * (0.55 + 0.25 * t), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = LotColors.target.withValues(alpha: 1 - t));
    // Ghim chỉ vị trí.
    final pin = center - Offset(0, _scale * 1.1);
    canvas.drawLine(center, pin, Paint()
      ..color = LotColors.target
      ..strokeWidth = 2);
    canvas.drawCircle(pin, _scale * 0.22, Paint()..color = LotColors.target);
  }

  void _gates(Canvas canvas, int selectedIndex) {
    for (var i = 0; i < lot.floors.length; i++) {
      for (final g in lot.floors[i].entryGates) {
        final at = _p(-FloorGrid.spine / 2, -0.2, i);
        final strong = i == selectedIndex || g.gateId == guide?.gate?.gateId;
        final paint = Paint()..color = (strong ? LotColors.route : LotColors.slabSide);
        canvas.drawPath(
            Path()
              ..moveTo(at.dx, at.dy)
              ..lineTo(at.dx - _scale * 0.3, at.dy - _scale * 0.55)
              ..lineTo(at.dx + _scale * 0.3, at.dy - _scale * 0.55)
              ..close(),
            paint);
        if (strong) _label(canvas, 'Cổng ${g.gateName}', at - Offset(0, _scale * 0.7), true, center: true, size: 10);
      }
    }
  }

  void _route(Canvas canvas, Map<String, FloorGrid> grids) {
    final g = guide;
    final floor = g?.floor;
    if (g == null || floor == null) return;
    final to = lot.floors.indexOf(floor);
    final gateFloor = g.gate == null ? null : lot.floorOf(g.gate!);
    final from = gateFloor == null ? to : lot.floors.indexOf(gateFloor);
    const sx = -FloorGrid.spine / 2;
    final pts = <Offset>[_p(sx, -0.2, from)];
    if (from != to) pts.add(_p(sx, -0.2, to));
    final slot = g.slot;
    final cell = slot == null ? null : grids[floor.id]?.cellOf(slot);
    if (cell != null) {
      final aisleY = cell.$2 - FloorGrid.aisle / 2;
      pts
        ..add(_p(sx, aisleY, to))
        ..add(_p(cell.$1 + 0.5, aisleY, to))
        ..add(_p(cell.$1 + 0.5, cell.$2 + 0.4, to));
    } else if (g.zone != null) {
      // Chưa có ô: dẫn tới đầu hàng của khu gợi ý.
      final row = grids[floor.id]?.rows.where((r) => r.$1 == g.zone).firstOrNull;
      if (row != null) {
        final aisleY = row.$3 - FloorGrid.aisle / 2;
        pts
          ..add(_p(sx, aisleY, to))
          ..add(_p(row.$2.length / 2, aisleY, to));
      }
    }
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white);
    // Vạch đứt chạy theo t: khách thấy hướng đi.
    final dash = 9.0, gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var d = (t * (dash + gap)) % (dash + gap) - gap;
      while (d < metric.length) {
        final start = math.max(0.0, d);
        final end = math.min(metric.length, d + dash);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..color = LotColors.route);
        }
        d += dash + gap;
      }
    }
    // Mũi tên ở cuối.
    final last = pts.last, prev = pts[pts.length - 2];
    final angle = math.atan2(last.dy - prev.dy, last.dx - prev.dx);
    const a = 0.5;
    final len = 10.0;
    canvas.drawPath(
        Path()
          ..moveTo(last.dx, last.dy)
          ..lineTo(last.dx - len * math.cos(angle - a), last.dy - len * math.sin(angle - a))
          ..lineTo(last.dx - len * math.cos(angle + a), last.dy - len * math.sin(angle + a))
          ..close(),
        Paint()..color = LotColors.route);
  }

  void _label(Canvas canvas, String text, Offset at, bool strong,
      {bool center = false, bool alignRight = false, double size = 11, bool bold = false, bool dark = false}) {
    final style = ui.TextStyle(
      color: dark ? const Color(0xFF0F172A) : (strong ? const Color(0xFF1E293B) : const Color(0xFF64748B)),
      fontSize: size,
      fontWeight: strong || bold ? FontWeight.w700 : FontWeight.w500,
    );
    final b = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left, maxLines: 1))
      ..pushStyle(style)
      ..addText(text);
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 200));
    final w = p.longestLine;
    final dx = center ? at.dx - w / 2 : (alignRight ? at.dx - w : at.dx);
    canvas.drawParagraph(p, Offset(dx, at.dy - p.height / 2));
  }

  @override
  bool shouldRepaint(LotIsoPainter old) =>
      old.t != t ||
      old.selectedFloorId != selectedFloorId ||
      old.lot != lot ||
      old.guide != guide ||
      old.pick?.selectedSlotId != pick?.selectedSlotId;
}

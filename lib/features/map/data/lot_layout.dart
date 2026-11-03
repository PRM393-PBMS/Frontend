import '../../../data/models/pbms_models.dart';
import '../../staff/data/staff_models.dart';
import 'pbms_facility.dart';

/// Mô hình bãi dựng từ danh mục tầng, ô, cổng (không có toạ độ thật): mỗi tầng chia khu theo
/// tiền tố mã ô (A01, A02 -> khu A), ô trong khu xếp theo số. Đủ để khách định hướng ở bãi nhỏ.
class LayoutSlot {
  final String id;
  final String code;
  final String status;
  final bool isCar;
  final String vehicleTypeId;

  const LayoutSlot({
    required this.id,
    required this.code,
    required this.status,
    required this.isCar,
    this.vehicleTypeId = '',
  });

  String get _s => status.toLowerCase();
  bool get isFree => _s == 'available';
  bool get isOccupied => _s == 'occupied';
  bool get isAssigned => _s == 'assigned';
}

class LayoutZone {
  /// Rỗng khi mã ô không có tiền tố chữ (khu chung).
  final String name;
  final List<LayoutSlot> slots;

  const LayoutZone(this.name, this.slots);

  int get free => slots.where((s) => s.isFree).length;
  String get label => name.isEmpty ? 'khu chung' : 'khu $name';
}

class LayoutFloor {
  final String id;
  final String name;
  final bool isResident;

  /// Tầng không chia ô (xe máy): đếm theo sức chứa.
  final String? vehicleTypeName;
  final int capacity;
  final int capacityFree;
  final List<LayoutZone> zones;
  final List<GateModel> gates;

  const LayoutFloor({
    required this.id,
    required this.name,
    required this.isResident,
    this.vehicleTypeName,
    this.capacity = 0,
    this.capacityFree = 0,
    required this.zones,
    required this.gates,
  });

  bool get hasSlots => zones.isNotEmpty;
  bool get isCarFloor => zones.any((z) => z.slots.any((s) => s.isCar));
  bool get isMotorbikeFloor => !hasSlots && (vehicleTypeName ?? '').toLowerCase().contains('máy');
  int get free => hasSlots ? zones.fold(0, (s, z) => s + z.free) : capacityFree;
  int get total => hasSlots ? zones.fold(0, (s, z) => s + z.slots.length) : capacity;
  Iterable<GateModel> get entryGates => gates.where((g) => !g.isExit);

  /// Thứ tự tầng: hầm (B2, Hầm 1) dưới mặt đất, số âm; trệt 0; tầng n là n.
  int get level => floorLevel(name);
}

class LotLayout {
  final String parkingId;

  /// Từ dưới lên trên.
  final List<LayoutFloor> floors;

  const LotLayout(this.parkingId, this.floors);

  Iterable<GateModel> get gates => floors.expand((f) => f.gates);

  LayoutFloor? floorOf(GateModel gate) => floors.where((f) => f.id == gate.floorId).firstOrNull;

  ({LayoutFloor floor, LayoutZone zone, LayoutSlot slot})? find(String slotCode) {
    final code = slotCode.trim().toUpperCase();
    for (final f in floors) {
      for (final z in f.zones) {
        for (final s in z.slots) {
          if (s.code.toUpperCase() == code) return (floor: f, zone: z, slot: s);
        }
      }
    }
    return null;
  }

  /// Dựng mọi bãi từ JSON tầng (/api/Floor), ô (/api/ParkingSlot), cổng và chỗ trống tầng không chia ô.
  static List<LotLayout> buildAll({
    required List<Map<String, dynamic>> floors,
    required List<ParkingSlotModel> slots,
    required List<GateModel> gates,
    List<FacilityAvailabilityModel> availability = const [],
  }) {
    final byLot = <String, List<LayoutFloor>>{};
    for (final f in floors) {
      final id = '${f['floorId'] ?? ''}';
      final lot = '${f['parkingId'] ?? ''}';
      if (id.isEmpty || lot.isEmpty) continue;
      final floorSlots = slots.where((s) => s.floorId == id).toList();
      final zones = <String, List<LayoutSlot>>{};
      for (final s in floorSlots) {
        zones.putIfAbsent(slotZone(s.slotCode), () => []).add(LayoutSlot(
              id: s.slotId,
              code: s.slotCode,
              status: s.status,
              isCar: isCarType(s.vehicleTypeName),
              vehicleTypeId: s.vehicleTypeId,
            ));
      }
      final names = zones.keys.toList()..sort();
      final avail = availability.where((a) => a.floorId == id).firstOrNull;
      byLot.putIfAbsent(lot, () => []).add(LayoutFloor(
            id: id,
            name: '${f['floorName'] ?? ''}',
            isResident: f['isResident'] == true,
            vehicleTypeName: f['dedicatedVehicleTypeName'] as String?,
            capacity: (f['totalCapacity'] as num?)?.toInt() ?? 0,
            capacityFree: avail?.availableSlots ?? 0,
            zones: [
              for (final n in names)
                LayoutZone(n, zones[n]!..sort((a, b) => slotNumber(a.code).compareTo(slotNumber(b.code)))),
            ],
            gates: gates.where((g) => g.floorId == id).toList(),
          ));
    }
    return [
      for (final e in byLot.entries)
        LotLayout(e.key, e.value..sort((a, b) {
          final byLevel = a.level.compareTo(b.level);
          return byLevel != 0 ? byLevel : a.name.compareTo(b.name);
        })),
    ];
  }
}

/// "A01" -> "A", "B1-A01" -> "B1-A", "001" -> "".
String slotZone(String code) =>
    code.trim().toUpperCase().replaceFirst(RegExp(r'\d+$'), '').replaceFirst(RegExp(r'[-_. ]+$'), '');

int slotNumber(String code) => int.tryParse(RegExp(r'(\d+)$').firstMatch(code)?.group(1) ?? '') ?? 0;

int floorLevel(String name) {
  final n = name.trim().toLowerCase();
  final basement = RegExp(r'^(b|hầm\s*|ham\s*)(\d+)').firstMatch(n);
  if (basement != null) return -int.parse(basement.group(2)!);
  if (n.contains('trệt') || n == 'g' || n.startsWith('g ')) return 0;
  return int.tryParse(RegExp(r'(\d+)').firstMatch(n)?.group(1) ?? '') ?? 0;
}

/// Chỉ đường trong bãi: cổng vào -> tầng -> khu -> ô. [slot] null khi chưa phân ô (gợi ý tầng/khu).
class LotGuide {
  final GateModel? gate;
  final LayoutFloor? floor;
  final LayoutZone? zone;
  final LayoutSlot? slot;
  final List<String> steps;

  const LotGuide({this.gate, this.floor, this.zone, this.slot, required this.steps});
}

/// [targetSlotCode]: ô của lượt gửi (hệ thống phân ô khi xe vào cổng). Không có thì gợi ý theo loại xe.
/// [entryGateName]: cổng khách đã vào (lượt đang gửi).
LotGuide buildGuide(LotLayout lot, {String? targetSlotCode, String? entryGateName, bool car = true}) {
  final target = targetSlotCode == null || targetSlotCode.isEmpty ? null : lot.find(targetSlotCode);
  final entered = entryGateName == null
      ? null
      : lot.gates.where((g) => g.gateName.toLowerCase() == entryGateName.toLowerCase()).firstOrNull;

  if (target != null) {
    final gate = entered ?? _entryGateFor(lot, target.floor);
    final steps = <String>[
      entered != null ? 'Bạn đã vào bãi qua cổng ${entered.gateName}.' : _gateStep(lot, gate),
      ..._floorStep(lot, gate, target.floor),
      if (target.zone.slots.length > 1 || target.zone.name.isNotEmpty)
        'Tới ${target.zone.label}: ô ${target.slot.code} là ô thứ '
            '${target.zone.slots.indexOf(target.slot) + 1}/${target.zone.slots.length} tính từ lối đi chính.',
      'Đỗ vào ô ${target.slot.code} (ô nhấp nháy trên sơ đồ).',
    ];
    return LotGuide(gate: gate, floor: target.floor, zone: target.zone, slot: target.slot, steps: steps);
  }

  if (targetSlotCode != null && targetSlotCode.isNotEmpty) {
    return LotGuide(steps: ['Không tìm thấy ô $targetSlotCode trên sơ đồ. Hỏi nhân viên tại cổng để được hướng dẫn.']);
  }

  // Chưa có ô: gợi ý tầng còn nhiều chỗ nhất cho loại xe (bỏ tầng cư dân, chỉ dành cho vé tháng).
  final candidates = lot.floors
      .where((f) => !f.isResident && (car ? f.isCarFloor : f.isMotorbikeFloor || (f.hasSlots && !f.isCarFloor)))
      .toList()
    ..sort((a, b) => b.free.compareTo(a.free));
  final floor = candidates.where((f) => f.free > 0).firstOrNull;
  final kind = car ? 'ô tô' : 'xe máy';
  if (floor == null) {
    return LotGuide(steps: ['Bãi hiện đã hết chỗ cho $kind. Thử bãi khác hoặc đặt chỗ trước.']);
  }
  final gate = _entryGateFor(lot, floor);
  final zone = floor.zones.where((z) => z.free > 0).fold<LayoutZone?>(
      null, (best, z) => best == null || z.free > best.free ? z : best);
  return LotGuide(gate: gate, floor: floor, zone: zone, steps: [
    _gateStep(lot, gate),
    ..._floorStep(lot, gate, floor, free: floor.free, kind: kind),
    if (zone != null) '${zone.label[0].toUpperCase()}${zone.label.substring(1)} còn nhiều chỗ nhất (${zone.free} ô trống).',
    car
        ? 'Hệ thống phân ô khi xe qua cổng; mở lại sơ đồ từ lượt gửi để xem đường tới đúng ô.'
        : 'Xe máy đỗ vào chỗ trống bất kỳ trong khu xe máy.',
  ]);
}

/// Cổng vào trên chính tầng đó, không có thì cổng gần mặt đất nhất.
GateModel? _entryGateFor(LotLayout lot, LayoutFloor floor) {
  final here = floor.entryGates.firstOrNull;
  if (here != null) return here;
  final all = lot.floors.expand((f) => f.entryGates.map((g) => (g, f.level.abs()))).toList()
    ..sort((a, b) => a.$2.compareTo(b.$2));
  return all.firstOrNull?.$1;
}

String _gateStep(LotLayout lot, GateModel? gate) => gate == null
    ? 'Vào bãi qua cổng vào chính.'
    : 'Vào bãi qua cổng ${gate.gateName}${lot.floorOf(gate) == null ? '' : ' (${lot.floorOf(gate)!.name})'}.';

List<String> _floorStep(LotLayout lot, GateModel? gate, LayoutFloor floor, {int? free, String? kind}) {
  final from = gate == null ? null : lot.floorOf(gate);
  final room = free == null ? '' : ', còn $free chỗ $kind';
  if (from == null || from.id == floor.id) {
    return ['Ở ngay ${floor.name}$room.'];
  }
  final dir = floor.level > from.level ? 'lên' : 'xuống';
  return ['Theo dốc/thang $dir ${floor.name}$room.'];
}

import 'package:equatable/equatable.dart';

import '../../../core/utils/json_read.dart';

class VehicleTypeItem extends Equatable {
  final String id;
  final String name;

  const VehicleTypeItem({required this.id, required this.name});

  factory VehicleTypeItem.fromJson(Map<String, dynamic> j) =>
      VehicleTypeItem(id: j.str('vehicleTypeId'), name: j.str('typeName'));

  bool get isCar => name.trim().toLowerCase() == 'ô tô';

  @override
  List<Object?> get props => [id, name];
}

class FloorItem extends Equatable {
  final String id;
  final String name;
  final bool isResident;
  final int totalCapacity;
  final String? dedicatedVehicleTypeName;

  const FloorItem({
    required this.id,
    required this.name,
    required this.isResident,
    required this.totalCapacity,
    this.dedicatedVehicleTypeName,
  });

  factory FloorItem.fromJson(Map<String, dynamic> j) => FloorItem(
        id: j.str('floorId'),
        name: j.str('floorName'),
        isResident: j.boolean('isResident'),
        totalCapacity: j.integer('totalCapacity'),
        dedicatedVehicleTypeName: j.strOrNull('dedicatedVehicleTypeName'),
      );

  @override
  List<Object?> get props =>
      [id, name, isResident, totalCapacity, dedicatedVehicleTypeName];
}

class GateItem extends Equatable {
  final String id;
  final String name;
  final String type;
  final String floorId;
  final String floorName;

  const GateItem({
    required this.id,
    required this.name,
    required this.type,
    required this.floorId,
    required this.floorName,
  });

  factory GateItem.fromJson(Map<String, dynamic> j) => GateItem(
        id: j.str('gateId'),
        name: j.str('gateName'),
        type: j.str('gateType'),
        floorId: j.str('floorId'),
        floorName: j.str('floorName'),
      );

  bool get isEntry => type.trim().toLowerCase() == 'entry';
  bool get isExit => type.trim().toLowerCase() == 'exit';

  @override
  List<Object?> get props => [id, name, type, floorId, floorName];
}

class ParkingSlotItem extends Equatable {
  final String id;
  final String floorId;
  final String floorName;
  final String code;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final String status;
  final bool isResident;

  const ParkingSlotItem({
    required this.id,
    required this.floorId,
    required this.floorName,
    required this.code,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.status,
    required this.isResident,
  });

  factory ParkingSlotItem.fromJson(Map<String, dynamic> j) => ParkingSlotItem(
        id: j.str('slotId'),
        floorId: j.str('floorId'),
        floorName: j.str('floorName'),
        code: j.str('slotCode'),
        vehicleTypeId: j.str('vehicleTypeId'),
        vehicleTypeName: j.str('vehicleTypeName'),
        status: j.str('status'),
        isResident: j.boolean('isResident'),
      );

  bool get isAvailable => status.trim().toLowerCase() == 'available';

  @override
  List<Object?> get props => [id, code, status];
}

class PricingPolicyItem extends Equatable {
  final String id;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final double basePrice;
  final int baseHours;
  final double extraHourPrice;
  final double nightSurcharge;
  final DateTime? effectiveDate;
  final String status;

  const PricingPolicyItem({
    required this.id,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.basePrice,
    required this.baseHours,
    required this.extraHourPrice,
    required this.nightSurcharge,
    required this.effectiveDate,
    required this.status,
  });

  factory PricingPolicyItem.fromJson(Map<String, dynamic> j) =>
      PricingPolicyItem(
        id: j.str('policyId'),
        vehicleTypeId: j.str('vehicleTypeId'),
        vehicleTypeName: j.str('vehicleTypeName'),
        basePrice: j.number('basePrice'),
        baseHours: j.integer('baseHours'),
        extraHourPrice: j.number('extraHourPrice'),
        nightSurcharge: j.number('nightSurcharge'),
        effectiveDate: j.date('effectiveDate'),
        status: j.str('status'),
      );

  bool get isActive => status.trim().toLowerCase() == 'active';

  @override
  List<Object?> get props => [id, status, basePrice];
}

class SubscriptionPackageItem extends Equatable {
  final String id;
  final String name;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int durationMonths;
  final double price;
  final bool requireFixedSlot;
  final String? description;
  final String status;

  const SubscriptionPackageItem({
    required this.id,
    required this.name,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.durationMonths,
    required this.price,
    required this.requireFixedSlot,
    required this.description,
    required this.status,
  });

  factory SubscriptionPackageItem.fromJson(Map<String, dynamic> j) =>
      SubscriptionPackageItem(
        id: j.str('packageId'),
        name: j.str('packageName'),
        vehicleTypeId: j.str('vehicleTypeId'),
        vehicleTypeName: j.str('vehicleTypeName'),
        durationMonths: j.integer('durationMonths'),
        price: j.number('price'),
        requireFixedSlot: j.boolean('requireFixedSlot'),
        description: j.strOrNull('description'),
        status: j.str('status'),
      );

  bool get isActive => status.trim().toLowerCase() == 'active';

  @override
  List<Object?> get props => [id, status, price];
}

class AvailabilityEntry extends Equatable {
  final String floorId;
  final String floorName;
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;
  final int assignedSlots;

  const AvailabilityEntry({
    required this.floorId,
    required this.floorName,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.totalSlots,
    required this.availableSlots,
    required this.occupiedSlots,
    required this.assignedSlots,
  });

  factory AvailabilityEntry.fromJson(Map<String, dynamic> j) =>
      AvailabilityEntry(
        floorId: j.str('floorId'),
        floorName: j.str('floorName'),
        vehicleTypeId: j.str('vehicleTypeId'),
        vehicleTypeName: j.str('vehicleTypeName'),
        totalSlots: j.integer('totalSlots'),
        availableSlots: j.integer('availableSlots'),
        occupiedSlots: j.integer('occupiedSlots'),
        assignedSlots: j.integer('assignedSlots'),
      );

  @override
  List<Object?> get props =>
      [floorId, vehicleTypeId, availableSlots, totalSlots];
}

/// Tổng hợp tình trạng bãi: số chỗ theo tầng, thông tin tầng và bảng giá đang áp dụng.
class AvailabilityOverview extends Equatable {
  final List<AvailabilityEntry> entries;
  final List<FloorItem> floors;
  final List<PricingPolicyItem> activePricing;

  const AvailabilityOverview({
    required this.entries,
    required this.floors,
    required this.activePricing,
  });

  int get totalAvailable => entries.fold(0, (sum, e) => sum + e.availableSlots);
  int get totalSlots => entries.fold(0, (sum, e) => sum + e.totalSlots);

  FloorItem? floorById(String id) {
    for (final f in floors) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Gom số chỗ theo loại xe trên toàn bãi.
  Map<String, ({int available, int total})> get byVehicleType {
    final map = <String, ({int available, int total})>{};
    for (final e in entries) {
      final cur = map[e.vehicleTypeName] ?? (available: 0, total: 0);
      map[e.vehicleTypeName] = (
        available: cur.available + e.availableSlots,
        total: cur.total + e.totalSlots
      );
    }
    return map;
  }

  @override
  List<Object?> get props => [entries, floors, activePricing];
}

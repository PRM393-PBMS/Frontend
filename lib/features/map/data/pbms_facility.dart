import 'package:latlong2/latlong.dart';

import '../../../data/models/pbms_models.dart';

/// Bãi đỗ duy nhất do hệ thống PBMS quản lý.
/// Backend chưa cung cấp toạ độ / địa chỉ, nên vị trí trên bản đồ được cấu hình tại đây.
class PbmsFacility {
  PbmsFacility._();

  static const name = 'Bãi đỗ PBMS';
  static const area = 'Bến Nghé, Quận 1';
  static const location = LatLng(10.7769, 106.7009);
}

/// Một bãi để hiển thị trên bản đồ / trang chủ. Khi backend chưa có danh sách
/// bãi, app dùng một bãi PBMS mặc định với chỗ trống toàn hệ thống.
class LotView {
  final String id;
  final String name;
  final String? area;
  final LatLng? point;
  final List<VehicleTypeCapacity> capacities;

  const LotView({
    required this.id,
    required this.name,
    required this.area,
    required this.point,
    required this.capacities,
  });

  int get available => capacities.fold(0, (s, c) => s + c.available);
  int get total => capacities.fold(0, (s, c) => s + c.total);
  int get occupiedPercent => total == 0 ? 0 : ((total - available) / total * 100).round();
  VehicleTypeCapacity? get car => capacities.where((c) => c.isCar).firstOrNull;

  static Future<List<LotView>> load({
    required Future<List<ParkingLotModel>> Function() lots,
    required Future<List<FacilityAvailabilityModel>> Function() facility,
    required Future<List<PricingPolicyModel>> Function() pricing,
  }) async {
    final results = await Future.wait([lots(), pricing()]);
    final lotList = results[0] as List<ParkingLotModel>;
    final prices = results[1] as List<PricingPolicyModel>;
    if (lotList.isNotEmpty) {
      return [
        for (final l in lotList)
          LotView(
            id: l.id,
            name: l.name,
            area: l.displayLocation,
            point: l.hasCoordinates ? LatLng(l.latitude!, l.longitude!) : null,
            capacities: VehicleTypeCapacity.fromLot(l, prices),
          ),
      ];
    }
    return [
      LotView(
        id: 'pbms',
        name: PbmsFacility.name,
        area: PbmsFacility.area,
        point: PbmsFacility.location,
        capacities: VehicleTypeCapacity.summarize(await facility(), prices),
      ),
    ];
  }
}

/// Loại xe được phép đặt chỗ trước (backend chỉ nhận đặt chỗ ô tô).
bool isCarType(String vehicleTypeName) {
  final n = vehicleTypeName.toLowerCase();
  return n.contains('ô tô') || n.contains('oto') || n.contains('car');
}

/// Tổng hợp chỗ trống theo loại xe từ dữ liệu từng tầng.
class VehicleTypeCapacity {
  final String vehicleTypeId;
  final String vehicleTypeName;
  final int available;
  final int total;
  final PricingPolicyModel? pricing;

  const VehicleTypeCapacity({
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.available,
    required this.total,
    this.pricing,
  });

  bool get isCar => isCarType(vehicleTypeName);
  int get occupiedPercent =>
      total == 0 ? 0 : ((total - available) / total * 100).round();

  /// Chỗ trống của một bãi (từ `/parkings/available`) kèm bảng giá theo loại xe.
  static List<VehicleTypeCapacity> fromLot(
    ParkingLotModel lot,
    List<PricingPolicyModel> pricing,
  ) {
    final result = [
      for (final a in lot.availability)
        VehicleTypeCapacity(
          vehicleTypeId: a.vehicleTypeId,
          vehicleTypeName: a.vehicleTypeName,
          available: a.availableSlots,
          total: a.totalSlots,
          pricing: pricing.where((p) => p.vehicleTypeId == a.vehicleTypeId).firstOrNull,
        ),
    ];
    result.sort((a, b) => (b.isCar ? 1 : 0).compareTo(a.isCar ? 1 : 0));
    return result;
  }

  static List<VehicleTypeCapacity> summarize(
    List<FacilityAvailabilityModel> floors,
    List<PricingPolicyModel> pricing,
  ) {
    final byType = <String, List<FacilityAvailabilityModel>>{};
    for (final f in floors) {
      byType.putIfAbsent(f.vehicleTypeId, () => []).add(f);
    }
    final result = [
      for (final entry in byType.entries)
        VehicleTypeCapacity(
          vehicleTypeId: entry.key,
          vehicleTypeName: entry.value.first.vehicleTypeName,
          available: entry.value.fold(0, (s, f) => s + f.availableSlots),
          total: entry.value.fold(0, (s, f) => s + f.totalSlots),
          pricing: pricing
              .where((p) => p.vehicleTypeId == entry.key)
              .firstOrNull,
        ),
    ];
    // Ô tô lên trước vì là loại đặt chỗ được.
    result.sort((a, b) => (b.isCar ? 1 : 0).compareTo(a.isCar ? 1 : 0));
    return result;
  }
}

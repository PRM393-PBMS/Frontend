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

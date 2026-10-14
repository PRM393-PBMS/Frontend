import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'catalog_models.dart';

/// Danh mục dùng chung: tầng, cổng, ô đỗ, bảng giá, gói tháng, tình trạng chỗ trống.
class CatalogRepository {
  final ApiClient _api;

  CatalogRepository(this._api);

  Future<List<AvailabilityEntry>> availability() =>
      _api.getList(ApiEndpoints.availability, AvailabilityEntry.fromJson);

  Future<List<FloorItem>> floors() =>
      _api.getList(ApiEndpoints.floors, FloorItem.fromJson);

  Future<List<GateItem>> gates() =>
      _api.getList(ApiEndpoints.gates, GateItem.fromJson);

  Future<List<ParkingSlotItem>> slots() =>
      _api.getList(ApiEndpoints.parkingSlots, ParkingSlotItem.fromJson);

  /// Chỉ Staff/Manager được gọi.
  Future<List<VehicleTypeItem>> vehicleTypes() =>
      _api.getList(ApiEndpoints.vehicleTypes, VehicleTypeItem.fromJson);

  Future<List<PricingPolicyItem>> pricingPolicies() =>
      _api.getList(ApiEndpoints.pricingPolicies, PricingPolicyItem.fromJson);

  Future<List<SubscriptionPackageItem>> packages() => _api.getList(
      ApiEndpoints.subscriptionPackages, SubscriptionPackageItem.fromJson);

  /// Bảng giá đang áp dụng: mỗi loại xe lấy chính sách Active mới nhất đã tới ngày hiệu lực.
  static List<PricingPolicyItem> currentPricing(List<PricingPolicyItem> all) {
    final now = DateTime.now();
    final byType = <String, PricingPolicyItem>{};
    for (final p in all) {
      if (!p.isActive) continue;
      if (p.effectiveDate != null && p.effectiveDate!.isAfter(now)) continue;
      final cur = byType[p.vehicleTypeId];
      if (cur == null ||
          (p.effectiveDate ?? DateTime(1970))
              .isAfter(cur.effectiveDate ?? DateTime(1970))) {
        byType[p.vehicleTypeId] = p;
      }
    }
    return byType.values.toList()
      ..sort((a, b) => a.vehicleTypeName.compareTo(b.vehicleTypeName));
  }

  Future<AvailabilityOverview> overview() async {
    final results =
        await Future.wait([availability(), floors(), pricingPolicies()]);
    return AvailabilityOverview(
      entries: results[0] as List<AvailabilityEntry>,
      floors: results[1] as List<FloorItem>,
      activePricing: currentPricing(results[2] as List<PricingPolicyItem>),
    );
  }
}

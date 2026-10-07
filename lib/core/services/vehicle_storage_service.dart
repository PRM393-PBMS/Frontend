import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/presentation/models/vehicle_card_model.dart';

/// Dịch vụ lưu trữ phương tiện đăng ký vào bộ nhớ thiết bị & đồng bộ ví kỹ thuật số
class VehicleStorageService {
  VehicleStorageService._();
  static final VehicleStorageService instance = VehicleStorageService._();

  String _storageKey(String? userId) => 'pbms_registered_vehicles_${userId ?? "default"}';

  /// Lấy danh sách xe đã đăng ký của người dùng
  Future<List<VehicleCardModel>> getVehicles({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => VehicleCardModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Thêm hoặc cập nhật phương tiện vào ví
  Future<void> saveVehicle(VehicleCardModel vehicle, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(userId);
      final current = await getVehicles(userId: userId);

      // Xoá xe cũ nếu trùng biển số hoặc ID để cập nhật
      current.removeWhere((v) =>
          v.id == vehicle.id ||
          v.licensePlate.replaceAll(' ', '').toUpperCase() ==
              vehicle.licensePlate.replaceAll(' ', '').toUpperCase());

      // Chèn xe mới lên đầu danh sách
      current.insert(0, vehicle);

      final encoded = jsonEncode(current.map((v) => v.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  /// Xoá phương tiện khỏi ví
  Future<void> removeVehicle(String vehicleId, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(userId);
      final current = await getVehicles(userId: userId);
      current.removeWhere((v) => v.id == vehicleId);

      final encoded = jsonEncode(current.map((v) => v.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  /// Xoá toàn bộ xe của người dùng
  Future<void> clearAll({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(userId));
    } catch (_) {}
  }
}

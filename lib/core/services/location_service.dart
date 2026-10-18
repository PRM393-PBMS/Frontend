import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Kết quả lấy vị trí: có toạ độ, hoặc lý do không lấy được để giao diện hướng dẫn.
enum LocationStatus { ok, serviceOff, denied, deniedForever, failed }

class LocationResult {
  final LocationStatus status;
  final LatLng? position;

  const LocationResult(this.status, [this.position]);

  bool get ok => position != null;
}

/// Vị trí thực tế của khách (GPS). Nhớ kết quả gần nhất trong 2 phút để
/// trang chủ và bản đồ dùng chung, không hỏi quyền lặp lại.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const _maxAge = Duration(minutes: 2);

  LatLng? _last;
  DateTime? _at;

  LatLng? get last => _last;

  /// [prompt]: được phép hiện hộp thoại xin quyền của hệ thống.
  Future<LocationResult> current({bool prompt = true, bool fresh = false}) async {
    final at = _at;
    if (!fresh && _last != null && at != null && DateTime.now().difference(at) < _maxAge) {
      return LocationResult(LocationStatus.ok, _last);
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        // Trong nhà / tín hiệu yếu: dùng vị trí gần nhất hệ thống còn nhớ.
        if (!kIsWeb) pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return const LocationResult(LocationStatus.failed);
      _last = LatLng(pos.latitude, pos.longitude);
      _at = DateTime.now();
      return LocationResult(LocationStatus.ok, _last);
    } catch (_) {
      return const LocationResult(LocationStatus.failed);
    }
  }

  static String formatDistance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
}

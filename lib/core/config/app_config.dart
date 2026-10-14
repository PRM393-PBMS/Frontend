/// Cấu hình môi trường.
///
/// Đổi backend khi chạy: `flutter run --dart-define=API_BASE_URL=http://localhost:3000`
/// (Android Emulator dùng `http://10.0.2.2:3000`).
class AppConfig {
  AppConfig._();

  static const String cloudBaseUrl = 'https://prm393-backend-u2ym.onrender.com';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: cloudBaseUrl,
  );

  // Render free tier có thể mất tới ~60s để khởi động lại.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Chu kỳ kiểm tra trạng thái thanh toán PayOS.
  static const Duration paymentPollInterval = Duration(seconds: 4);

  static const String appTitle = 'PBMS Parking';
  static const String appVersion = '1.0.0';
}

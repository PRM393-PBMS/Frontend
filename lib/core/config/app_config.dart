/// Application Environment Configuration
class AppConfig {
  AppConfig._();

  // Có thể chuyển đổi giữa Local và Render Cloud
  static const bool useCloudBackend = true;

  static const String localBaseUrl = 'http://10.0.2.2:3000'; // 10.0.2.2 cho Android Emulator, localhost cho iOS/Web
  static const String cloudBaseUrl = 'https://prm393-backend-u2ym.onrender.com';

  static String get baseUrl => useCloudBackend ? cloudBaseUrl : localBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  static const String appTitle = 'PRM393 Parking System';
  static const String appVersion = '1.0.0';
}

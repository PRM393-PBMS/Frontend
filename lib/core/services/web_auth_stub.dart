/// Bản rỗng cho nền tảng không phải web.
class WebAuth {
  WebAuth._();

  static Future<bool> isAvailable() async => false;

  /// 'success' | 'canceled' | 'unavailable' | 'failed'
  static Future<String> authenticate(String displayName) async => 'unavailable';

  static void reset() {}
}

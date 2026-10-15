import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _kIsFirstTimeAppOpen = 'is_first_time_app_open';

  /// Chỉ hiện giới thiệu ở lần mở app đầu tiên.
  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kIsFirstTimeAppOpen) ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsFirstTimeAppOpen, false);
    } catch (_) {}
  }
}

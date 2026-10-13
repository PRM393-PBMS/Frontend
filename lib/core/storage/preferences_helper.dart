import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _kLastOpenedDate = 'last_opened_date';
  static const String _kIsFirstTimeAppOpen = 'is_first_time_app_open';

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if it's the very first time the app is opened
    final isFirstTime = prefs.getBool(_kIsFirstTimeAppOpen) ?? true;
    
    // Check if it's the first time today
    final lastOpenedDateString = prefs.getString(_kLastOpenedDate);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    bool isFirstTimeToday = lastOpenedDateString != todayString;

    return isFirstTime || isFirstTimeToday;
  }

  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await prefs.setBool(_kIsFirstTimeAppOpen, false);
    await prefs.setString(_kLastOpenedDate, todayString);
  }
}

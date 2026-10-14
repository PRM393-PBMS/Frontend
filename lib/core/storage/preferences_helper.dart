import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class PreferencesHelper {
  static const String _kLastOpenedDate = 'last_opened_date';
  static const String _kIsFirstTimeAppOpen = 'is_first_time_app_open';

  static String _today() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool(_kIsFirstTimeAppOpen) ?? true;
      final lastOpenedDateString = prefs.getString(_kLastOpenedDate);
      return isFirstTime || lastOpenedDateString != _today();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsFirstTimeAppOpen, false);
      await prefs.setString(_kLastOpenedDate, _today());
    } catch (_) {}
  }

  static Future<ThemeMode> readThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(StorageKeys.themeMode)) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.themeMode, mode.name);
    } catch (_) {}
  }
}

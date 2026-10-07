import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danh sách ngôn ngữ hỗ trợ trong hệ thống PBMS Smart Parking
enum AppLanguage {
  vi(
    code: 'vi',
    name: 'Tiếng Việt',
    englishName: 'Vietnamese',
    flag: '🇻🇳',
    desc: 'Mặc định hệ thống',
  ),
  en(
    code: 'en',
    name: 'English',
    englishName: 'English (US)',
    flag: '🇬🇧',
    desc: 'International Driver Pass',
  ),
  ja(
    code: 'ja',
    name: '日本語',
    englishName: 'Japanese',
    flag: '🇯🇵',
    desc: 'スマートパーキング多言語対応',
  );

  final String code;
  final String name;
  final String englishName;
  final String flag;
  final String desc;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.englishName,
    required this.flag,
    required this.desc,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.vi;
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

/// Bộ điều khiển ngôn ngữ toàn cục (Global Language Controller)
class LanguageController {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  static const String _prefKey = 'pbms_app_language_code';

  final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.vi);

  AppLanguage get currentLanguage => languageNotifier.value;

  /// Khởi tạo và tải ngôn ngữ đã lưu từ SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        languageNotifier.value = AppLanguage.fromCode(savedCode);
      }
    } catch (_) {
      // Dùng mặc định Tiếng Việt nếu gặp sự cố đọc cache
    }
  }

  /// Chuyển đổi ngôn ngữ và lưu vào bộ nhớ lâu dài
  Future<void> setLanguage(AppLanguage language) async {
    if (languageNotifier.value == language) return;
    languageNotifier.value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {}
  }
}

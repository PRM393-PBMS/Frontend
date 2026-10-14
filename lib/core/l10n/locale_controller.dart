import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Ngôn ngữ giao diện (vi / en / ja), có lưu lựa chọn. Mặc định tiếng Việt.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _key = 'pbms_locale';
  static const fallback = Locale('vi');

  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(fallback);

  Locale get locale => localeNotifier.value;

  static bool isSupported(String code) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == code);

  Future<void> restore() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_key);
      if (code != null && isSupported(code)) {
        localeNotifier.value = Locale(code);
      }
    } catch (_) {}
    Intl.defaultLocale = locale.languageCode;
  }

  Future<void> setLocale(Locale value) async {
    localeNotifier.value = value;
    Intl.defaultLocale = value.languageCode;
    try {
      await (await SharedPreferences.getInstance())
          .setString(_key, value.languageCode);
    } catch (_) {}
  }
}

/// Tên hiển thị của mỗi ngôn ngữ bằng chính ngôn ngữ đó.
const languageNames = {'vi': 'Tiếng Việt', 'en': 'English', 'ja': '日本語'};

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

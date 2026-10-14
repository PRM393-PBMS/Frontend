import 'package:flutter/material.dart';

import '../storage/preferences_helper.dart';

/// Bộ điều khiển chế độ giao diện (Theo hệ thống / Sáng / Tối), có lưu lựa chọn.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  ThemeMode get currentMode => themeModeNotifier.value;

  Future<void> restore() async {
    themeModeNotifier.value = await PreferencesHelper.readThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await PreferencesHelper.saveThemeMode(mode);
  }
}

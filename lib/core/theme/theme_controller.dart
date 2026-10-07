import 'package:flutter/material.dart';

/// Bộ điều khiển chuyển đổi giao diện Sáng / Tối (Light & Dark Theme Controller)
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  /// Mặc định kích hoạt Tông màu sáng (Light Mode)
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  ThemeMode get currentMode => themeModeNotifier.value;

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}

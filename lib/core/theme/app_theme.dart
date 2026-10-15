import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData Material 3 dựng từ [AppPalette].
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);
  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = AppTypography.textTheme(p.text, p.textSecondary);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.text,
      secondary: p.ok,
      onSecondary: isDark ? AppColors.carbon950 : AppColors.white,
      secondaryContainer: p.okSoft,
      onSecondaryContainer: p.text,
      tertiary: p.warn,
      onTertiary: AppColors.carbon950,
      error: p.danger,
      onError: isDark ? AppColors.carbon950 : AppColors.white,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.text,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceRaised,
      surfaceContainerHighest: p.surfaceRaised,
      outline: p.line,
      outlineVariant: p.line,
      inverseSurface: isDark ? AppColors.porcelain50 : AppColors.carbon900,
      onInverseSurface: isDark ? AppColors.ink : const Color(0xFFEDF0F3),
      shadow: const Color(0xFF0B1220),
      scrim: const Color(0xFF05080C),
    );

    final controlShape = RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      extensions: [p],
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: BorderSide(color: p.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.surfaceRaised,
          disabledForegroundColor: p.textMuted,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: p.line, width: 1.2),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.accent, 1.6),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.6),
        labelStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: p.accent),
        hintStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? p.text : p.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? p.accent : p.textSecondary,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accentSoft,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.accent),
        checkmarkColor: p.accent,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          side: WidgetStatePropertyAll(BorderSide(color: p.line)),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.accentSoft : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.accent : p.textSecondary),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.porcelain50 : AppColors.carbon900,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : const Color(0xFFEDF0F3),
        ),
        actionTextColor: isDark ? AppColors.cobalt : AppColors.cobaltBright,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.text,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.onAccent : p.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.accent : p.surfaceRaised),
        trackOutlineColor: WidgetStatePropertyAll(p.line),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceRaised,
        circularTrackColor: Colors.transparent,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.accent : p.textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        side: BorderSide(color: p.textMuted, width: 1.5),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.text,
        unselectedLabelColor: p.textSecondary,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: p.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.line,
      ),
    );
  }
}

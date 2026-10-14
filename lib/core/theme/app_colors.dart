import 'package:flutter/material.dart';

/// Design tokens màu sắc PBMS: hệ "Precision Architectural & Dark-Tech Mobility"
/// của nhánh LongMainRes.
///
/// Quy tắc:
/// - Một màu nhấn duy nhất: cyan điện tử ở chế độ tối; ở chế độ sáng dùng
///   xanh Deep Tech cùng họ màu (cyan trên nền trắng không đạt tương phản WCAG AA).
/// - Mint / Amber / Crimson chỉ dùng cho trạng thái có ngữ nghĩa thật
///   (chỗ trống, chờ thanh toán, lỗi), không dùng để trang trí.
/// - Thẻ nhận diện (phiên đang gửi, thẻ xe, vé) dùng gradient titanium.
class AppColors {
  AppColors._();

  // Accent
  static const Color primary = Color(0xFF00E5FF); // Electric Precision Cyan
  static const Color primaryDeep =
      Color(0xFF0369A1); // Deep Tech Blue (chế độ sáng)
  static const Color primaryPressed = Color(0xFF075985);
  static const Color primarySoftLight = Color(0xFFE0F2FE);
  static const Color primarySoftDark = Color(0xFF0B2A3A);

  // Semantic status
  static const Color mint = Color(0xFF00E599); // Phosphor Mint
  static const Color amber = Color(0xFFFFB020); // Amber Beacon
  static const Color crimson = Color(0xFFFF4757); // Crimson Warning
  static const Color success = Color(0xFF047857);
  static const Color successSoftLight = Color(0xFFE3F8EF);
  static const Color successSoftDark = Color(0xFF0B2E25);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSoftLight = Color(0xFFFFF4DE);
  static const Color warningSoftDark = Color(0xFF33260C);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoftLight = Color(0xFFFEECEE);
  static const Color dangerSoftDark = Color(0xFF3A1419);

  // Light neutrals: Crisp Milled Gray
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFEDF1F6);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF090D14);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF64748B);

  // Dark neutrals: Deep Obsidian / Milled Slate
  static const Color bgDark = Color(0xFF090D14);
  static const Color surfaceDark = Color(0xFF162032);
  static const Color surfaceMutedDark = Color(0xFF1E2B42);
  static const Color borderDark = Color(0xFF1F2E45);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF7C8BA1);

  /// Gradient kim loại cho thẻ nhận diện (phiên đang gửi, thẻ xe, vé).
  static const LinearGradient titaniumCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF222F43), Color(0xFF131B28), Color(0xFF0B1019)],
  );

  static const LinearGradient metallicCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B3A52), Color(0xFF182233), Color(0xFF0F1522)],
  );

  /// Màu chữ và viền trên nền titanium (luôn tối ở cả hai chế độ).
  static const Color onTitanium = Color(0xFFF1F5F9);
  static const Color onTitaniumMuted = Color(0xFF94A3B8);
  static const Color titaniumBorder = Color(0xFF2B3A52);
}

/// Bộ màu theo theme hiện tại, đọc qua `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color shadow;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.shadow,
  });

  static const light = AppPalette(
    bg: AppColors.bgLight,
    surface: AppColors.surfaceLight,
    surfaceMuted: AppColors.surfaceMutedLight,
    border: AppColors.borderLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    accent: AppColors.primaryDeep,
    accentSoft: AppColors.primarySoftLight,
    success: AppColors.success,
    successSoft: AppColors.successSoftLight,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoftLight,
    danger: AppColors.danger,
    dangerSoft: AppColors.dangerSoftLight,
    shadow: Color(0x14090D14),
  );

  static const dark = AppPalette(
    bg: AppColors.bgDark,
    surface: AppColors.surfaceDark,
    surfaceMuted: AppColors.surfaceMutedDark,
    border: AppColors.borderDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    accent: AppColors.primary,
    accentSoft: AppColors.primarySoftDark,
    success: AppColors.mint,
    successSoft: AppColors.successSoftDark,
    warning: AppColors.amber,
    warningSoft: AppColors.warningSoftDark,
    danger: AppColors.crimson,
    dangerSoft: AppColors.dangerSoftDark,
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
        bg: bg,
        surface: surface,
        surfaceMuted: surfaceMuted,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        accent: accent ?? this.accent,
        accentSoft: accentSoft,
        success: success,
        successSoft: successSoft,
        warning: warning,
        warningSoft: warningSoft,
        danger: danger,
        dangerSoft: dangerSoft,
        shadow: shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

import 'package:flutter/material.dart';

/// Bảng màu gốc lấy cảm hứng từ nội thất & cụm đồng hồ ô tô.
/// Chỉ dùng trực tiếp khi màu không phụ thuộc chế độ sáng/tối;
/// còn lại đọc qua `context.palette`.
class AppColors {
  AppColors._();

  // Carbon / Graphite (dark neutrals, tinted cool)
  static const Color carbon950 = Color(0xFF0D1013);
  static const Color carbon900 = Color(0xFF161A1F);
  static const Color graphite800 = Color(0xFF1F242B);
  static const Color graphite700 = Color(0xFF2B323B);
  static const Color graphite500 = Color(0xFF5B6573);
  static const Color graphite300 = Color(0xFFA3ACB8);

  // Porcelain (light neutrals, same cool hue family)
  static const Color porcelain50 = Color(0xFFF1F3F5);
  static const Color porcelain100 = Color(0xFFE7EAEE);
  static const Color porcelain200 = Color(0xFFD5DAE0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF12161B);
  static const Color inkSecondary = Color(0xFF4A5360);
  static const Color inkMuted = Color(0xFF636C7A);

  // Instrument panel (dark card used in both modes)
  static const Color panel = Color(0xFF0F1A2A);
  static const Color panelRaised = Color(0xFF17253A);
  static const Color panelLine = Color(0xFF263850);
  static const Color panelText = Color(0xFFE9EEF5);
  static const Color panelMuted = Color(0xFF8E9DB2);

  // Accents
  static const Color cobalt = Color(0xFF1F5FD1);
  static const Color cobaltBright = Color(0xFF5A8DF2);
  static const Color amber = Color(0xFFF2A21B);
  static const Color amberText = Color(0xFF9A5B00);
  static const Color amberBright = Color(0xFFF5B13D);
  static const Color emerald = Color(0xFF0B7A55);
  static const Color emeraldBright = Color(0xFF34C38F);
  static const Color signal = Color(0xFFB3302A);
  static const Color signalBright = Color(0xFFF06A5E);

  // Legacy aliases kept so untouched helpers still compile.
  static const Color primary = cobalt;
  static const Color success = emerald;
  static const Color warning = amberText;
  static const Color error = signal;
}

/// Vai trò màu theo chế độ sáng/tối.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;
  final Color danger;
  final Color dangerSoft;
  final Color plateBg;
  final Color plateText;
  final Color skeleton;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.plateBg,
    required this.plateText,
    required this.skeleton,
  });

  static const light = AppPalette(
    background: AppColors.porcelain50,
    surface: AppColors.white,
    surfaceRaised: AppColors.porcelain100,
    line: AppColors.porcelain200,
    text: AppColors.ink,
    textSecondary: AppColors.inkSecondary,
    textMuted: AppColors.inkMuted,
    accent: AppColors.cobalt,
    onAccent: AppColors.white,
    accentSoft: Color(0xFFE3ECFB),
    ok: AppColors.emerald,
    okSoft: Color(0xFFDDF2EA),
    warn: AppColors.amberText,
    warnSoft: Color(0xFFFCEFD6),
    danger: AppColors.signal,
    dangerSoft: Color(0xFFF8E1DF),
    plateBg: AppColors.white,
    plateText: AppColors.ink,
    skeleton: Color(0xFFE2E6EB),
  );

  static const dark = AppPalette(
    background: AppColors.carbon950,
    surface: AppColors.carbon900,
    surfaceRaised: AppColors.graphite800,
    line: AppColors.graphite700,
    text: Color(0xFFEDF0F3),
    textSecondary: AppColors.graphite300,
    textMuted: Color(0xFF8590A0),
    accent: AppColors.cobaltBright,
    onAccent: AppColors.carbon950,
    accentSoft: Color(0xFF1A2A46),
    ok: AppColors.emeraldBright,
    okSoft: Color(0xFF12301F),
    warn: AppColors.amberBright,
    warnSoft: Color(0xFF3A2A0E),
    danger: AppColors.signalBright,
    dangerSoft: Color(0xFF3A1714),
    plateBg: Color(0xFFF4F6F8),
    plateText: AppColors.ink,
    skeleton: AppColors.graphite800,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      line: l(line, other.line),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      ok: l(ok, other.ok),
      okSoft: l(okSoft, other.okSoft),
      warn: l(warn, other.warn),
      warnSoft: l(warnSoft, other.warnSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      plateBg: l(plateBg, other.plateBg),
      plateText: l(plateText, other.plateText),
      skeleton: l(skeleton, other.skeleton),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography System chuẩn Precision Minimalist / Swiss Grid
/// Display/Headings: Plus Jakarta Sans
/// Body/UI: Public Sans
/// Data/Numbers/Timers/Plates: JetBrains Mono (Tabular Figures)
class AppTypography {
  AppTypography._();

  // ===========================================================================
  // 1. DISPLAY & HEADINGS (Plus Jakarta Sans)
  // ===========================================================================
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.textPrimaryLight,
      );

  // ===========================================================================
  // 2. BODY & UI LABELS (Public Sans)
  // ===========================================================================
  static TextStyle get bodyLarge => GoogleFonts.publicSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get bodyMedium => GoogleFonts.publicSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondaryLight,
      );

  static TextStyle get bodySmall => GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textMutedLight,
      );

  static TextStyle get labelLarge => GoogleFonts.publicSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get labelMedium => GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textSecondaryLight,
      );

  static TextStyle get labelSmall => GoogleFonts.publicSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textMutedLight,
      );

  // ===========================================================================
  // 3. TABULAR DATA & TELEMETRY (JetBrains Mono - Chống giật số khi đếm giờ)
  // ===========================================================================
  /// Biển số xe (Ví dụ: 51H-982.34)
  static TextStyle get licensePlate => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textPrimaryLight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Đồng hồ đếm lùi thời gian đỗ (Ví dụ: 01:45:20)
  static TextStyle get timerLarge => GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get timerMedium => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Giá tiền VNĐ (Ví dụ: 25.000 ₫/h)
  static TextStyle get priceHighlight => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Mã vé xe / Mã QR Code reference
  static TextStyle get ticketCode => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.textSecondaryLight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ===========================================================================
  // 4. MATERIAL 3 COMPATIBILITY GETTERS
  // ===========================================================================
  static TextStyle get headlineMd => titleLarge;
  static TextStyle get headlineLg => displayMedium;
  static TextStyle get bodyMd => bodyMedium;
  static TextStyle get labelSm => labelSmall;
  static TextStyle get labelMd => labelMedium;
  static TextStyle get labelLg => labelLarge;
}

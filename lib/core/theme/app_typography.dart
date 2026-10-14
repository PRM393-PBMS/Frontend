import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography theo nhánh LongMainRes:
/// - Plus Jakarta Sans cho tiêu đề (đậm, tracking âm),
/// - Inter cho nội dung,
/// - JetBrains Mono cho biển số, mã vé, số liệu và huy hiệu.
/// Cả ba font đều hỗ trợ đầy đủ dấu tiếng Việt.
class AppTypography {
  AppTypography._();

  static TextStyle _display(double size, FontWeight weight,
          {double? height, double? letterSpacing}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _body(double size, FontWeight weight,
          {double? height, double? letterSpacing}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get display =>
      _display(30, FontWeight.w800, height: 1.15, letterSpacing: -1.0);
  static TextStyle get headline =>
      _display(24, FontWeight.w700, height: 1.2, letterSpacing: -0.8);
  static TextStyle get title =>
      _display(18, FontWeight.w700, height: 1.3, letterSpacing: -0.4);
  static TextStyle get titleSmall =>
      _display(16, FontWeight.w600, height: 1.35, letterSpacing: -0.3);
  static TextStyle get body => _body(15, FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _body(13.5, FontWeight.w400, height: 1.45);
  static TextStyle get label =>
      _body(14, FontWeight.w600, height: 1.3, letterSpacing: 0.1);
  static TextStyle get labelSmall =>
      _body(12, FontWeight.w600, height: 1.3, letterSpacing: 0.2);
  static TextStyle get caption => _body(12, FontWeight.w400, height: 1.4);

  /// Biển số, mã đơn hàng.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      );

  /// Số liệu lớn (tiền, số chỗ, thời gian) dạng telemetry.
  static TextStyle get figure => GoogleFonts.jetBrainsMono(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displayMedium: display.copyWith(color: primary),
        headlineSmall: headline.copyWith(color: primary),
        titleLarge: title.copyWith(color: primary),
        titleMedium: titleSmall.copyWith(color: primary),
        bodyLarge: body.copyWith(color: primary),
        bodyMedium: bodySmall.copyWith(color: secondary),
        labelLarge: label.copyWith(color: primary),
        labelMedium: labelSmall.copyWith(color: secondary),
        bodySmall: caption.copyWith(color: secondary),
      );
}

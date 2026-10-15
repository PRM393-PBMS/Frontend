import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hệ chữ:
/// - Barlow Semi Condensed: tiêu đề, gọn và sắc như biển chỉ dẫn đường bộ.
/// - Barlow: nội dung, dễ đọc lướt trên điện thoại.
/// - JetBrains Mono (tabular): biển số, giờ, chi phí, mã đơn.
class AppTypography {
  AppTypography._();

  static const _tabular = [FontFeature.tabularFigures()];

  /// Tắt trong test để không tải font qua mạng.
  static bool useGoogleFonts = true;

  static TextStyle _font(TextStyle Function({TextStyle? textStyle}) loader, TextStyle style) =>
      useGoogleFonts ? loader(textStyle: style) : style;

  static TextTheme textTheme(Color text, Color secondary) {
    TextStyle display(double size, FontWeight w, double tracking) =>
        _font(
          ({textStyle}) => GoogleFonts.barlowSemiCondensed(textStyle: textStyle),
          TextStyle(
            fontSize: size,
            fontWeight: w,
            height: 1.12,
            letterSpacing: tracking,
            color: text,
          ),
        );
    TextStyle body(double size, FontWeight w, {double height = 1.45, Color? c}) =>
        _font(
          ({textStyle}) => GoogleFonts.barlow(textStyle: textStyle),
          TextStyle(fontSize: size, fontWeight: w, height: height, color: c ?? text),
        );

    return TextTheme(
      displaySmall: display(34, FontWeight.w700, -0.6),
      headlineMedium: display(28, FontWeight.w700, -0.5),
      headlineSmall: display(24, FontWeight.w700, -0.4),
      titleLarge: display(21, FontWeight.w600, -0.2),
      titleMedium: body(16, FontWeight.w600, height: 1.3),
      titleSmall: body(14.5, FontWeight.w600, height: 1.3),
      bodyLarge: body(16, FontWeight.w400),
      bodyMedium: body(14.5, FontWeight.w400),
      bodySmall: body(13, FontWeight.w400, c: secondary),
      labelLarge: body(15, FontWeight.w600, height: 1.2),
      labelMedium: body(13, FontWeight.w600, height: 1.2),
      labelSmall: body(12, FontWeight.w500, height: 1.2, c: secondary),
    );
  }

  /// Số liệu: thời gian, tiền, mã. Luôn dùng chữ số tabular.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
  }) =>
      _font(
        ({textStyle}) => GoogleFonts.jetBrainsMono(textStyle: textStyle),
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing,
          height: 1.15,
          fontFeatures: _tabular,
        ),
      );

  /// Biển số xe.
  static TextStyle plate({double size = 15, Color? color}) => _font(
        ({textStyle}) => GoogleFonts.jetBrainsMono(textStyle: textStyle),
        TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.6,
          height: 1.1,
          fontFeatures: _tabular,
        ),
      );
}

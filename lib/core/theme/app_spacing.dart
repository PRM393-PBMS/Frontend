import 'package:flutter/material.dart';

/// Spacing, Border Radius & Swiss Grid Standards
class AppSpacing {
  AppSpacing._();

  // Grid Multiples (4pt / 8pt system)
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double pagePadding = 20.0;

  // Swiss Precision Hairlines
  static const double hairlineFine = 0.5;
  static const double hairline = 1.0;

  // Border Radius (Kỷ luật hình khối gọn gàng, tinh tế, không bo tròn quá đà)
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double radiusFull = 999.0;

  static final BorderRadius roundedXs = BorderRadius.circular(radiusXs);
  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
}

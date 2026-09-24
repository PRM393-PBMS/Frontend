import 'dart:math';
import 'package:flutter/material.dart';

/// Hệ thống Responsive Core dựa trên màn hình chuẩn Design Base 390x844 dp (iPhone 12/13/14)
class ResponsiveUtils {
  ResponsiveUtils._();

  static const double designWidth = 390.0;
  static const double designHeight = 844.0;

  static Size size(BuildContext context) => MediaQuery.sizeOf(context);
  static double width(BuildContext context) => size(context).width;
  static double height(BuildContext context) => size(context).height;

  static bool isSmallMobile(BuildContext context) => width(context) < 360;
  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 1024;
  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  static Orientation orientation(BuildContext context) => MediaQuery.orientationOf(context);
  static bool isPortrait(BuildContext context) => orientation(context) == Orientation.portrait;
  static bool isLandscape(BuildContext context) => orientation(context) == Orientation.landscape;

  static EdgeInsets padding(BuildContext context) => MediaQuery.paddingOf(context);
  static EdgeInsets viewInsets(BuildContext context) => MediaQuery.viewInsetsOf(context);

  /// Chiều rộng theo phần trăm màn hình (0 - 100)
  static double wp(BuildContext context, double percent) {
    return width(context) * (percent / 100);
  }

  /// Chiều cao theo phần trăm màn hình (0 - 100)
  static double hp(BuildContext context, double percent) {
    return height(context) * (percent / 100);
  }

  /// Tỷ lệ scale theo chiều ngang
  static double scaleWidth(BuildContext context) {
    return width(context) / designWidth;
  }

  /// Tỷ lệ scale theo chiều dọc
  static double scaleHeight(BuildContext context) {
    return height(context) / designHeight;
  }

  /// Scale font chữ có clamp giới hạn [minScale, maxScale]
  /// Giúp chống vỡ giao diện trên máy quá nhỏ hoặc khi hệ điều hành bật Text Zoom quá lớn
  static double sp(
    BuildContext context,
    double fontSize, {
    double minScale = 0.85,
    double maxScale = 1.25,
  }) {
    final scale = (width(context) / designWidth).clamp(minScale, maxScale);
    return fontSize * scale;
  }

  /// Scale icon có giới hạn min/max
  static double iconSize(
    BuildContext context,
    double baseSize, {
    double minScale = 0.9,
    double maxScale = 1.3,
  }) {
    final scale = (width(context) / designWidth).clamp(minScale, maxScale);
    return baseSize * scale;
  }

  /// Scale spacing/padding
  static double space(BuildContext context, double baseSpace) {
    final scale = min(scaleWidth(context), scaleHeight(context)).clamp(0.85, 1.3);
    return baseSpace * scale;
  }
}

/// Extension tiện lợi trên BuildContext để gọi trực tiếp context.wp(50), context.sp(16),...
extension ResponsiveContextExtension on BuildContext {
  Size get screenSize => ResponsiveUtils.size(this);
  double get screenWidth => ResponsiveUtils.width(this);
  double get screenHeight => ResponsiveUtils.height(this);

  bool get isSmallMobile => ResponsiveUtils.isSmallMobile(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  EdgeInsets get mediaPadding => ResponsiveUtils.padding(this);
  EdgeInsets get keyboardInsets => ResponsiveUtils.viewInsets(this);
  bool get isKeyboardOpen => keyboardInsets.bottom > 0;

  double wp(double percent) => ResponsiveUtils.wp(this, percent);
  double hp(double percent) => ResponsiveUtils.hp(this, percent);
  double sp(double fontSize, {double minScale = 0.85, double maxScale = 1.25}) =>
      ResponsiveUtils.sp(this, fontSize, minScale: minScale, maxScale: maxScale);
  double iconSize(double baseSize, {double minScale = 0.9, double maxScale = 1.3}) =>
      ResponsiveUtils.iconSize(this, baseSize, minScale: minScale, maxScale: maxScale);
  double space(double baseSpace) => ResponsiveUtils.space(this, baseSpace);
}

/// Extension trên số num để viết gọn: 20.wp(context), 16.sp(context)
extension ResponsiveNumExtension on num {
  double wp(BuildContext context) => ResponsiveUtils.wp(context, toDouble());
  double hp(BuildContext context) => ResponsiveUtils.hp(context, toDouble());
  double sp(BuildContext context, {double minScale = 0.85, double maxScale = 1.25}) =>
      ResponsiveUtils.sp(context, toDouble(), minScale: minScale, maxScale: maxScale);
  double icon(BuildContext context, {double minScale = 0.9, double maxScale = 1.3}) =>
      ResponsiveUtils.iconSize(context, toDouble(), minScale: minScale, maxScale: maxScale);
  double space(BuildContext context) => ResponsiveUtils.space(context, toDouble());
}

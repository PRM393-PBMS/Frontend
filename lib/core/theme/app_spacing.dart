import 'package:flutter/material.dart';

/// Spacing và hệ bo góc.
///
/// Quy tắc bo góc (áp dụng toàn app): control (nút, ô nhập, chip) = 12,
/// bề mặt (thẻ, sheet) = 14, huy hiệu trạng thái = 8.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double page = 16;

  /// Bề rộng tối đa của nội dung trên tablet / web.
  static const double maxContentWidth = 640;

  static const double radiusBadge = 8;
  static const double radiusControl = 12;
  static const double radiusSurface = 14;

  static final BorderRadius badge = BorderRadius.circular(radiusBadge);
  static final BorderRadius control = BorderRadius.circular(radiusControl);
  static final BorderRadius surface = BorderRadius.circular(radiusSurface);
}

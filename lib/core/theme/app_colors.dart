import 'package:flutter/material.dart';

/// Bảng màu PBMS: một màu nhấn duy nhất (teal), còn lại là trung tính và trạng thái.
class AppColors {
  AppColors._();

  // Màu nhấn duy nhất
  static const Color brand = Color(0xFF087B8C);
  static const Color brandTint = Color(0xFFEFFBFC);
  static const Color brandLine = Color(0xFF97DFEB);

  /// Bí danh của [brand] cho theme Material.
  static const Color primary = brand;
  static const Color primaryDark = Color(0xFF065F6B);

  // Trạng thái: đủ tương phản (>= 4.5:1) khi làm chữ trên nền trắng.
  static const Color success = Color(0xFF047857);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFDC2626);

  // Trung tính (sáng)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Trung tính (tối)
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
}

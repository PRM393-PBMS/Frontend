import 'package:flutter/material.dart';

/// Bảng màu chuẩn của PRM393 Parking Design System
class AppColors {
  AppColors._();

  // Primary Branding
  static const Color primary = Color(0xFF2563EB); // Modern Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Secondary & Accents
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFF6366F1); // Indigo

  // Semantic Status (Dành riêng cho trạng thái chỗ đỗ xe & thanh toán)
  static const Color available = Color(0xFF10B981); // Xanh lá: Chỗ trống / Đã thanh toán
  static const Color occupied = Color(0xFFEF4444);  // Đỏ: Đã có xe / Quá giờ
  static const Color reserved = Color(0xFFF59E0B);  // Vàng cam: Đã đặt trước
  static const Color maintenance = Color(0xFF6B7280); // Xám: Bảo trì

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral Colors (Light Mode)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Neutral Colors (Dark Mode)
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Material 3 tokens (onboarding / auth surfaces)
  static const Color m3Primary = Color(0xFF0058BC);
  static const Color m3OnPrimary = Color(0xFFFFFFFF);
  static const Color m3PrimaryFixed = Color(0xFFD8E2FF);
  static const Color m3OnPrimaryFixed = Color(0xFF001A41);
  static const Color m3PrimaryFixedDim = Color(0xFFADC6FF);
  static const Color m3Secondary = Color(0xFF006E28);
  static const Color m3SecondaryContainer = Color(0xFF6FFB85);
  static const Color m3SecondaryFixed = Color(0xFF72FE88);
  static const Color m3TertiaryContainer = Color(0xFFAC6300);
  static const Color m3Surface = Color(0xFFFCF8FB);
  static const Color m3SurfaceContainerLow = Color(0xFFF6F3F5);
  static const Color m3SurfaceContainer = Color(0xFFF0EDEF);
  static const Color m3SurfaceContainerHighest = Color(0xFFE4E2E4);
  static const Color m3OnSurface = Color(0xFF1B1B1D);
  static const Color m3OnSurfaceVariant = Color(0xFF414755);
  static const Color m3OutlineVariant = Color(0xFFC1C6D7);
  static const Color m3InverseSurface = Color(0xFF303032);
  static const Color m3InverseOnSurface = Color(0xFFF3F0F2);
}

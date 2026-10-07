import 'package:flutter/material.dart';

/// Bảng màu chuẩn PRM393 Parking Design System
/// Định hướng: Refined Cobalt Blue & Warm Sand (Precision Minimalist / Swiss Grid)
class AppColors {
  AppColors._();

  // Primary Branding (Refined Cobalt Blue)
  static const Color primary = Color(0xFF1D4ED8); // Refined Cobalt Blue (Trầm, cao cấp, tin cậy)
  static const Color primaryDark = Color(0xFF1E3A8A); // Deep Navy Cobalt
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Cobalt Accent
  static const Color primarySubtle = Color(0xFFEFF6FF); // Soft Cobalt Wash

  // Secondary & Accents
  static const Color secondary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF0F172A); // Deep Ink / Graphite

  // Semantic Status (Dành riêng cho trạng thái ô đỗ & giao dịch)
  static const Color available = Color(0xFF059669); // Signal Emerald: Chỗ trống / Đã thanh toán
  static const Color availableLight = Color(0xFFECFDF5);
  static const Color occupied = Color(0xFFDC2626);  // Signal Crimson: Đã có xe / Quá giờ
  static const Color occupiedLight = Color(0xFFFEF2F2);
  static const Color reserved = Color(0xFFD97706);  // Signal Amber: Đang giữ chỗ / Sắp hết giờ
  static const Color reservedLight = Color(0xFFFFFBEB);
  static const Color maintenance = Color(0xFF6B7280); // Neutral Steel: Tạm dừng / Bảo trì

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF1D4ED8);

  // Neutral Colors (Light Mode) - Warm Sand / Swiss Crisp Paper
  static const Color bgLight = Color(0xFFF9F9F8); // Warm Sand Tint (Tự nhiên, không xám lạnh nhân tạo)
  static const Color surfaceLight = Color(0xFFFFFFFF); // Clean Card Surface
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E5DF); // Hairline 1px border
  static const Color borderSubtle = Color(0xFFF0F0EB); // Hairline 0.5px line
  static const Color textPrimaryLight = Color(0xFF0F172A); // Deep Slate / Ink
  static const Color textSecondaryLight = Color(0xFF52525B); // Neutral Zinc
  static const Color textMutedLight = Color(0xFF9CA3AF); // Muted Mineral Gray

  // Neutral Colors (Dark Mode) - Deep Charcoal Precision
  static const Color bgDark = Color(0xFF0A0D14);
  static const Color surfaceDark = Color(0xFF141A24);
  static const Color cardDark = Color(0xFF141A24);
  static const Color borderDark = Color(0xFF263040);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Material 3 Token Compatibility Map (Đồng bộ về tông Refined Cobalt & Sand)
  static const Color m3Primary = Color(0xFF1D4ED8);
  static const Color m3OnPrimary = Color(0xFFFFFFFF);
  static const Color m3PrimaryFixed = Color(0xFFDBEAFE);
  static const Color m3OnPrimaryFixed = Color(0xFF1E3A8A);
  static const Color m3PrimaryFixedDim = Color(0xFFBFDBFE);
  static const Color m3Secondary = Color(0xFF059669);
  static const Color m3SecondaryContainer = Color(0xFFD1FAE5);
  static const Color m3SecondaryFixed = Color(0xFFA7F3D0);
  static const Color m3TertiaryContainer = Color(0xFFFEF3C7);
  static const Color m3Surface = Color(0xFFF9F9F8);
  static const Color m3SurfaceContainerLow = Color(0xFFF4F4F1);
  static const Color m3SurfaceContainer = Color(0xFFEEEEEC);
  static const Color m3SurfaceContainerHighest = Color(0xFFE5E5E2);
  static const Color m3OnSurface = Color(0xFF0F172A);
  static const Color m3OnSurfaceVariant = Color(0xFF52525B);
  static const Color m3OutlineVariant = Color(0xFFE5E5DF);
  static const Color m3InverseSurface = Color(0xFF18181B);
  static const Color m3InverseOnSurface = Color(0xFFFAFAFA);
}

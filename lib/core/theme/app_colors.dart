import 'package:flutter/material.dart';

/// Precision Architectural & Dark-Tech Mobility Color System
class AppColors {
  AppColors._();

  // Primary Branding (Electric Ice / Precision Cyan)
  static const Color primary = Color(0xFF00E5FF); // Electric Precision Cyan
  static const Color primaryDark = Color(0xFF0284C7); // Deep Tech Blue
  static const Color primaryLight = Color(0xFF7DD3FC); // Soft Cyan Highlight

  // Secondary & Accents
  static const Color secondary = Color(0xFF38BDF8); // Sky Ice
  static const Color accent = Color(0xFF6366F1); // Indigo Telemetry

  // Precision Telemetry & Semantic Status
  static const Color available = Color(0xFF00E599); // Phosphor Mint: Chỗ trống / Đã thanh toán
  static const Color occupied = Color(0xFFFF4757);  // Crimson Warning: Đã có xe / Quá giờ
  static const Color reserved = Color(0xFFFFB020);  // Amber Beacon: Đã đặt trước
  static const Color maintenance = Color(0xFF64748B); // Slate Muted: Bảo trì

  static const Color success = Color(0xFF00E599);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF38BDF8);

  // Surfaces & Backgrounds - Precision Dark-Tech (Flagship)
  static const Color bgDark = Color(0xFF090D14); // Deep Obsidian
  static const Color surfaceDark = Color(0xFF0F172A); // Architectural Charcoal
  static const Color cardDark = Color(0xFF162032); // Milled Slate Surface
  static const Color cardElevatedDark = Color(0xFF1E2B42); // Elevated Interactive Card
  static const Color borderDark = Color(0xFF1F2E45); // Milled Hairline Border
  static const Color borderSubtleDark = Color(0xFF172336);
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Crisp Off-White
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Muted Slate
  static const Color textMutedDark = Color(0xFF64748B); // Low-contrast Metadata

  // Surfaces & Backgrounds - Architectural Light Mode
  static const Color bgLight = Color(0xFFF4F6F9); // Crisp Milled Gray
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF090D14);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Titanium & Metallic Material Accents
  static const LinearGradient titaniumCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF222F43),
      Color(0xFF131B28),
      Color(0xFF0B1019),
    ],
  );

  static const LinearGradient metallicCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B3A52),
      Color(0xFF182233),
      Color(0xFF0F1522),
    ],
  );
}

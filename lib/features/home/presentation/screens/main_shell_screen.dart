import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/theme_controller.dart';
import 'package:prm393_frontend/core/widgets/floating_bottom_nav_bar.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/services_popup_sheet.dart';
import 'package:prm393_frontend/core/localization/app_language.dart';
import 'package:prm393_frontend/core/localization/app_translations.dart';
import 'package:prm393_frontend/features/profile/presentation/screens/profile_screen.dart';

/// Dual-Responsive Master Shell (Web Desktop Navigation Rail & Mobile Compact Dock)
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTab = 0;

  List<NavTab> _getTabs(BuildContext context) => [
    NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: context.tr('nav_home')),
    NavTab(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: context.tr('nav_history')),
    NavTab(icon: Icons.widgets_outlined, activeIcon: Icons.widgets_rounded, label: context.tr('nav_services')),
    NavTab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: context.tr('nav_profile')),
  ];

  Widget _bodyForTab(int idx) {
    switch (idx) {
      case 0:
        return const HomeScreen();
      case 1:
        return const _PlaceholderPage(
          icon: Icons.history_rounded,
          label: 'Lịch sử giao dịch & Đỗ xe',
          color: AppColors.secondary,
        );
      case 3:
        return const HomeScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void _handleCenterTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 10),
            Text('Tính năng cốt lõi: Đặt chỗ gửi xe thông minh (Reserve Slot)'),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          // ===================================================================
          // DESKTOP / WEB PORTAL SPLIT ARCHITECTURE (260px Rail + Content)
          // ===================================================================
          return Scaffold(
            backgroundColor: bgColor,
            body: Row(
              children: [
                _buildDesktopSidebar(context),
                Expanded(
                  child: Container(
                    color: bgColor,
                    child: _bodyForTab(_currentTab),
                  ),
                ),
              ],
            ),
          );
        }

        // ===================================================================
        // MOBILE / TABLET COMPACT ARCHITECTURE (Full Cockpit + Floating Pill)
        // ===================================================================
        return Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          body: _bodyForTab(_currentTab),
          bottomNavigationBar: FloatingBottomNavBar(
            currentIndex: _currentTab,
            onTabChanged: (i) {
              if (i == 3) {
                ServicesPopupSheet.show(context);
              } else {
                setState(() => _currentTab = i);
              }
            },
            tabs: _getTabs(context),
            centerIcon: Icons.add_rounded,
            centerColor: AppColors.primary,
            onCenterTap: _handleCenterTap,
            radialOptions: [
              RadialOption(
                icon: Icons.calendar_month_rounded,
                label: 'Đặt chỗ',
                color: AppColors.primary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('→ POST /api/reservations'), behavior: SnackBarBehavior.floating),
                ),
              ),
              RadialOption(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Quét QR',
                color: AppColors.secondary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('→ POST /api/ParkingOperation/upload-and-decode-qr'), behavior: SnackBarBehavior.floating),
                ),
              ),
              RadialOption(
                icon: Icons.card_membership_rounded,
                label: 'Vé tháng',
                color: AppColors.accent,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('→ GET /api/MonthlySubscription/my'), behavior: SnackBarBehavior.floating),
                ),
              ),
              RadialOption(
                icon: Icons.report_problem_outlined,
                label: 'Sự cố',
                color: AppColors.warning,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('→ POST /api/IncidentReport'), behavior: SnackBarBehavior.floating),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DESKTOP SIDEBAR NAVIGATION RAIL
  // ===========================================================================
  Widget _buildDesktopSidebar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final railBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: railBg,
        border: Border(right: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          // Brand Logo & System Telemetry
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.local_parking_rounded, color: Color(0xFF090D14), size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PBMS',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // Navigation Links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildSidebarNavItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: context.tr('desktop_sidebar_cockpit'),
                ),
                _buildSidebarNavItem(
                  context,
                  index: 1,
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_toggle_off_rounded,
                  label: context.tr('desktop_sidebar_history'),
                ),
                _buildSidebarNavItem(
                  context,
                  index: 3,
                  icon: Icons.widgets_outlined,
                  activeIcon: Icons.widgets_rounded,
                  label: context.tr('desktop_sidebar_services'),
                  onTapOverride: () => ServicesPopupSheet.show(context),
                ),
                _buildSidebarNavItem(
                  context,
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: context.tr('desktop_sidebar_profile'),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Fast Action Buttons in Rail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _handleCenterTap,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(context.tr('desktop_reserve_slot')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.primary : const Color(0xFF090D14),
                    foregroundColor: isDark ? const Color(0xFF090D14) : Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ServicesPopupSheet.show(context),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(context.tr('desktop_scan_qr')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    side: BorderSide(color: borderColor),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // User Profile Dock in Sidebar Bottom
          BlocBuilder<AuthBloc, dynamic>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : const Color(0xFF090D14),
                      child: Text(
                        'L',
                        style: TextStyle(
                          color: isDark ? AppColors.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thành Long',
                            style: AppTypography.titleSmall.copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'VIP Resident',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Text(
                        LanguageController.instance.currentLanguage.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      tooltip: context.tr('item_language'),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final cur = LanguageController.instance.currentLanguage;
                        final next = cur == AppLanguage.vi
                            ? AppLanguage.en
                            : (cur == AppLanguage.en ? AppLanguage.ja : AppLanguage.vi);
                        LanguageController.instance.setLanguage(next);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFFFFB020) : const Color(0xFF0F172A),
                      ),
                      tooltip: isDark ? 'Chuyển sang Tông màu sáng' : 'Chuyển sang Tông màu tối',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ThemeController.instance.toggleTheme();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
);
        },
      ),
    );
  }

  Widget _buildSidebarNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    VoidCallback? onTapOverride,
  }) {
    final active = _currentTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTapOverride ?? () => setState(() => _currentTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? AppColors.cardDark : const Color(0xFF090D14))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? (isDark ? AppColors.borderDark : const Color(0xFF090D14))
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 20,
                  color: active
                      ? (isDark ? AppColors.primary : Colors.white)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? (isDark ? AppColors.textPrimaryDark : Colors.white)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple placeholder for unimplemented tabs
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlaceholderPage({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tính năng đang được hoàn thiện theo chuẩn Dark-Tech Mobility',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
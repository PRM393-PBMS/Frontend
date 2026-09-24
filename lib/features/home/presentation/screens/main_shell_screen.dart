import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/floating_bottom_nav_bar.dart';
import 'package:prm393_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/services_popup_sheet.dart';
import 'package:prm393_frontend/features/profile/presentation/screens/profile_screen.dart';

/// Thanh điều hướng dùng chung với Floating Glass Pill + Radial Arc Menu
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTab = 0;

  // ---- Tab definitions (4 items, center button is separate) ----
  static const _tabs = [
    NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ'),
    NavTab(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'Lịch sử'),
    NavTab(icon: Icons.widgets_outlined, activeIcon: Icons.widgets_rounded, label: 'Dịch vụ'),
    NavTab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Hồ sơ'),
  ];

  // ---- Body pages per tab index (0, 1, 3, 4 — tab 2 is center CTA) ----
  Widget _bodyForTab(int idx) {
    switch (idx) {
      case 0: return const HomeScreen();
      case 1: return _PlaceholderPage(icon: Icons.history_rounded, label: 'Lịch sử giao dịch', color: AppColors.secondary);
      case 3: return const HomeScreen(); // Fallback keep home active when services popup closes
      case 4: return const ProfileScreen();
      default: return const HomeScreen();
    }
  }

  void _handleCenterTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng chính: Đặt chỗ gửi xe'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      // extendBody so ListView content scrolls behind the floating bar
      extendBody: true,
      body: _bodyForTab(_currentTab),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentTab,
        onTabChanged: (i) {
          if (i == 3) {
            // Nhấp vào Dịch vụ trên taskbar -> mở popup modal
            ServicesPopupSheet.show(context);
          } else {
            setState(() => _currentTab = i);
          }
        },
        tabs: _tabs,
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
  }
}

// ---- Simple placeholder for unimplemented tabs ----
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlaceholderPage({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Padding(
        padding: EdgeInsets.only(bottom: 84.0 + bottomPad),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Tính năng đang phát triển', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
            ],
          ),
        ),
      ),
    );
  }
}
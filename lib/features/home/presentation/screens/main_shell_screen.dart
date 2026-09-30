import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/floating_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:prm393_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/screens/monthly_pass_screen.dart';

/// Thanh điều hướng dùng chung với Floating Glass Pill + Radial Arc Menu
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTab = 0;

  // ---- Main destinations ----
  static const _tabs = [
    NavTab(
        icon: Icons.local_parking_outlined,
        activeIcon: Icons.local_parking_rounded,
        label: 'Đặt chỗ'),
    NavTab(
        icon: Icons.history_outlined,
        activeIcon: Icons.history_rounded,
        label: 'Lịch sử'),
    NavTab(
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership_rounded,
        label: 'Vé tháng'),
    NavTab(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cá nhân'),
  ];

  // ---- Body pages per tab index ----
  Widget _bodyForTab(int idx) {
    switch (idx) {
      case 0:
        return HomeDashboardScreen(
          onOpenMap: (lotId) => context.push(RouteNames.mapPath, extra: lotId),
        );
      case 1:
        return _PlaceholderPage(
            icon: Icons.history_rounded,
            label: 'Lịch sử giao dịch',
            color: AppColors.secondary);
      case 2:
        return const MonthlyPassScreen();
      case 3:
        return const ProfileScreen();
      default:
        return HomeDashboardScreen(
          onOpenMap: (lotId) => context.push(RouteNames.mapPath, extra: lotId),
        );
    }
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
        onTabChanged: (i) => setState(() => _currentTab = i),
        tabs: _tabs,
        radialOptions: const [],
        onCenterTap: () {},
        showCenterButton: false,
      ),
    );
  }
}

// ---- Simple placeholder for unimplemented tabs ----
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PlaceholderPage(
      {required this.icon, required this.label, required this.color});

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
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Tính năng đang phát triển',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMutedLight)),
            ],
          ),
        ),
      ),
    );
  }
}

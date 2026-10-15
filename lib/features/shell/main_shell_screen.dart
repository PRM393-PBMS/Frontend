import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../account/account_screen.dart';
import '../home/home_screen.dart';
import '../pass/monthly_pass_screen.dart';
import '../reserve/reserve_screen.dart';
import '../sessions/sessions_screen.dart';
import 'shell_scope.dart';

/// Khung chính với Material 3 NavigationBar. Tab được dựng khi mở lần đầu
/// và giữ trạng thái khi chuyển qua lại.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = AppTab.home;
  final Set<int> _visited = {AppTab.home};
  final ValueNotifier<int> _revision = ValueNotifier(0);

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.speed_outlined),
      selectedIcon: Icon(Icons.speed_rounded),
      label: 'Tổng quan',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_available_outlined),
      selectedIcon: Icon(Icons.event_available_rounded),
      label: 'Đặt chỗ',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Lượt gửi',
    ),
    NavigationDestination(
      icon: Icon(Icons.badge_outlined),
      selectedIcon: Icon(Icons.badge_rounded),
      label: 'Vé tháng',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Tài khoản',
    ),
  ];

  void _goTab(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  Widget _page(int index) => switch (index) {
        AppTab.home => const HomeScreen(),
        AppTab.reserve => const ReserveScreen(),
        AppTab.sessions => const SessionsScreen(),
        AppTab.pass => const MonthlyPassScreen(),
        _ => const AccountScreen(),
      };

  @override
  void dispose() {
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ShellScope(
      goTab: _goTab,
      revision: _revision,
      child: PopScope(
        canPop: _index == AppTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goTab(AppTab.home);
        },
        child: Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < _destinations.length; i++)
                _visited.contains(i)
                    ? TickerMode(enabled: i == _index, child: _page(i))
                    : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goTab,
              destinations: _destinations,
            ),
          ),
        ),
      ),
    );
  }
}

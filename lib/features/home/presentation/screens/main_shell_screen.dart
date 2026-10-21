import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/services/push_notification_service.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/widgets/pbms_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/features/history/presentation/screens/history_screen.dart';
import 'package:prm393_frontend/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:prm393_frontend/features/home/presentation/shell_scope.dart';
import 'package:prm393_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/screens/monthly_pass_screen.dart';
import 'package:prm393_frontend/features/wallet/presentation/screens/wallet_screen.dart';

/// Khung chính: 4 tab và nút Ví của tôi ở giữa thanh dưới.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTab = AppTab.home;
  final Set<int> _visited = {AppTab.home};
  final ValueNotifier<int> _revision = ValueNotifier(0);

  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    // Chỉ khi đã đăng nhập mới kiểm tra thông báo mới để đẩy lên điện thoại.
    PushNotificationService.instance.attach(context.read<PbmsRepository>());
    // Trang kết quả PayOS mở lại app: tải lại dữ liệu và báo kết quả.
    _links = AppLinks().uriLinkStream.listen(_onLink, onError: (_) {});
  }

  void _onLink(Uri uri) {
    if (uri.scheme != 'pbms' || uri.host != 'payment-result' || !mounted) return;
    _revision.value++;
    final message = switch (uri.queryParameters['status']) {
      'success' => 'Thanh toán thành công.',
      'cancelled' => 'Đã huỷ thanh toán, bạn chưa bị trừ tiền.',
      'failed' => 'Thanh toán không thành công, bạn chưa bị trừ tiền.',
      'pending' => 'Đang chờ ngân hàng xác nhận thanh toán.',
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      ));
  }

  // ---- Main destinations ----
  static const _tabs = [
    NavTab(
        icon: Icons.local_parking_outlined,
        activeIcon: Icons.local_parking_rounded,
        label: 'Gửi xe'),
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

  void _goTab(int index) {
    if (index == _currentTab) return;
    setState(() {
      _currentTab = index;
      _visited.add(index);
    });
  }

  Future<void> _openMap(String? lotId) async {
    await context.push(RouteNames.mapPath, extra: lotId);
    // Có thể vừa đặt chỗ ở màn bản đồ → làm mới các tab.
    _revision.value++;
  }

  Future<void> _openWallet() async {
    await Navigator.of(context).push(WalletScreen.riseRoute());
    // Có thể vừa nạp tiền / trả phí → làm mới các tab.
    _revision.value++;
  }

  // ---- Body pages per tab index ----
  Widget _bodyForTab(int idx) {
    switch (idx) {
      case AppTab.history:
        return const HistoryScreen();
      case AppTab.pass:
        return const MonthlyPassScreen();
      case AppTab.profile:
        return const ProfileScreen();
      default:
        return HomeDashboardScreen(onOpenMap: _openMap);
    }
  }

  @override
  void dispose() {
    _links?.cancel();
    _revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      goTab: _goTab,
      revision: _revision,
      child: PopScope(
        canPop: _currentTab == AppTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goTab(AppTab.home);
        },
        child: Scaffold(
          backgroundColor: AppColors.bgLight,
          // extendBody so ListView content scrolls behind the floating bar
          extendBody: true,
          body: IndexedStack(
            index: _currentTab,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                _visited.contains(i)
                    ? TickerMode(enabled: i == _currentTab, child: _bodyForTab(i))
                    : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: PbmsBottomBar(
            currentIndex: _currentTab,
            onTabChanged: _goTab,
            tabs: _tabs,
            centerIcon: Icons.account_balance_wallet_rounded,
            centerLabel: 'Ví',
            onCenterTap: _openWallet,
          ),
        ),
      ),
    );
  }
}

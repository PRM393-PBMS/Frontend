import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/network/connectivity_status.dart';
import 'package:prm393_frontend/core/services/push_notification_service.dart';
import 'package:prm393_frontend/core/services/shell_actions.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:prm393_frontend/features/map/presentation/lot_map_screen.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
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
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    // Chỉ khi đã đăng nhập mới kiểm tra thông báo mới để đẩy lên điện thoại.
    PushNotificationService.instance.attach(context.read<PbmsRepository>());
    // Bấm thông báo (khay, danh sách, thông báo đang gửi xe): mở đúng màn.
    ShellActions.pending.addListener(_runPendingAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPendingAction());
    // Mất mạng: thử tải lại mỗi 20 giây, có mạng lại thì thanh ngoại tuyến tự tắt.
    ConnectivityStatus.offline.addListener(_onConnectivity);
    // Trang kết quả PayOS mở lại app: tải lại dữ liệu và báo kết quả.
    _links = AppLinks().uriLinkStream.listen(_onLink, onError: (_) {});
  }

  void _onLink(Uri uri) {
    if (uri.scheme == 'pbms' && uri.host == 'widget' && mounted) {
      _onWidgetLink(uri);
      return;
    }
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

  /// Bấm widget màn hình chính: pbms://widget/exit-pass | reservation?lot=... | home.
  void _onWidgetLink(Uri uri) {
    final action = uri.pathSegments.firstOrNull;
    switch (action) {
      case 'exit-pass':
        ShellActions.request(const OpenExitPass());
      case 'reservation':
        ShellActions.request(OpenLotMap(parkingId: uri.queryParameters['lot']));
      default:
        _goTab(AppTab.home);
    }
  }

  void _onConnectivity() {
    if (!mounted) return;
    setState(() {});
    _retry?.cancel();
    _retry = ConnectivityStatus.offline.value
        ? Timer.periodic(const Duration(seconds: 20), (_) => _revision.value++)
        : null;
  }

  Future<void> _runPendingAction() async {
    final action = ShellActions.pending.value;
    if (action == null || !mounted) return;
    ShellActions.pending.value = null;
    final repo = context.read<PbmsRepository>();
    try {
      switch (action) {
        case OpenLotMap(:final slotCode, :final entryGateName, :final parkingId):
          await LotMapScreen.open(context, lotId: parkingId, targetSlotCode: slotCode, entryGateName: entryGateName);
        case OpenTopUp(:final amount):
          final wallet = await repo.getWallet();
          if (!mounted) return;
          final paid = await TopUpSheet.show(context, wallet, initialAmount: amount);
          if (paid == true) _revision.value++;
        case OpenRenew(:final subscriptionId):
          _goTab(AppTab.pass);
          MonthlyPassScreen.renewRequest.value = subscriptionId;
        case OpenExitPass():
          await _openExitPass(repo);
      }
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  /// Mã ra cổng của xe đang gửi; chưa trả trước thì mở vé để trả. Mất mạng thì dùng vé đã lưu.
  Future<void> _openExitPass(PbmsRepository repo) async {
    _goTab(AppTab.home);
    ParkingSessionModel? session;
    try {
      session = (await repo.getMySessions()).where((s) => s.isActive).firstOrNull;
    } catch (_) {
      session = (await repo.cachedActiveSession())?.session;
    }
    if (!mounted) return;
    if (session == null) {
      showPbmsSnack(context, 'Không còn xe nào đang gửi.');
      return;
    }
    final pass = session.exitPass;
    if (pass == null) {
      await SessionDetailSheet.show(context, session);
      _revision.value++;
      return;
    }
    await PbmsQrDialog.show(
      context,
      title: 'Mã ra cổng',
      payload: pass.qrPayload,
      plate: session.licensePlateIn,
      isMotorbike: session.isMotorbike,
      code: pass.code,
      rows: [
        (Icons.info_outline_rounded, 'Dùng khi', 'Camera không đọc được biển số'),
        if (session.slotCode != null) (Icons.local_parking_rounded, 'Vị trí đỗ', session.slotCode!),
      ],
    );
  }

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
    ShellActions.pending.removeListener(_runPendingAction);
    ConnectivityStatus.offline.removeListener(_onConnectivity);
    _retry?.cancel();
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
          body: Column(
            children: [
              if (ConnectivityStatus.offline.value) const _OfflineBar(),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  // Thanh ngoại tuyến đã chiếm phần tai thỏ: các tab không chừa thêm lần nữa.
                  removeTop: ConnectivityStatus.offline.value,
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        _visited.contains(i)
                            ? TickerMode(enabled: i == _currentTab, child: _bodyForTab(i))
                            : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: PbmsBottomBar(
            currentIndex: _currentTab,
            onTabChanged: _goTab,
            tabs: _tabs,
            centerIcon: Icons.account_balance_wallet_rounded,
            centerLabel: 'Ví của tôi',
            onCenterTap: _openWallet,
          ),
        ),
      ),
    );
  }
}

/// Mất kết nối tới máy chủ: một thanh chung thay vì báo lỗi ở từng chỗ.
class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1E293B),
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 6, 16, 8),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đang ngoại tuyến. Vé đang gửi và mã ra cổng vẫn mở được.',
                style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

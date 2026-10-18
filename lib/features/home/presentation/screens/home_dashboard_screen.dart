import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:prm393_frontend/core/services/location_service.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:prm393_frontend/features/home/presentation/shell_scope.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/notifications_bottom_sheet.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/promo_carousel.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';
import 'package:prm393_frontend/features/reservations/presentation/widgets/reservation_actions.dart';
import 'package:prm393_frontend/features/wallet/presentation/screens/wallet_screen.dart';

/// Lượt gửi đang diễn ra hoặc đặt chỗ sắp tới, ưu tiên xe đang trong bãi.
typedef _Activity = ({
  ParkingSessionModel? session,
  ReservationModel? reservation,
  PricingPolicyModel? sessionPricing,
});

class HomeDashboardScreen extends StatefulWidget {
  /// Mở bản đồ, có thể chọn sẵn một bãi.
  final ValueChanged<String?> onOpenMap;

  const HomeDashboardScreen({super.key, required this.onOpenMap});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _lots = AsyncCubit<List<LotView>>(() => LotView.load(
        lots: _repo.getParkingLots,
        facility: _repo.getAvailability,
        pricing: _repo.getPricingPolicies,
        sessions: _repo.getMySessions,
        slots: _repo.getAllSlots,
      ));
  late final _activity = AsyncCubit<_Activity>(_loadActivity);
  int _unread = 0;
  Timer? _ticker;

  /// Vị trí thực tế của khách để gợi ý bãi gần nhất.
  LocationResult? _loc;
  bool _locating = false;
  StreamSubscription<AsyncState<List<LotView>>>? _lotsSub;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _locate();
    // Dòng "Gần bãi X" ở đầu trang cần danh sách bãi: vẽ lại khi tải xong.
    _lotsSub = _lots.stream.listen((_) {
      if (mounted) setState(() {});
    });
    // Đồng hồ thời gian đỗ cập nhật mỗi phút.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void reloadAll() {
    _lots.load();
    _activity.load();
    _loadUnread();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lotsSub?.cancel();
    _lots.close();
    _activity.close();
    super.dispose();
  }

  Future<_Activity> _loadActivity() async {
    final results = await Future.wait([
      _repo.getMySessions(),
      _repo.getMyReservations(),
      _repo.getPricingPolicies(),
    ]);
    final sessions = results[0] as List<ParkingSessionModel>;
    final reservations = results[1] as List<ReservationModel>;
    final pricing = results[2] as List<PricingPolicyModel>;
    final active = sessions.where((s) => s.isActive).firstOrNull;
    final upcoming = reservations.where((r) => r.canModify).toList()
      ..sort((a, b) => a.expectedEntryTime.compareTo(b.expectedEntryTime));
    return (
      session: active,
      reservation: upcoming.firstOrNull,
      sessionPricing: active == null
          ? null
          : pricing
              .where((p) => p.vehicleTypeName == active.vehicleTypeName)
              .firstOrNull,
    );
  }

  Future<void> _locate({bool fresh = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    final r = await LocationService.instance.current(fresh: fresh);
    if (!mounted) return;
    setState(() {
      _loc = r;
      _locating = false;
    });
  }

  /// Bấm dòng vị trí: lấy lại vị trí, hoặc mở cài đặt nếu quyền / GPS đang tắt.
  Future<void> _onLocationTap() async {
    switch (_loc?.status) {
      case LocationStatus.serviceOff:
        await Geolocator.openLocationSettings();
      case LocationStatus.deniedForever:
        await Geolocator.openAppSettings();
      default:
        await _locate(fresh: true);
    }
  }

  Future<void> _loadUnread() async {
    try {
      final page = await _repo.getNotifications();
      if (mounted) setState(() => _unread = page.unreadCount);
    } catch (_) {
      // Huy hiệu chưa đọc không chặn trang chủ.
    }
  }

  String get _locationLabel {
    if (_locating) return 'Đang lấy vị trí của bạn...';
    switch (_loc?.status) {
      case LocationStatus.ok:
        final lots = _lots.state.data ?? const <LotView>[];
        final pos = _loc!.position;
        final near = lots.where((l) => l.distanceFrom(pos) != null).toList()
          ..sort(
              (a, b) => a.distanceFrom(pos)!.compareTo(b.distanceFrom(pos)!));
        if (near.isEmpty) return 'Đã lấy vị trí của bạn';
        return 'Gần ${near.first.name}, ${LocationService.formatDistance(near.first.distanceFrom(pos)!)}';
      case LocationStatus.serviceOff:
        return 'Bật GPS để gợi ý bãi gần bạn';
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        return 'Cho phép vị trí để gợi ý bãi gần bạn';
      case LocationStatus.failed:
        return 'Chưa lấy được vị trí, chạm để thử lại';
      case null:
        return 'Vị trí của bạn';
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: PbmsTokens.teal,
          onRefresh: () async => reloadAll(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 112 + bottomInset),
            children: [
              _buildHeader(context),
              const SizedBox(height: 22),
              _buildPromos(context),
              const SizedBox(height: 14),
              PbmsAsync<List<LotView>>(
                cubit: _lots,
                loadingHeight: 58,
                errorTitle: 'Không tải được chỗ trống',
                builder: _buildNearbyButton,
              ),
              const SizedBox(height: 20),
              PbmsAsync<_Activity>(
                cubit: _activity,
                loadingHeight: 160,
                errorTitle: 'Không tải được lượt gửi xe',
                builder: _buildActivity,
              ),
              const SizedBox(height: 22),
              PbmsAsync<List<LotView>>(
                cubit: _lots,
                loadingHeight: 180,
                errorTitle: 'Không tải được chỗ trống',
                isEmpty: (d) => d.every((l) => l.total == 0),
                empty: const PbmsEmptyView(
                  icon: Icons.local_parking_rounded,
                  title: 'Bãi chưa mở ô đỗ nào',
                  message:
                      'Khi bãi cấu hình tầng và ô đỗ, chỗ trống sẽ hiện ở đây.',
                ),
                builder: (lots) => lots.length > 1
                    ? _buildLotSuggestions(lots)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PbmsSectionTitle('Chỗ trống theo loại xe'),
                          for (final c in lots.first.capacities) ...[
                            _CapacityCard(
                                capacity: c,
                                onOpenMap: () =>
                                    widget.onOpenMap(lots.first.id)),
                            const SizedBox(height: 11),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nhiều bãi: "Bãi gần bạn" (theo GPS), "Bãi thường dùng" (theo lượt gửi),
  /// rồi các bãi còn lại (còn chỗ lên trước).
  Widget _buildLotSuggestions(List<LotView> lots) {
    final pos = _loc?.position;
    final nearby = lots.where((l) => l.distanceFrom(pos) != null).toList()
      ..sort((a, b) => a.distanceFrom(pos)!.compareTo(b.distanceFrom(pos)!));
    final frequent = lots.where((l) => l.visits > 0).toList()
      ..sort((a, b) => b.visits.compareTo(a.visits));
    final shown = {
      ...nearby.take(3).map((l) => l.id),
      ...frequent.take(3).map((l) => l.id)
    };
    final others = lots.where((l) => !shown.contains(l.id)).toList()
      ..sort((a, b) => b.available.compareTo(a.available));

    Widget card(LotView l) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: _LotCard(
            lot: l,
            distance: l.distanceFrom(pos),
            onOpenMap: widget.onOpenMap,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nearby.isNotEmpty) ...[
          const PbmsSectionTitle('Bãi gần bạn'),
          ...nearby.take(3).map(card),
          const SizedBox(height: 11),
        ] else if (_loc?.ok == true) ...[
          const PbmsCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: PbmsTokens.teal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Các bãi chưa được nhập toạ độ nên chưa sắp xếp được theo khoảng cách.',
                    style: PbmsText.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (frequent.isNotEmpty) ...[
          const PbmsSectionTitle('Bãi thường dùng'),
          ...frequent.take(3).map(card),
          const SizedBox(height: 11),
        ],
        if (others.isNotEmpty) ...[
          PbmsSectionTitle(
            shown.isEmpty ? 'Gợi ý bãi đỗ' : 'Các bãi khác',
            trailing: Text(
                '${others.where((l) => l.available > 0).length} bãi còn chỗ',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PbmsTokens.teal)),
          ),
          ...others.map(card),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final fullName = (user?.fullName ?? '').trim();
        final displayName = fullName.isNotEmpty
            ? fullName.split(RegExp(r'\s+')).last
            : (user?.userName ?? 'bạn');
        final initial =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _onLocationTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              _loc?.ok == true
                                  ? Icons.near_me_rounded
                                  : Icons.location_disabled_outlined,
                              size: 16,
                              color: PbmsTokens.teal),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(_locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PbmsText.caption),
                          ),
                          const Icon(Icons.refresh_rounded,
                              size: 15, color: PbmsTokens.muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_greeting, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PbmsText.headline,
                  ),
                ],
              ),
            ),
            Badge(
              isLabelVisible: _unread > 0,
              label: Text(_unread > 9 ? '9+' : '$_unread'),
              backgroundColor: PbmsTokens.danger,
              offset: const Offset(-4, 4),
              child: IconButton(
                tooltip:
                    _unread > 0 ? 'Thông báo, $_unread chưa đọc' : 'Thông báo',
                onPressed: () => NotificationsBottomSheet.show(
                  context,
                  onNotificationsUpdated: _loadUnread,
                ).then((_) => _loadUnread()),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: PbmsTokens.ink,
                  side: const BorderSide(color: PbmsTokens.border),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 21),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Mở trang cá nhân',
              child: GestureDetector(
                onTap: () => ShellScope.maybeOf(context)?.goTab(AppTab.profile),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: PbmsTokens.tealTint,
                  child: Text(initial,
                      style: const TextStyle(
                          color: PbmsTokens.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Băng quảng cáo đầu trang: mỗi ảnh giới thiệu một tính năng và mở thẳng tới đó.
  Widget _buildPromos(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    return PromoCarousel(items: [
      PromoItem(
        image: 'assets/images/promo/reserve.jpg',
        title: 'Giữ chỗ ô tô trước tới 5 giờ',
        subtitle: 'Chọn bãi trên bản đồ, cọc trừ vào phí khi ra',
        action: 'Đặt chỗ',
        onTap: () => widget.onOpenMap(null),
      ),
      PromoItem(
        image: 'assets/images/promo/monthly.jpg',
        title: 'Vé tháng 3, 6, 9, 12 tháng',
        subtitle: 'Ký hợp đồng điện tử ngay trên app',
        action: 'Xem gói',
        onTap: () => shell?.goTab(AppTab.pass),
      ),
      PromoItem(
        image: 'assets/images/promo/wallet.jpg',
        title: 'Nạp ví PBMS, ra bãi không chờ',
        subtitle: 'Nạp qua ngân hàng, thẻ; trả phí một chạm',
        action: 'Nạp ví',
        onTap: () => WalletScreen.open(context),
      ),
      PromoItem(
        image: 'assets/images/promo/prepay.jpg',
        title: 'Trả phí trước, quét mã ra cổng',
        subtitle: 'Mã ra cổng dùng tới khi xe rời bãi',
        action: 'Lượt gửi',
        onTap: () => shell?.goTab(AppTab.history),
      ),
    ]);
  }

  Widget _buildNearbyButton(List<LotView> lots) {
    final available = lots.fold<int>(0, (s, l) => s + l.available);
    final single = lots.length == 1 ? lots.first : null;
    final detail = single == null
        ? '${lots.where((l) => l.available > 0).length}/${lots.length} bãi còn chỗ, xem trên bản đồ'
        : (single.capacities.isEmpty
            ? 'Chưa có dữ liệu ô đỗ'
            : single.capacities
                .map((c) => '${c.vehicleTypeName} ${c.available}')
                .join(', '));

    return Material(
      color: PbmsTokens.teal,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => widget.onOpenMap(null),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.local_parking_rounded,
                  size: 20, color: Colors.white),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        single == null
                            ? '${lots.length} bãi còn $available chỗ trống'
                            : '${single.name} còn $available chỗ trống',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE4F7F8))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivity(_Activity activity) {
    final session = activity.session;
    if (session != null) {
      return _buildActiveSession(session, activity.sessionPricing);
    }
    final reservation = activity.reservation;
    if (reservation != null) return _buildUpcomingReservation(reservation);
    return PbmsEmptyView(
      icon: Icons.directions_car_outlined,
      title: 'Chưa có xe trong bãi',
      message:
          'Giữ chỗ ô tô trước tối đa 5 giờ, tiền cọc trừ vào phí khi ra bãi.',
      action: TextButton.icon(
        onPressed: () => widget.onOpenMap(null),
        style: TextButton.styleFrom(
            foregroundColor: PbmsTokens.teal, minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.event_available_rounded, size: 18),
        label: const Text('Đặt chỗ trước'),
      ),
    );
  }

  Widget _activityHeader(String title, Widget trailing) {
    return Row(
      children: [
        Semantics(
          label: 'Đang hoạt động',
          child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: PbmsTokens.teal, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PbmsTokens.teal)),
        ),
        trailing,
      ],
    );
  }

  Widget _slotChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: PbmsTokens.tealTint, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PbmsTokens.teal)),
    );
  }

  Widget _qrButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.qr_code_2_rounded, size: 19),
        label: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: PbmsTokens.teal,
          backgroundColor: PbmsTokens.tealTint,
          side: const BorderSide(color: PbmsTokens.tealLine),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildActiveSession(
      ParkingSessionModel s, PricingPolicyModel? pricing) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => SessionDetailSheet.show(context, s),
      child: PbmsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _activityHeader(
                'Xe đang trong bãi', _slotChip(s.slotCode ?? 'Chưa phân ô')),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.licensePlateIn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PbmsText.title),
                      const SizedBox(height: 4),
                      Text(
                        'Vào lúc ${DateFormatter.formatDayTime(s.entryTime)}'
                        '${s.vehicleTypeName == null ? '' : ', ${s.vehicleTypeName}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormatter.clock(s.parkedDuration),
                        style: PbmsText.figure(17, color: PbmsTokens.teal)),
                    const SizedBox(height: 3),
                    if (pricing != null)
                      Text(
                          '${CurrencyFormatter.format(pricing.extraHourPrice)}/giờ',
                          style: PbmsText.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (s.exitPass != null)
              _qrButton(
                'Mã ra cổng ${s.exitPass!.code}',
                () => PbmsQrDialog.show(
                  context,
                  title: 'Mã ra cổng',
                  payload: s.exitPass!.qrPayload,
                  headline: s.licensePlateIn,
                  rows: [
                    (Icons.password_rounded, 'Mã', s.exitPass!.code),
                    (
                      Icons.local_parking_rounded,
                      'Vị trí đỗ',
                      s.slotCode ?? 'Chưa phân ô'
                    ),
                    (
                      Icons.timer_outlined,
                      'Hiệu lực',
                      'Tới khi xe ra khỏi bãi'
                    ),
                  ],
                ),
              )
            else
              PbmsPrimaryButton(
                label: 'Thanh toán để lấy xe',
                icon: Icons.payments_outlined,
                onPressed: () => SessionDetailSheet.show(context, s)
                    .then((_) => reloadAll()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReservation(ReservationModel r) {
    final ticket = r.ticket;
    final info = StatusInfo.reservation(r.status);
    return PbmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _activityHeader('Đặt chỗ sắp tới', PbmsStatusPill(info)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormatter.formatTime(r.expectedEntryTime),
                  style: PbmsText.figure(24)),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${DateFormatter.formatDay(r.expectedEntryTime)}, ${r.vehicleTypeName}',
                    style: PbmsText.caption,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (r.isPending)
            PbmsPrimaryButton(
              label: 'Đặt cọc để giữ chỗ',
              icon: Icons.payments_outlined,
              onPressed: () => ReservationActions.payDeposit(
                  context, r, () => ShellScope.dataChanged(context)),
            )
          else
            _qrButton(
              ticket == null
                  ? 'Mã QR sẽ có sau khi xác nhận'
                  : 'Mã QR vào cổng',
              ticket == null
                  ? null
                  : () => PbmsQrDialog.show(
                        context,
                        title: 'Mã QR vào cổng',
                        payload: ticket.qrPayload,
                        headline: r.vehicleTypeName,
                        rows: [
                          (
                            Icons.location_on_outlined,
                            'Địa điểm',
                            PbmsFacility.name
                          ),
                          (
                            Icons.schedule_rounded,
                            'Giờ vào dự kiến',
                            DateFormatter.formatDayTime(r.expectedEntryTime)
                          ),
                        ],
                      ),
            ),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final VehicleTypeCapacity capacity;
  final VoidCallback onOpenMap;

  const _CapacityCard({required this.capacity, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final c = capacity;
    final pricing = c.pricing;
    final hasRoom = c.available > 0;
    final stateColor = hasRoom ? PbmsTokens.teal : PbmsTokens.danger;

    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: PbmsTokens.tealTint,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    c.isCar
                        ? Icons.directions_car_rounded
                        : Icons.two_wheeler_rounded,
                    size: 26,
                    color: PbmsTokens.teal),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(c.vehicleTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PbmsText.bodyStrong)),
                        const SizedBox(width: 5),
                        if (pricing != null)
                          Text(
                              '${CurrencyFormatter.format(pricing.basePrice)}/${pricing.baseHours}h đầu',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PbmsTokens.teal)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pricing == null
                          ? 'Chưa có bảng giá'
                          : 'Sau đó ${CurrencyFormatter.format(pricing.extraHourPrice)}/giờ'
                              '${pricing.nightSurcharge > 0 ? ', phụ thu đêm ${CurrencyFormatter.format(pricing.nightSurcharge)}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PbmsText.caption,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            hasRoom ? '${c.available} chỗ trống' : 'Đã hết chỗ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: stateColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ])),
                        const Spacer(),
                        Text('Đã lấp ${c.occupiedPercent}% / ${c.total} chỗ',
                            style: PbmsText.caption),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.total == 0 ? 0 : c.occupiedPercent / 100,
                        minHeight: 4,
                        color: stateColor,
                        backgroundColor: PbmsTokens.divider,
                        semanticsLabel: 'Tỉ lệ lấp đầy ${c.vehicleTypeName}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Divider(height: 1, color: PbmsTokens.border)),
          Row(
            children: [
              if (c.isCar)
                TextButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.event_available_rounded, size: 17),
                  label: const Text('Đặt chỗ trước'),
                  style: TextButton.styleFrom(
                      foregroundColor: PbmsTokens.teal,
                      minimumSize: const Size(48, 44)),
                )
              else
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('Không cần đặt trước, vào bãi trực tiếp',
                        maxLines: 2, style: PbmsText.caption),
                  ),
                ),
              if (c.isCar) const Spacer(),
              TextButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: const Text('Bản đồ'),
                style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.muted,
                    minimumSize: const Size(48, 44)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ gợi ý một bãi (thiết kế "Gợi ý bãi gần nhất" của main).
class _LotCard extends StatelessWidget {
  final LotView lot;
  final double? distance;
  final ValueChanged<String?> onOpenMap;

  const _LotCard({required this.lot, required this.onOpenMap, this.distance});

  @override
  Widget build(BuildContext context) {
    final car = lot.car;
    final hasRoom = lot.available > 0;
    final stateColor = hasRoom ? PbmsTokens.teal : PbmsTokens.danger;
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: PbmsTokens.tealTint,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_parking_rounded,
                    size: 26, color: PbmsTokens.teal),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(lot.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PbmsText.bodyStrong)),
                        if (car?.pricing != null)
                          Text(
                              '${CurrencyFormatter.format(car!.pricing!.basePrice)}/${car.pricing!.baseHours}h',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PbmsTokens.teal)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        [
                          if (distance != null)
                            'Cách bạn ${LocationService.formatDistance(distance!)}',
                          if (lot.visits > 0) 'Bạn đã gửi ${lot.visits} lần',
                          if (distance == null && lot.visits == 0)
                            lot.area ??
                                (lot.point == null
                                    ? 'Chưa có vị trí trên bản đồ'
                                    : ''),
                        ].join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.caption),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            hasRoom
                                ? '${lot.available} chỗ trống'
                                : 'Đã hết chỗ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: stateColor)),
                        const Spacer(),
                        Text('Đã lấp ${lot.occupiedPercent}%',
                            style: PbmsText.caption),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lot.total == 0 ? 0 : lot.occupiedPercent / 100,
                        minHeight: 4,
                        color: stateColor,
                        backgroundColor: PbmsTokens.divider,
                        semanticsLabel: 'Tỉ lệ lấp đầy ${lot.name}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Divider(height: 1, color: PbmsTokens.border)),
          Row(
            children: [
              if (car != null)
                TextButton.icon(
                  onPressed: () => onOpenMap(lot.id),
                  icon: const Icon(Icons.event_available_rounded, size: 17),
                  label: const Text('Đặt chỗ trước'),
                  style: TextButton.styleFrom(
                      foregroundColor: PbmsTokens.teal,
                      minimumSize: const Size(48, 44)),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onOpenMap(lot.id),
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: const Text('Bản đồ'),
                style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.muted,
                    minimumSize: const Size(48, 44)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

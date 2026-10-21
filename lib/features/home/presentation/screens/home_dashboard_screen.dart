import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:prm393_frontend/core/services/location_service.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_state.dart';
import 'package:prm393_frontend/features/entry_pass/entry_pass_screen.dart';
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

  /// Phí tạm tính của lượt gửi đang diễn ra, làm mới cùng đồng hồ.
  FeePreviewModel? _fee;

  /// Vị trí thực tế của khách để gợi ý bãi gần nhất.
  LocationResult? _loc;
  bool _locating = false;
  final _subs = <StreamSubscription<Object?>>[];

  ParkingSessionModel? get _activeSession => _activity.state.data?.session;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _locate();
    // Bảng chỗ trống và dòng "Gần bãi X" cần danh sách bãi; carousel ẩn khi có xe trong bãi.
    _subs
      ..add(_lots.stream.listen((_) {
        if (mounted) setState(() {});
      }))
      ..add(_activity.stream.listen((_) {
        if (mounted) setState(() {});
        _refreshFee();
      }));
    // Đồng hồ thời gian đỗ và phí tạm tính cập nhật mỗi phút.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _refreshFee();
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
    for (final s in _subs) {
      s.cancel();
    }
    _lots.close();
    _activity.close();
    super.dispose();
  }

  Future<_Activity> _loadActivity() async {
    final results = await Future.wait([
      _repo.getMySessions(),
      _repo.getMyReservations(),
    ]);
    final sessions = results[0] as List<ParkingSessionModel>;
    final reservations = results[1] as List<ReservationModel>;
    final upcoming = reservations.where((r) => r.canModify).toList()
      ..sort((a, b) => a.expectedEntryTime.compareTo(b.expectedEntryTime));
    return (
      session: sessions.where((s) => s.isActive).firstOrNull,
      reservation: upcoming.firstOrNull,
    );
  }

  Future<void> _refreshFee() async {
    final session = _activeSession;
    if (session == null || session.isPrepaid) {
      if (_fee != null && mounted) setState(() => _fee = null);
      return;
    }
    try {
      final fee = await _repo.getFeePreview(session.sessionId);
      if (mounted && _activeSession?.sessionId == session.sessionId) {
        setState(() => _fee = fee);
      }
    } catch (_) {
      // Phí tạm tính không chặn vé; giữ số cũ.
    }
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
    if (_locating) return 'Đang lấy vị trí...';
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
    final parked = _activeSession != null;

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
              const SizedBox(height: 20),
              // Xe đang trong bãi / đặt chỗ sắp tới luôn đứng đầu: đây là việc ở cổng.
              PbmsAsync<_Activity>(
                cubit: _activity,
                loadingHeight: 220,
                errorTitle: 'Không tải được lượt gửi xe',
                builder: _buildActivity,
              ),
              const SizedBox(height: 20),
              PbmsAsync<List<LotView>>(
                cubit: _lots,
                loadingHeight: 120,
                errorTitle: 'Không tải được chỗ trống',
                builder: _buildLedBoard,
              ),
              if (!parked) ...[
                const SizedBox(height: 20),
                _buildPromos(context),
              ],
              const SizedBox(height: 24),
              PbmsAsync<List<LotView>>(
                cubit: _lots,
                loadingHeight: 180,
                errorTitle: 'Không tải được chỗ trống',
                isEmpty: (d) => d.every((l) => l.total == 0),
                empty: const PbmsEmptyView(
                  icon: Icons.local_parking_rounded,
                  title: 'Bãi chưa mở ô đỗ nào',
                ),
                builder: (lots) => lots.length > 1
                    ? _buildLotSuggestions(lots)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const PbmsSectionTitle('Giá theo loại xe'),
                          for (final c in lots.first.capacities) ...[
                            _CapacityRow(
                                capacity: c,
                                onTap: () => widget.onOpenMap(lots.first.id)),
                            const SizedBox(height: 10),
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

    Widget row(LotView l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LotRow(
            lot: l,
            distance: l.distanceFrom(pos),
            onTap: () => widget.onOpenMap(l.id),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nearby.isNotEmpty) ...[
          const PbmsSectionTitle('Bãi gần bạn'),
          ...nearby.take(3).map(row),
          const SizedBox(height: 14),
        ],
        if (frequent.isNotEmpty) ...[
          const PbmsSectionTitle('Bãi thường dùng'),
          ...frequent.take(3).map(row),
          const SizedBox(height: 14),
        ],
        if (others.isNotEmpty) ...[
          PbmsSectionTitle(shown.isEmpty ? 'Các bãi' : 'Các bãi khác'),
          ...others.map(row),
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
                  Text(
                    '$_greeting, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PbmsText.title,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _onLocationTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              _loc?.ok == true
                                  ? Icons.near_me_rounded
                                  : Icons.location_disabled_outlined,
                              size: 16,
                              color: PbmsTokens.teal),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(_locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PbmsText.caption),
                          ),
                        ],
                      ),
                    ),
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
                  // Có ảnh đại diện thì hiện ảnh, lỗi tải thì vẫn còn chữ cái đầu bên dưới.
                  foregroundImage: resolveMediaUrl(user?.avatarUrl) == null
                      ? null
                      : CachedNetworkImageProvider(resolveMediaUrl(user?.avatarUrl)!),
                  // Chỉ gắn khi có ảnh: CircleAvatar khẳng định điều này ở bản debug.
                  onForegroundImageError: resolveMediaUrl(user?.avatarUrl) == null ? null : (_, __) {},
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

  /// Băng giới thiệu tính năng; chỉ đổi ảnh khi khách vuốt.
  Widget _buildPromos(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    return PromoCarousel(items: [
      PromoItem(
        image: 'assets/images/promo/prepay.jpg',
        title: 'Trả phí trước, quét mã ra cổng',
        subtitle: 'Mã dùng tới khi xe rời bãi',
        action: 'Lượt gửi',
        onTap: () => shell?.goTab(AppTab.history),
      ),
      PromoItem(
        image: 'assets/images/promo/monthly.jpg',
        title: 'Vé tháng 3, 6, 9, 12 tháng',
        subtitle: 'Ký hợp đồng điện tử trên app',
        action: 'Xem gói',
        onTap: () => shell?.goTab(AppTab.pass),
      ),
      PromoItem(
        image: 'assets/images/promo/wallet.jpg',
        title: 'Nạp ví PBMS, ra bãi không chờ',
        subtitle: 'Nạp qua ngân hàng hoặc thẻ',
        action: 'Nạp ví',
        onTap: () => WalletScreen.open(context),
      ),
      PromoItem(
        image: 'assets/images/promo/reserve.jpg',
        title: 'Giữ chỗ ô tô trước tới 5 giờ',
        subtitle: 'Cọc trừ vào phí khi ra',
        action: 'Đặt chỗ',
        onTap: () => widget.onOpenMap(null),
      ),
    ]);
  }

  /// Bảng LED chỗ trống, cộng dồn theo loại xe trên mọi bãi.
  Widget _buildLedBoard(List<LotView> lots) {
    final caps = lots.expand((l) => l.capacities);
    int sum(bool car) =>
        caps.where((c) => c.isCar == car).fold(0, (s, c) => s + c.available);
    final hasMoto = caps.any((c) => !c.isCar);
    final hasCar = caps.any((c) => c.isCar);
    if (!hasMoto && !hasCar) return const SizedBox.shrink();
    return PbmsLedCounter(
      caption: lots.length == 1
          ? lots.first.name
          : '${lots.where((l) => l.available > 0).length}/${lots.length} bãi còn chỗ',
      entries: [
        if (hasMoto) (label: 'Xe máy', available: sum(false)),
        if (hasCar) (label: 'Ô tô', available: sum(true)),
      ],
      onTap: () => widget.onOpenMap(lots.length == 1 ? lots.first.id : null),
    );
  }

  Widget _buildActivity(_Activity activity) {
    final session = activity.session;
    if (session != null) return _buildActiveSession(session);
    final reservation = activity.reservation;
    if (reservation != null) return _buildUpcomingReservation(reservation);
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.qr_code_2_rounded,
            label: 'Mã QR gửi xe',
            onTap: () => EntryPassScreen.open(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.event_available_rounded,
            label: 'Đặt chỗ ô tô',
            onTap: () => widget.onOpenMap(null),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSession(ParkingSessionModel s) {
    final pass = s.exitPass;
    final fee = _fee;
    return PbmsTicketStub(
      onTap: () => SessionDetailSheet.show(context, s).then((_) => reloadAll()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PbmsPlate(
                  licensePlate: s.licensePlateIn,
                  isMotorbike: s.isMotorbike,
                  fontSize: 20),
              const Spacer(),
              if (s.slotCode != null) PbmsSlotTag(s.slotCode!),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Đã đỗ', style: PbmsText.label),
          Text(DateFormatter.clock(s.parkedDuration),
              style: PbmsText.display(44)),
          const SizedBox(height: 4),
          Text('Vào lúc ${DateFormatter.formatDayTime(s.entryTime)}',
              style: PbmsText.caption),
        ],
      ),
      stub: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pass != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Align(alignment: Alignment.centerLeft, child: PbmsPaidStamp()),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: Text('Phí tạm tính', style: PbmsText.body)),
                  Text(
                    fee == null
                        ? '...'
                        : fee.isCoveredBySubscription
                            ? 'Trong vé tháng'
                            : CurrencyFormatter.format(fee.amount),
                    style: PbmsText.figure(22, color: PbmsTokens.ink)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          PbmsPrimaryButton(
            label: pass != null ? 'Mã ra cổng' : 'Trả phí, lấy mã ra cổng',
            icon: Icons.qr_code_2_rounded,
            onPressed: pass != null
                ? () => PbmsQrDialog.show(
                      context,
                      title: 'Mã ra cổng',
                      payload: pass.qrPayload,
                      plate: s.licensePlateIn,
                      isMotorbike: s.isMotorbike,
                      code: pass.code,
                      rows: [
                        if (s.slotCode != null)
                          (Icons.local_parking_rounded, 'Vị trí đỗ', s.slotCode!),
                      ],
                    )
                : () => SessionDetailSheet.show(context, s)
                    .then((_) => reloadAll()),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingReservation(ReservationModel r) {
    final ticket = r.ticket;
    final plate = r.licensePlate;
    return PbmsTicketStub(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Đặt chỗ sắp tới', style: PbmsText.label)),
              PbmsStatusPill(StatusInfo.reservation(r.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(DateFormatter.formatTime(r.expectedEntryTime),
              style: PbmsText.display(44)),
          const SizedBox(height: 4),
          Text(
              '${DateFormatter.formatDay(r.expectedEntryTime)}, ${PbmsFacility.name}',
              style: PbmsText.caption),
          if (plate != null) ...[
            const SizedBox(height: 14),
            PbmsPlate(licensePlate: plate, isMotorbike: false, fontSize: 18),
          ],
        ],
      ),
      stub: r.isPending
          ? PbmsPrimaryButton(
              label: 'Đặt cọc để giữ chỗ',
              icon: Icons.payments_outlined,
              onPressed: () => ReservationActions.payDeposit(
                  context, r, () => ShellScope.dataChanged(context)),
            )
          : PbmsPrimaryButton(
              label: ticket == null ? 'Mã QR có sau khi xác nhận' : 'Mã QR vào cổng',
              icon: Icons.qr_code_2_rounded,
              onPressed: ticket == null
                  ? null
                  : () => PbmsQrDialog.show(
                        context,
                        title: 'Mã QR vào cổng',
                        payload: ticket.qrPayload,
                        plate: plate,
                        headline: r.vehicleTypeName,
                        rows: [
                          (
                            Icons.schedule_rounded,
                            'Giờ vào dự kiến',
                            DateFormatter.formatDayTime(r.expectedEntryTime)
                          ),
                        ],
                      ),
            ),
    );
  }
}

/// Lối tắt khi chưa có xe trong bãi.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: PbmsTokens.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: PbmsTokens.teal),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: PbmsText.bodyStrong)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một bãi: tên, khoảng cách, số chỗ trống lớn bên phải. Chạm để mở trên bản đồ.
class _LotRow extends StatelessWidget {
  final LotView lot;
  final double? distance;
  final VoidCallback onTap;

  const _LotRow({required this.lot, required this.onTap, this.distance});

  @override
  Widget build(BuildContext context) {
    final hasRoom = lot.available > 0;
    final car = lot.car;
    final detail = [
      if (distance != null) LocationService.formatDistance(distance!),
      if (lot.visits > 0) 'đã gửi ${lot.visits} lần',
      if (car?.pricing != null)
        'ô tô ${CurrencyFormatter.format(car!.pricing!.basePrice)}/${car.pricing!.baseHours}h',
      if (distance == null && lot.visits == 0 && lot.area != null) lot.area!,
    ].join(', ');
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: PbmsTokens.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.bodyStrong),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PbmsText.caption),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hasRoom ? '${lot.available}' : 'Hết',
                      style: PbmsText.figure(24,
                              color: hasRoom ? PbmsTokens.ink : PbmsTokens.danger)
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text(hasRoom ? 'chỗ trống' : 'chỗ', style: PbmsText.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một loại xe ở bãi duy nhất: giá và số chỗ trống.
class _CapacityRow extends StatelessWidget {
  final VehicleTypeCapacity capacity;
  final VoidCallback onTap;

  const _CapacityRow({required this.capacity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = capacity;
    final pricing = c.pricing;
    final hasRoom = c.available > 0;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: PbmsTokens.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(c.isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                  size: 22, color: PbmsTokens.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.vehicleTypeName, style: PbmsText.bodyStrong),
                    const SizedBox(height: 3),
                    Text(
                      pricing == null
                          ? 'Chưa có bảng giá'
                          : '${CurrencyFormatter.format(pricing.basePrice)}/${pricing.baseHours}h đầu, '
                              'sau đó ${CurrencyFormatter.format(pricing.extraHourPrice)}/giờ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PbmsText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(hasRoom ? '${c.available}' : 'Hết',
                  style: PbmsText.figure(24,
                          color: hasRoom ? PbmsTokens.ink : PbmsTokens.danger)
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

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

  /// Danh sách bãi đang mở rộng (mặc định chỉ hiện một bãi).
  bool _showAllLots = false;
  final _subs = <StreamSubscription<Object?>>[];

  ParkingSessionModel? get _activeSession => _activity.state.data?.session;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _locate();
    // Dòng "Gần bãi X" cần danh sách bãi; phí tạm tính cần biết xe nào đang trong bãi.
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
              _buildPromos(context),
              const SizedBox(height: 20),
              PbmsAsync<_Activity>(
                cubit: _activity,
                loadingHeight: 220,
                errorTitle: 'Không tải được lượt gửi xe',
                builder: _buildActivity,
              ),
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

  /// Nhiều bãi: chỉ hiện một bãi phù hợp nhất (gần nhất theo GPS, rồi bãi thường dùng,
  /// rồi bãi còn nhiều chỗ); các bãi còn lại hiện khi nhấn "Xem thêm".
  Widget _buildLotSuggestions(List<LotView> lots) {
    final pos = _loc?.position;
    final nearby = lots.where((l) => l.distanceFrom(pos) != null).toList()
      ..sort((a, b) => a.distanceFrom(pos)!.compareTo(b.distanceFrom(pos)!));
    final frequent = lots.where((l) => l.visits > 0).toList()
      ..sort((a, b) => b.visits.compareTo(a.visits));
    final rest = lots.toList()..sort((a, b) => b.available.compareTo(a.available));
    final ordered = <LotView>[];
    for (final l in [...nearby, ...frequent, ...rest]) {
      if (!ordered.any((o) => o.id == l.id)) ordered.add(l);
    }
    final title = nearby.isNotEmpty
        ? 'Bãi gần bạn'
        : (frequent.isNotEmpty ? 'Bãi bạn hay gửi' : 'Bãi gợi ý');
    final more = ordered.length - 1;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget card(LotView l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LotCard(
            lot: l,
            distance: l.distanceFrom(pos),
            onTap: () => widget.onOpenMap(l.id),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nút "Xem thêm" nằm cùng dòng tiêu đề, phía đối diện.
        PbmsSectionTitle(
          title,
          trailing: more > 0
              ? TextButton.icon(
                  onPressed: () => setState(() => _showAllLots = !_showAllLots),
                  iconAlignment: IconAlignment.end,
                  icon: AnimatedRotation(
                    turns: _showAllLots ? 0.5 : 0,
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, size: 20),
                  ),
                  label: Text(_showAllLots ? 'Thu gọn' : 'Xem thêm $more bãi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.teal,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.only(left: 8),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                )
              : null,
        ),
        card(ordered.first),
        AnimatedSize(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _showAllLots
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: ordered.skip(1).map(card).toList(),
                )
              : const SizedBox(width: double.infinity),
        ),
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

/// Thẻ bãi: ảnh bãi phủ kín, tối dần từ trên xuống, phủ teal 40%.
/// Trên trái: loại xe nhận và giá. Trên phải: số chỗ trống. Dưới phải: khoảng cách và tên bãi.
class _LotCard extends StatelessWidget {
  final LotView lot;
  final double? distance;
  final VoidCallback onTap;

  const _LotCard({required this.lot, required this.onTap, this.distance});

  /// Ảnh dự phòng khi bãi chưa có ảnh trên máy chủ: gán cố định theo mã bãi.
  static const _photos = [
    'assets/images/promo/reserve.jpg',
    'assets/images/promo/prepay.jpg',
    'assets/images/promo/monthly.jpg',
    'assets/images/promo/wallet.jpg',
  ];

  static String photoFor(String lotId) =>
      _photos[lotId.codeUnits.fold<int>(0, (s, c) => s + c) % _photos.length];

  /// "30k/2h", "20k/giờ": giá lượt đầu rẻ nhất của bãi.
  static String? priceLabel(LotView lot) {
    final prices = lot.capacities.map((c) => c.pricing).whereType<PricingPolicyModel>().toList()
      ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    if (prices.isEmpty) return null;
    final p = prices.first;
    final amount = p.basePrice >= 1000
        ? '${(p.basePrice / 1000).toStringAsFixed(p.basePrice % 1000 == 0 ? 0 : 1)}k'
        : CurrencyFormatter.format(p.basePrice);
    return p.baseHours <= 1 ? '$amount/giờ' : '$amount/${p.baseHours}h';
  }

  /// Khoảng cách và thời gian lái xe ước tính trong nội thành (~25 km/h).
  static String driveLabel(double meters) {
    final minutes = (meters / 1000 / 25 * 60).ceil().clamp(1, 999);
    return '${LocationService.formatDistance(meters)} · $minutes phút lái xe';
  }

  @override
  Widget build(BuildContext context) {
    final hasRoom = lot.available > 0;
    final hasCar = lot.capacities.any((c) => c.isCar);
    final hasMoto = lot.capacities.any((c) => !c.isCar);
    final price = priceLabel(lot);
    final where = distance != null ? driveLabel(distance!) : lot.area;

    return Semantics(
      button: true,
      label: '${lot.name}, ${hasRoom ? '${lot.available} chỗ trống' : 'hết chỗ'}'
          '${where == null ? '' : ', $where'}',
      excludeSemantics: true,
      child: Material(
        color: PbmsTokens.teal,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _LotPhoto(url: resolveMediaUrl(lot.imageUrl), fallback: photoFor(lot.id)),
                // Tối dần từ trên xuống để chữ trắng phía dưới đủ tương phản.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A000000), Color(0x8C000000)],
                    ),
                  ),
                ),
                // Lớp teal 40% của theme: vẫn nhìn thấy ảnh bên dưới.
                ColoredBox(color: PbmsTokens.teal.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Một dòng, không xuống hàng: thẻ cao cố định 100.
                          Expanded(
                            child: Row(
                              children: [
                                if (lot.openingHours != null)
                                  _GlassPill(icons: const [Icons.schedule_rounded], label: lot.openingHours)
                                else if (hasMoto || hasCar)
                                  _GlassPill(
                                    icons: [
                                      if (hasMoto) Icons.two_wheeler_rounded,
                                      if (hasCar) Icons.directions_car_rounded,
                                    ],
                                    // Nhận cả hai loại xe: chỉ hai biểu tượng cho gọn.
                                    label: hasMoto && hasCar ? null : (hasCar ? 'Ô tô' : 'Xe máy'),
                                  ),
                                if (price != null) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _GlassPill(
                                      icons: const [Icons.account_balance_wallet_outlined],
                                      label: price,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AvailabilityPill(
                            label: hasRoom ? '${lot.available} chỗ trống' : 'Hết chỗ',
                            full: !hasRoom,
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (where != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.place_outlined, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(where,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xF2FFFFFF))),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(lot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 17, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
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

/// Ảnh bãi từ máy chủ; chưa có hoặc tải lỗi thì dùng ảnh bãi đỗ có sẵn trong app.
class _LotPhoto extends StatelessWidget {
  final String? url;
  final String fallback;

  const _LotPhoto({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(fallback, fit: BoxFit.cover, excludeFromSemantics: true);
    final src = url;
    if (src == null) return asset;
    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      placeholder: (_, __) => asset,
      errorWidget: (_, __, ___) => asset,
    );
  }
}

/// Nhãn nhỏ trên ảnh: nền trắng trong suốt nhẹ, viền trắng mảnh.
class _GlassPill extends StatelessWidget {
  final List<IconData> icons;
  final String? label;

  const _GlassPill({required this.icons, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x29FFFFFF),
        border: Border.all(color: const Color(0x99FFFFFF), width: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < icons.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Icon(icons[i], size: 14, color: Colors.white),
          ],
          if (label != null) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Nhãn chỗ trống theo màu trạng thái của theme: xanh lục khi còn chỗ, đỏ khi hết.
class _AvailabilityPill extends StatelessWidget {
  final String label;
  final bool full;

  const _AvailabilityPill({required this.label, required this.full});

  @override
  Widget build(BuildContext context) {
    final fg = full ? PbmsTokens.danger : PbmsTokens.ok;
    final bg = full ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
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

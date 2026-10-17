import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:prm393_frontend/features/incidents/presentation/screens/incidents_screen.dart';
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
  final VoidCallback onOpenMap;

  const HomeDashboardScreen({super.key, required this.onOpenMap});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _capacity = AsyncCubit<List<VehicleTypeCapacity>>(_loadCapacity);
  late final _activity = AsyncCubit<_Activity>(_loadActivity);
  int _unread = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    // Đồng hồ thời gian đỗ cập nhật mỗi phút.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void reloadAll() {
    _capacity.load();
    _activity.load();
    _loadUnread();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _capacity.close();
    _activity.close();
    super.dispose();
  }

  Future<List<VehicleTypeCapacity>> _loadCapacity() async {
    final results = await Future.wait([
      _repo.getAvailability(),
      _repo.getPricingPolicies(),
    ]);
    return VehicleTypeCapacity.summarize(
      results[0] as List<FacilityAvailabilityModel>,
      results[1] as List<PricingPolicyModel>,
    );
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

  Future<void> _loadUnread() async {
    try {
      final page = await _repo.getNotifications();
      if (mounted) setState(() => _unread = page.unreadCount);
    } catch (_) {
      // Huy hiệu chưa đọc không chặn trang chủ.
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
              _buildSearchEntry(),
              const SizedBox(height: 10),
              PbmsAsync<List<VehicleTypeCapacity>>(
                cubit: _capacity,
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
              _buildQuickAccess(context),
              const SizedBox(height: 22),
              const PbmsSectionTitle('Chỗ trống theo loại xe'),
              PbmsAsync<List<VehicleTypeCapacity>>(
                cubit: _capacity,
                loadingHeight: 150,
                errorTitle: 'Không tải được chỗ trống',
                isEmpty: (d) => d.isEmpty,
                empty: const PbmsEmptyView(
                  icon: Icons.local_parking_rounded,
                  title: 'Bãi chưa mở ô đỗ nào',
                  message: 'Khi bãi cấu hình tầng và ô đỗ, chỗ trống sẽ hiện ở đây.',
                ),
                builder: (items) => Column(
                  children: [
                    for (final c in items) ...[
                      _CapacityCard(capacity: c, onOpenMap: widget.onOpenMap),
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
                    onTap: widget.onOpenMap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 16, color: PbmsTokens.teal),
                          SizedBox(width: 5),
                          Text(PbmsFacility.area, style: PbmsText.caption),
                          Icon(Icons.expand_more_rounded,
                              size: 17, color: PbmsTokens.muted),
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
                tooltip: _unread > 0
                    ? 'Thông báo, $_unread chưa đọc'
                    : 'Thông báo',
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

  Widget _buildSearchEntry() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onOpenMap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: PbmsTokens.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: PbmsTokens.tealTint,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.map_outlined,
                    color: PbmsTokens.teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bạn muốn đỗ xe khi nào?', style: PbmsText.bodyStrong),
                    SizedBox(height: 3),
                    Text('Xem bãi trên bản đồ và giữ chỗ ô tô trước',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PbmsText.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: PbmsTokens.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyButton(List<VehicleTypeCapacity> items) {
    final available = items.fold<int>(0, (s, c) => s + c.available);
    final detail = items.isEmpty
        ? 'Chưa có dữ liệu ô đỗ'
        : items.map((c) => '${c.vehicleTypeName} ${c.available}').join(', ');

    return Material(
      color: PbmsTokens.teal,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: widget.onOpenMap,
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
                    Text('${PbmsFacility.name} còn $available chỗ trống',
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
    if (session != null) return _buildActiveSession(session, activity.sessionPricing);
    final reservation = activity.reservation;
    if (reservation != null) return _buildUpcomingReservation(reservation);
    return PbmsEmptyView(
      icon: Icons.directions_car_outlined,
      title: 'Chưa có xe trong bãi',
      message: 'Giữ chỗ ô tô trước tối đa 5 giờ, tiền cọc trừ vào phí khi ra bãi.',
      action: TextButton.icon(
        onPressed: widget.onOpenMap,
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
            _activityHeader('Xe đang trong bãi',
                _slotChip(s.slotCode ?? 'Chưa phân ô')),
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
                    (Icons.local_parking_rounded, 'Vị trí đỗ',
                        s.slotCode ?? 'Chưa phân ô'),
                    (Icons.timer_outlined, 'Hiệu lực', 'Tới khi xe ra khỏi bãi'),
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
              ticket == null ? 'Mã QR sẽ có sau khi xác nhận' : 'Mã QR vào cổng',
              ticket == null
                  ? null
                  : () => PbmsQrDialog.show(
                        context,
                        title: 'Mã QR vào cổng',
                        payload: ticket.qrPayload,
                        headline: r.vehicleTypeName,
                        rows: [
                          (Icons.location_on_outlined, 'Địa điểm', PbmsFacility.name),
                          (Icons.schedule_rounded, 'Giờ vào dự kiến',
                              DateFormatter.formatDayTime(r.expectedEntryTime)),
                        ],
                      ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final shortcuts = [
      (
        icon: Icons.history_rounded,
        name: 'Lịch sử',
        context: 'Lượt gửi, đặt chỗ',
        onTap: () => ShellScope.maybeOf(context)?.goTab(AppTab.history),
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        name: 'Ví PBMS',
        context: 'Nạp tiền, trả phí',
        onTap: () => WalletScreen.open(context),
      ),
      (
        icon: Icons.card_membership_rounded,
        name: 'Vé tháng',
        context: 'Đăng ký, gia hạn',
        onTap: () => ShellScope.maybeOf(context)?.goTab(AppTab.pass),
      ),
      (
        icon: Icons.report_gmailerrorred_rounded,
        name: 'Báo sự cố',
        context: 'Gửi cho nhân viên',
        onTap: () => IncidentsScreen.open(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PbmsSectionTitle('Truy cập nhanh'),
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = shortcuts[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: item.onTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: PbmsTokens.border),
                        borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: PbmsTokens.tealTint,
                              borderRadius: BorderRadius.circular(9)),
                          child:
                              Icon(item.icon, size: 18, color: PbmsTokens.teal),
                        ),
                        const SizedBox(width: 9),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PbmsTokens.ink)),
                            const SizedBox(height: 2),
                            Text(item.context, style: PbmsText.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
                            hasRoom
                                ? '${c.available} chỗ trống'
                                : 'Đã hết chỗ',
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Không cần đặt trước, vào bãi trực tiếp',
                      style: PbmsText.caption),
                ),
              const Spacer(),
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

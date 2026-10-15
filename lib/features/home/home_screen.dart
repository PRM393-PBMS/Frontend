import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_tag.dart';
import '../../core/widgets/ticket_qr.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';
import '../auth/presentation/blocs/auth_bloc.dart';
import '../auth/presentation/blocs/auth_state.dart';
import '../sessions/session_detail_sheet.dart';
import '../shell/shell_scope.dart';
import 'widgets/facility_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ReloadOnDataChange {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _sessions = AsyncCubit(_repo.getMySessions);
  late final _reservations = AsyncCubit(_repo.getMyReservations);
  late final _availability = AsyncCubit(() => _repo.getAvailability());
  late final _pricing = AsyncCubit(_repo.getPricingPolicies);
  late final _passes = AsyncCubit(_repo.getMySubscriptions);
  late final _notifications = AsyncCubit(_repo.getNotifications);
  DateTime _updatedAt = DateTime.now();

  @override
  void reloadAll() {
    _updatedAt = DateTime.now();
    _sessions.load();
    _reservations.load();
    _availability.load();
    _pricing.load();
    _passes.load();
    _notifications.load();
  }

  Future<void> _refresh() async {
    setState(reloadAll);
    await Future.wait([
      _sessions.stream.firstWhere((s) => !s.isLoading),
      _availability.stream.firstWhere((s) => !s.isLoading),
    ]).timeout(const Duration(seconds: 30), onTimeout: () => const []);
  }

  @override
  void dispose() {
    for (final c in [_sessions, _reservations, _availability, _pricing, _passes, _notifications]) {
      c.close();
    }
    super.dispose();
  }

  void _goTab(int tab) => ShellScope.maybeOf(context)?.goTab(tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, AppSpacing.scrollBottom),
            children: [
              _Header(
                notifications: _notifications,
                onOpenNotifications: () async {
                  await context.push(RouteNames.notificationsPath);
                  _notifications.load();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _ClusterSection(
                sessions: _sessions,
                reservations: _reservations,
                onReserve: () => _goTab(AppTab.reserve),
                onChanged: reloadAll,
              ),
              BlocBuilder<AsyncCubit<List<MonthlySubscriptionModel>>,
                  AsyncState<List<MonthlySubscriptionModel>>>(
                bloc: _passes,
                builder: (context, st) => _PassStrip(
                  passes: st.data ?? const [],
                  onOpen: () => _goTab(AppTab.pass),
                ),
              ),
              SectionHeader(
                title: 'Chỗ trống theo tầng',
                trailing: Text(
                  'Cập nhật ${DateFormatter.formatTime(_updatedAt)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              BlocBuilder<AsyncCubit<List<FacilityAvailabilityModel>>,
                  AsyncState<List<FacilityAvailabilityModel>>>(
                bloc: _availability,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _availability.load,
                  loading: const SkeletonList(count: 2, itemHeight: 76),
                  isEmpty: (d) => d.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.local_parking_rounded,
                    title: 'Chưa có dữ liệu ô đỗ',
                    message: 'Bãi xe chưa cấu hình tầng và ô đỗ. Vui lòng quay lại sau.',
                  ),
                  builder: (items) => FloorAvailabilityList(items: items),
                ),
              ),
              const SectionHeader(title: 'Bảng giá gửi xe'),
              BlocBuilder<AsyncCubit<List<PricingPolicyModel>>, AsyncState<List<PricingPolicyModel>>>(
                bloc: _pricing,
                builder: (context, st) => AsyncView(
                  state: st,
                  onRetry: _pricing.load,
                  loading: const SkeletonList(count: 2, itemHeight: 72),
                  isEmpty: (d) => d.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.sell_outlined,
                    title: 'Chưa công bố giá',
                    message: 'Bãi xe chưa có chính sách giá đang áp dụng.',
                  ),
                  builder: (items) => PricingTable(policies: items),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AsyncCubit<NotificationPage> notifications;
  final VoidCallback onOpenNotifications;

  const _Header({required this.notifications, required this.onOpenNotifications});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) => a.user != b.user,
            builder: (context, state) {
              final user = state.user;
              final full = (user?.fullName?.trim().isNotEmpty ?? false)
                  ? user!.fullName!.trim()
                  : (user?.userName ?? '');
              final given = full.split(RegExp(r'\s+')).last;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(), style: t.bodyMedium?.copyWith(color: p.textSecondary)),
                  Text(
                    given.isEmpty ? 'Tài xế' : given,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineMedium,
                  ),
                ],
              );
            },
          ),
        ),
        BlocBuilder<AsyncCubit<NotificationPage>, AsyncState<NotificationPage>>(
          bloc: notifications,
          builder: (context, st) {
            final unread = st.data?.unreadCount ?? 0;
            return IconButton(
              tooltip: unread > 0 ? '$unread thông báo chưa đọc' : 'Thông báo',
              onPressed: onOpenNotifications,
              style: IconButton.styleFrom(
                backgroundColor: p.surface,
                side: BorderSide(color: p.line),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              icon: Badge(
                isLabelVisible: unread > 0,
                backgroundColor: p.danger,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bảng đồng hồ chính: phiên đang gửi → đặt chỗ sắp tới → mời đặt chỗ.
class _ClusterSection extends StatelessWidget {
  final AsyncCubit<List<ParkingSessionModel>> sessions;
  final AsyncCubit<List<ReservationModel>> reservations;
  final VoidCallback onReserve;
  final VoidCallback onChanged;

  const _ClusterSection({
    required this.sessions,
    required this.reservations,
    required this.onReserve,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AsyncCubit<List<ParkingSessionModel>>, AsyncState<List<ParkingSessionModel>>>(
      bloc: sessions,
      builder: (context, ss) =>
          BlocBuilder<AsyncCubit<List<ReservationModel>>, AsyncState<List<ReservationModel>>>(
        bloc: reservations,
        builder: (context, rs) {
          final sessionList = ss.data;
          if (sessionList == null) {
            if (ss.status == AsyncStatus.error) {
              return ErrorState(
                title: 'Không tải được lượt gửi xe',
                message: ss.error ?? '',
                onRetry: sessions.load,
              );
            }
            return const _ClusterSkeleton();
          }
          final active = sessionList.where((s) => s.isActive).toList();
          if (active.isNotEmpty) {
            return Column(
              children: [
                for (final s in active) ...[
                  _LiveSessionPanel(session: s),
                  if (s != active.last) const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          }
          final upcoming = (rs.data ?? const <ReservationModel>[])
              .where((r) => r.isUpcoming || r.isPending)
              .toList()
            ..sort((a, b) => a.expectedEntryTime.compareTo(b.expectedEntryTime));
          if (upcoming.isNotEmpty) {
            return _UpcomingPanel(reservation: upcoming.first, onOpen: onReserve);
          }
          return _IdlePanel(onReserve: onReserve);
        },
      ),
    );
  }
}

class _InstrumentPanel extends StatelessWidget {
  final Widget child;

  const _InstrumentPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.panelLine),
        boxShadow: const [
          BoxShadow(color: Color(0x290B1220), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: AppColors.panelText,
                displayColor: AppColors.panelText,
              ),
        ),
        child: child,
      ),
    );
  }
}

class _LiveSessionPanel extends StatelessWidget {
  final ParkingSessionModel session;

  const _LiveSessionPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = session;
    return _InstrumentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PlateBadge(plate: s.licensePlateIn, fontSize: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PanelPill(label: 'Đang trong bãi', color: AppColors.emeraldBright),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Thời gian đỗ', style: t.labelSmall?.copyWith(color: AppColors.panelMuted)),
          const SizedBox(height: 2),
          LiveDuration(
            since: s.entryTime,
            style: AppTypography.mono(
              size: 52,
              weight: FontWeight.w600,
              color: AppColors.panelText,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Gauge(
                  label: 'Vào lúc',
                  value: DateFormatter.formatTime(s.entryTime),
                  size: 18,
                  labelColor: AppColors.panelMuted,
                  valueColor: AppColors.panelText,
                ),
              ),
              Expanded(
                child: Gauge(
                  label: 'Vị trí',
                  value: s.slotCode ?? '—',
                  size: 18,
                  labelColor: AppColors.panelMuted,
                  valueColor: AppColors.panelText,
                ),
              ),
              Expanded(
                child: Gauge(
                  label: 'Cổng vào',
                  value: s.entryGateName ?? '—',
                  size: 14,
                  labelColor: AppColors.panelMuted,
                  valueColor: AppColors.panelText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (s.ticket != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => TicketQr.present(
                      context,
                      payload: s.ticket!.qrPayload,
                      title: 'Mã QR ra cổng',
                      plate: s.licensePlateIn,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.panelText,
                      foregroundColor: AppColors.panel,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('Mã QR ra'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => SessionDetailSheet.show(context, s),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.panelText,
                    side: const BorderSide(color: AppColors.panelLine, width: 1.2),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Phí & chi tiết'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingPanel extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onOpen;

  const _UpcomingPanel({required this.reservation, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = reservation;
    final pending = r.isPending;
    final info = StatusInfo.reservation(r.status);
    final until = r.expectedEntryTime.difference(DateTime.now());
    return _InstrumentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Chỗ đã giữ', style: t.titleMedium?.copyWith(color: AppColors.panelText)),
              const Spacer(),
              _PanelPill(
                label: info.label,
                color: pending ? AppColors.amberBright : AppColors.emeraldBright,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            DateFormatter.formatTime(r.expectedEntryTime),
            style: AppTypography.mono(
              size: 52,
              weight: FontWeight.w600,
              color: AppColors.panelText,
              letterSpacing: -2,
            ),
          ),
          Text(
            until.isNegative
                ? '${DateFormatter.formatDay(r.expectedEntryTime)} · đã tới giờ vào'
                : '${DateFormatter.formatDay(r.expectedEntryTime)} · còn ${DateFormatter.humanDuration(until)}',
            style: t.bodyMedium?.copyWith(color: AppColors.panelMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (!pending && r.ticket != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => TicketQr.present(
                      context,
                      payload: r.ticket!.qrPayload,
                      title: 'Mã QR vào cổng',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.panelText,
                      foregroundColor: AppColors.panel,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('Mã QR vào'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: pending
                    ? FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: AppColors.carbon950,
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Hoàn tất đặt cọc'),
                      )
                    : OutlinedButton(
                        onPressed: onOpen,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.panelText,
                          side: const BorderSide(color: AppColors.panelLine, width: 1.2),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Quản lý'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdlePanel extends StatelessWidget {
  final VoidCallback onReserve;

  const _IdlePanel({required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _InstrumentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Không có xe trong bãi',
              style: t.headlineSmall?.copyWith(color: AppColors.panelText)),
          const SizedBox(height: 6),
          Text(
            'Giữ chỗ ô tô trước tối đa 5 giờ, đến nơi chỉ việc quét mã ở cổng.',
            style: t.bodyMedium?.copyWith(color: AppColors.panelMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onReserve,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cobaltBright,
              foregroundColor: AppColors.carbon950,
              minimumSize: const Size(0, 50),
            ),
            icon: const Icon(Icons.event_available_rounded, size: 20),
            label: const Text('Đặt chỗ trước'),
          ),
        ],
      ),
    );
  }
}

class _ClusterSkeleton extends StatelessWidget {
  const _ClusterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 248,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppSpacing.roundedXl,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 26),
          SizedBox(height: 28),
          Skeleton(width: 70, height: 10),
          SizedBox(height: 8),
          Skeleton(width: 180, height: 44),
          Spacer(),
          Skeleton(height: 48, radius: 10),
        ],
      ),
    );
  }
}

class _PanelPill extends StatelessWidget {
  final String label;
  final Color color;

  const _PanelPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.panelRaised,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.panelText, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Dải vé tháng: hiện vé hiệu lực gần hết hạn nhất, hoặc chờ thanh toán.
class _PassStrip extends StatelessWidget {
  final List<MonthlySubscriptionModel> passes;
  final VoidCallback onOpen;

  const _PassStrip({required this.passes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final relevant = passes.where((s) => s.isActive || s.isPendingPayment).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    if (relevant.isEmpty) return const SizedBox.shrink();
    final pass = relevant.first;
    final info = StatusInfo.subscription(pass.status);
    final soon = pass.isActive && pass.daysLeft <= 5;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppPanel(
        onTap: onOpen,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            PlateBadge(plate: pass.licensePlate, fontSize: 13),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pass.packageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    pass.isActive
                        ? 'Còn ${pass.daysLeft} ngày · đến ${DateFormatter.formatDate(pass.endDate)}'
                        : info.label,
                    style: t.bodySmall?.copyWith(color: soon || !pass.isActive ? p.warn : null),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

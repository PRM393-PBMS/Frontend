import '../../../core/l10n/locale_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/settle.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/titanium_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/blocs/auth_bloc.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../reservations/data/reservation_repository.dart';
import '../../sessions/data/session_repository.dart';

class HomeData extends Equatable {
  final List<ParkingSession> activeSessions;
  final Reservation? nextReservation;
  final AvailabilityOverview? overview;
  final Object? overviewError;

  /// Lỗi từng phần: trang chủ vẫn hiển thị các phần còn lại.
  final Object? sessionsError;
  final Object? reservationsError;

  const HomeData({
    required this.activeSessions,
    required this.nextReservation,
    required this.overview,
    required this.overviewError,
    this.sessionsError,
    this.reservationsError,
  });

  @override
  List<Object?> get props => [
        activeSessions,
        nextReservation,
        overview,
        overviewError,
        sessionsError,
        reservationsError,
      ];
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late final DataCubit<HomeData> _cubit = DataCubit(_load)..load();

  Future<HomeData> _load() async {
    final sessionsF = settle(context.read<SessionRepository>().mine());
    final reservationsF = settle(context.read<ReservationRepository>().mine());
    final overviewF = settle(context.read<CatalogRepository>().overview());
    final sessionsR = await sessionsF;
    final reservationsR = await reservationsF;
    final overviewR = await overviewF;

    // Chỉ báo lỗi toàn trang khi không phần nào tải được.
    if (!sessionsR.isOk && !reservationsR.isOk && !overviewR.isOk) {
      throw sessionsR.error!;
    }

    final sessions = sessionsR.value ?? const <ParkingSession>[];
    final upcoming = (reservationsR.value ?? const <Reservation>[])
        .where((r) => r.isUpcoming && r.expectedEntryTime != null)
        .toList()
      ..sort((a, b) => a.expectedEntryTime!.compareTo(b.expectedEntryTime!));

    return HomeData(
      activeSessions: sessions.where((s) => s.isActive).toList(),
      nextReservation: upcoming.isEmpty ? null : upcoming.first,
      overview: overviewR.value,
      overviewError: overviewR.error,
      sessionsError: sessionsR.error,
      reservationsError: reservationsR.error,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.select((AuthBloc b) => b.state.user);
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? context.l10n.homeMorning
        : (hour < 18 ? context.l10n.homeAfternoon : context.l10n.homeEvening);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.page,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: AppTypography.caption.copyWith(color: p.textSecondary)),
            Text(user?.displayName ?? '',
                style: AppTypography.title.copyWith(color: p.textPrimary),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: AppSpacing.sm)],
      ),
      body: LoadStateView<HomeData>(
        cubit: _cubit,
        loading: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
                height: 168, radius: BorderRadius.all(Radius.circular(16))),
            SizedBox(height: AppSpacing.xl),
            SkeletonList(count: 2, itemHeight: 84),
          ],
        ),
        builder: (context, data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.sessionsError != null) ...[
              InlineMessage(errorText(data.sessionsError, context.l10n)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (data.reservationsError != null) ...[
              InlineMessage(errorText(data.reservationsError, context.l10n)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (data.activeSessions.isNotEmpty)
              for (final s in data.activeSessions) ...[
                _ActiveSessionCard(
                  session: s,
                  onTap: () => _open(RouteNames.sessionDetail(s.id)),
                ),
                const SizedBox(height: AppSpacing.md),
              ]
            else
              _AvailabilityHero(
                overview: data.overview,
                error: data.overviewError,
                onTap: () => _open(RouteNames.availability),
              ),
            if (data.nextReservation != null) ...[
              const SizedBox(height: AppSpacing.md),
              _UpcomingReservation(
                reservation: data.nextReservation!,
                onTap: () => _open(
                    RouteNames.reservationDetail(data.nextReservation!.id)),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(context.l10n.homeServices),
            _ActionRow(
              icon: Icons.event_available_rounded,
              title: context.l10n.homeBookCar,
              subtitle: context.l10n.homeBookCarSub,
              onTap: () => _open(RouteNames.newReservation),
              highlight: true,
            ),
            _ActionRow(
              icon: Icons.calendar_month_outlined,
              title: context.l10n.homeMyBookings,
              subtitle: context.l10n.homeMyBookingsSub,
              onTap: () => _open(RouteNames.reservations),
            ),
            _ActionRow(
              icon: Icons.local_parking_rounded,
              title: context.l10n.homeAvailability,
              subtitle: context.l10n.homeAvailabilitySub,
              onTap: () => _open(RouteNames.availability),
            ),
            _ActionRow(
              icon: Icons.report_gmailerrorred_rounded,
              title: context.l10n.homeReport,
              subtitle: context.l10n.homeReportSub,
              onTap: () => _open(RouteNames.incidents),
            ),
            if (data.activeSessions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              _AvailabilityHero(
                overview: data.overview,
                error: data.overviewError,
                onTap: () => _open(RouteNames.availability),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final ParkingSession session;
  final VoidCallback onTap;

  const _ActiveSessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Nội dung nằm trên nền titanium nên luôn dùng bảng màu tối.
    const p = AppPalette.dark;
    return TitaniumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(StatusLabels.session(context.l10n, session.status)),
              const Spacer(),
              PlateTag(session.licensePlateIn),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
              context.l10n.homeParkedFor(
                  DateFormatter.formatDuration(context.l10n, session.elapsed)),
              style: AppTypography.headline.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.homeEnteredAt(
                    DateFormatter.formatRelativeDay(
                        context.l10n, session.entryTime),
                    session.entryGateName) +
                (session.slotCode != null
                    ? context.l10n.homeEnteredSlot(session.slotCode!)
                    : ''),
            style: AppTypography.bodySmall.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 18, color: p.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  session.hasPendingCheckout
                      ? context.l10n.homePayToExit
                      : context.l10n.homeViewTicket,
                  style: AppTypography.label.copyWith(color: p.accent),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityHero extends StatelessWidget {
  final AvailabilityOverview? overview;
  final Object? error;
  final VoidCallback onTap;

  const _AvailabilityHero(
      {required this.overview, required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = overview;
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.homeFreeNow,
              style: AppTypography.labelSmall.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          if (o == null)
            Text(
                error != null
                    ? errorText(error, context.l10n)
                    : context.l10n.homeNoAvailability,
                style: AppTypography.bodySmall.copyWith(color: p.textSecondary))
          else if (o.entries.isEmpty)
            Text(context.l10n.homeNoSlots,
                style: AppTypography.bodySmall.copyWith(color: p.textSecondary))
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${o.totalAvailable}',
                    style: AppTypography.figure
                        .copyWith(color: p.textPrimary, fontSize: 40)),
                const SizedBox(width: AppSpacing.sm),
                Text(context.l10n.homeOfSpaces('${o.totalSlots}'),
                    style: AppTypography.body.copyWith(color: p.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in o.byVehicleType.entries)
                  Text(context.l10n.homeTypeFree(e.key, '${e.value.available}'),
                      style: AppTypography.label.copyWith(
                        color:
                            e.value.available == 0 ? p.danger : p.textPrimary,
                      )),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(context.l10n.homeByFloor,
                  style: AppTypography.label.copyWith(color: p.accent)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: p.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingReservation extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;

  const _UpcomingReservation({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSurface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: p.accentSoft, borderRadius: AppSpacing.control),
            child: Icon(Icons.event_rounded, color: p.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    context.l10n.homeBookingAt(DateFormatter.formatRelativeDay(
                        context.l10n, reservation.expectedEntryTime)),
                    style: AppTypography.label.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  reservation.isPending
                      ? context.l10n.homeFinishDeposit
                      : context.l10n.homeArriveWindow,
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
              StatusLabels.reservation(context.l10n, reservation.status)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppSpacing.control,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight ? p.accent : p.surfaceMuted,
                  borderRadius: AppSpacing.control,
                ),
                child: Icon(icon,
                    size: 20,
                    color: highlight
                        ? Theme.of(context).colorScheme.onPrimary
                        : p.textPrimary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppTypography.label.copyWith(color: p.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTypography.caption
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dùng lại cho màn khác khi cần thông báo lỗi tải chỗ trống.
class AvailabilityError extends StatelessWidget {
  final String message;

  const AvailabilityError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => InlineMessage(message);
}

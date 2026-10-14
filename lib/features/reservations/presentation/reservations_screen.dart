import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/reservation_repository.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  late final DataCubit<List<Reservation>> _cubit =
      DataCubit(context.read<ReservationRepository>().mine)..load();

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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeMyBookings)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(RouteNames.newReservation),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.resNew),
      ),
      body: LoadStateView<List<Reservation>>(
        cubit: _cubit,
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.event_available_outlined,
          title: context.l10n.resEmptyTitle,
          message: context.l10n.resEmptyMessage,
          actionLabel: context.l10n.homeBookCar,
          onAction: () => _open(RouteNames.newReservation),
        ),
        builder: (context, list) {
          final upcoming = list.where((r) => r.isUpcoming).toList();
          final past = list.where((r) => !r.isUpcoming).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (upcoming.isNotEmpty) ...[
                SectionHeader(context.l10n.resUpcoming),
                for (final r in upcoming) ...[
                  _ReservationTile(r,
                      onTap: () => _open(RouteNames.reservationDetail(r.id))),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (past.isNotEmpty) ...[
                SectionHeader(context.l10n.resPast),
                for (final r in past) ...[
                  _ReservationTile(r,
                      onTap: () => _open(RouteNames.reservationDetail(r.id))),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation r;
  final VoidCallback onTap;

  const _ReservationTile(this.r, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppSurface(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    DateFormatter.formatRelativeDay(
                        context.l10n, r.expectedEntryTime),
                    style: AppTypography.titleSmall
                        .copyWith(color: p.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    context.l10n.resTileMeta(
                        r.vehicleTypeName,
                        DateFormatter.timeAgo(context.l10n, r.createdAt)
                            .toLowerCase()),
                    style:
                        AppTypography.caption.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          StatusBadge(StatusLabels.reservation(context.l10n, r.status)),
        ],
      ),
    );
  }
}

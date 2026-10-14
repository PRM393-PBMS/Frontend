import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/ticket_qr.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../data/reservation_repository.dart';
import 'time_slot_picker.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  late final ReservationRepository _repo =
      context.read<ReservationRepository>();
  late final DataCubit<Reservation> _cubit =
      DataCubit(() => _repo.byId(widget.reservationId))..load();
  bool _busy = false;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _cubit.refresh();
    }
  }

  Future<void> _pay(Reservation r) => _guard(() async {
        final link = await _repo.recreatePayment(r.id);
        if (!mounted) return;
        final paid = await PaymentSheet.show(
          context,
          title: context.l10n.resDepositTitle,
          description: context.l10n.resDepositDescShort(
              DateFormatter.formatRelativeDay(
                  context.l10n, r.expectedEntryTime)),
          link: link,
          checkStatus: () => _repo.paymentStatus(link.orderCode),
        );
        if (paid && mounted) showAppSnack(context, context.l10n.resConfirmed);
      });

  Future<void> _cancel(Reservation r) async {
    final ok = await confirmAction(
      context,
      title: context.l10n.resCancelTitle,
      message: r.isPending
          ? context.l10n.resCancelPending
          : context.l10n.resCancelPaid,
      confirmLabel: context.l10n.resCancelAction,
      destructive: true,
    );
    if (!ok) return;
    await _guard(() async {
      await _repo.cancel(r.id);
      if (mounted) showAppSnack(context, context.l10n.resCancelled);
    });
  }

  Future<void> _changeTime(Reservation r) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChangeTimeSheet(current: r.expectedEntryTime),
    );
    if (picked == null) return;
    await _guard(() async {
      await _repo.changeTime(r.id, picked);
      if (mounted) {
        showAppSnack(
            context,
            context.l10n.resRescheduled(
                DateFormatter.formatRelativeDay(context.l10n, picked)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.resDetailTitle)),
      body: LoadStateView<Reservation>(
        cubit: _cubit,
        loading: const Column(children: [
          SkeletonBox(
              height: 280, radius: BorderRadius.all(Radius.circular(16))),
        ]),
        builder: (context, r) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(StatusLabels.reservation(context.l10n, r.status)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                      DateFormatter.formatRelativeDay(
                          context.l10n, r.expectedEntryTime),
                      style: AppTypography.headline
                          .copyWith(color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.resEntryWindow(
                      DateFormatter.formatTime(r.expectedEntryTime
                          ?.subtract(const Duration(minutes: 30))),
                      DateFormatter.formatTime(r.expectedEntryTime
                          ?.add(const Duration(minutes: 30))),
                    ),
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary),
                  ),
                  if (r.showsTicket && r.ticket != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: TicketQr(
                        payload: r.ticket!.qrPayload,
                        caption: context.l10n.resShowAtEntry,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              child: Column(
                children: [
                  KeyValueRow(context.l10n.fieldVehicleType, r.vehicleTypeName),
                  KeyValueRow(context.l10n.resBookedAt,
                      DateFormatter.formatDateTime(r.createdAt)),
                  KeyValueRow(
                      context.l10n.resReschedule,
                      r.isModified
                          ? context.l10n.resRescheduleUsed
                          : context.l10n.resRescheduleLeft),
                ],
              ),
            ),
            if (r.isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.resPendingNote,
                style: AppTypography.caption.copyWith(color: p.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (r.isPending)
              AppButton(
                label: context.l10n.resPayDeposit,
                icon: Icons.payments_outlined,
                loading: _busy,
                onPressed: () => _pay(r),
              ),
            if (r.canChangeTime) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: context.l10n.resChangeTime,
                icon: Icons.schedule_rounded,
                onPressed: _busy ? null : () => _changeTime(r),
              ),
            ],
            if (r.isConfirmed && !r.canChangeTime)
              Text(context.l10n.resChangeRule,
                  style: AppTypography.caption.copyWith(color: p.textMuted)),
            if (r.canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.text(
                label: context.l10n.resCancelAction,
                onPressed: _busy ? null : () => _cancel(r),
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeTimeSheet extends StatefulWidget {
  final DateTime? current;

  const _ChangeTimeSheet({required this.current});

  @override
  State<_ChangeTimeSheet> createState() => _ChangeTimeSheetState();
}

class _ChangeTimeSheetState extends State<_ChangeTimeSheet> {
  final _slots = buildTimeSlots();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.resNewTime,
              style: AppTypography.title.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.resOneChange,
              style: AppTypography.bodySmall.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: TimeSlotPicker(
                slots: _slots.where((s) => s != widget.current).toList(),
                selected: _selected,
                onSelected: (t) => setState(() => _selected = t),
              ),
            ),
          ),
          AppButton(
            label: context.l10n.resConfirmChange,
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    );
  }
}

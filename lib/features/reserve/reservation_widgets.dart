import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/status_tag.dart';
import '../../core/widgets/ticket_qr.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';

/// Giới hạn đặt trước của backend: sau hiện tại và tối đa 5 giờ.
class ReservationWindow {
  ReservationWindow._();
  static const maxAhead = Duration(hours: 5);
  static const minLead = Duration(minutes: 10);

  static bool isValid(DateTime t) {
    final now = DateTime.now();
    return t.isAfter(now.add(const Duration(minutes: 1))) && !t.isAfter(now.add(maxAhead));
  }

  static DateTime roundUp(DateTime t, {int step = 5}) {
    final extra = (step - t.minute % step) % step;
    return DateTime(t.year, t.month, t.day, t.hour, t.minute + extra);
  }
}

/// Chọn giờ dự kiến vào bãi: lối tắt + giờ tuỳ chọn.
class EntryTimePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const EntryTimePicker({super.key, required this.value, required this.onChanged});

  static const _offsets = [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
  ];

  String _label(Duration d) => d.inMinutes < 60 ? '+${d.inMinutes} phút' : '+${d.inHours} giờ';

  Future<void> _custom(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? ReservationWindow.roundUp(now.add(const Duration(minutes: 30)));
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Giờ dự kiến vào bãi',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    var t = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    if (!ReservationWindow.isValid(t)) {
      showSnack(context, 'Chỉ đặt trước được trong vòng 5 giờ tới.', error: true);
      return;
    }
    onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value == null ? '--:--' : DateFormatter.formatTime(value),
              style: AppTypography.mono(size: 40, weight: FontWeight.w700, color: p.text, letterSpacing: -1),
            ),
            const SizedBox(width: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                value == null
                    ? 'Chọn giờ vào'
                    : '${DateFormatter.formatDay(value!)} · sau ${DateFormatter.humanDuration(value!.difference(now))}',
                style: t.bodyMedium?.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _offsets)
              ChoiceChip(
                label: Text(_label(d)),
                selected: value != null &&
                    (value!.difference(now) - d).inMinutes.abs() < 3,
                onSelected: (_) => onChanged(ReservationWindow.roundUp(DateTime.now().add(d))),
              ),
            ActionChip(
              avatar: const Icon(Icons.schedule_rounded, size: 18),
              label: const Text('Giờ khác'),
              onPressed: () => _custom(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// Thẻ đặt chỗ với các hành động phù hợp trạng thái.
class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onChanged;

  const ReservationCard({super.key, required this.reservation, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final r = reservation;
    final info = StatusInfo.reservation(r.status);
    final confirmed = r.isUpcoming;

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatTime(r.expectedEntryTime),
                      style: AppTypography.mono(size: 24, weight: FontWeight.w700, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.formatDay(r.expectedEntryTime)} · ${r.vehicleTypeName}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StatusTag.of(info),
              ),
            ],
          ),
          if (r.canModify) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              children: [
                if (r.isPending)
                  TextButton.icon(
                    onPressed: () => ReservationActions.payDeposit(context, r, onChanged),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Đặt cọc'),
                  ),
                if (confirmed && r.ticket != null)
                  TextButton.icon(
                    onPressed: () => TicketQr.present(
                      context,
                      payload: r.ticket!.qrPayload,
                      title: 'Mã QR vào cổng',
                      caption: 'Quét tại cổng vào lúc ${DateFormatter.formatDayTime(r.expectedEntryTime)}.',
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Mã QR'),
                  ),
                if (confirmed)
                  TextButton.icon(
                    onPressed: () => ReservationActions.changeTime(context, r, onChanged),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: const Text('Đổi giờ'),
                  ),
                TextButton(
                  onPressed: () => ReservationActions.cancel(context, r, onChanged),
                  style: TextButton.styleFrom(foregroundColor: p.danger),
                  child: const Text('Huỷ'),
                ),
              ],
            ),
          ] else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class ReservationActions {
  ReservationActions._();

  static Future<void> _verifyAndPay(
    BuildContext context,
    PaymentLinkModel link,
    VoidCallback onChanged,
  ) async {
    final repo = context.read<PbmsRepository>();
    final paid = await PaymentSheet.show(
      context,
      title: 'Đặt cọc giữ chỗ',
      link: link,
      verify: link.orderCode == null && link.reservationId == null
          ? null
          : () async {
              // Kiểm tra theo mã đơn PayOS, sau đó đối chiếu trạng thái đặt chỗ.
              if (link.orderCode != null) {
                final st = await repo.checkPaymentStatus(link.orderCode!);
                if (st.isPaid) return PaymentCheck.paid;
              }
              if (link.reservationId != null) {
                final r = await repo.getReservation(link.reservationId!);
                if (r.isUpcoming) return PaymentCheck.paid;
              }
              return PaymentCheck.pending;
            },
    );
    onChanged();
    if (paid && context.mounted) {
      showSnack(context, 'Đặt cọc thành công. Chỗ của bạn đã được giữ.');
    }
  }

  /// Gọi sau khi tạo đặt chỗ mới.
  static Future<void> payNew(BuildContext context, PaymentLinkModel link, VoidCallback onChanged) =>
      _verifyAndPay(context, link, onChanged);

  static Future<void> payDeposit(
    BuildContext context,
    ReservationModel r,
    VoidCallback onChanged,
  ) async {
    final repo = context.read<PbmsRepository>();
    try {
      final link = await repo.recreateReservationPayment(r.reservationId);
      if (!context.mounted) return;
      await _verifyAndPay(context, link, onChanged);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(e), error: true);
    }
  }

  static Future<void> cancel(
    BuildContext context,
    ReservationModel r,
    VoidCallback onChanged,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ đặt chỗ?'),
        content: Text(
          'Chỗ giữ lúc ${DateFormatter.formatDayTime(r.expectedEntryTime)} sẽ được nhả cho người khác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Huỷ đặt chỗ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PbmsRepository>().cancelReservation(r.reservationId);
      if (context.mounted) showSnack(context, 'Đã huỷ đặt chỗ.');
      onChanged();
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(e), error: true);
    }
  }

  static Future<void> changeTime(
    BuildContext context,
    ReservationModel r,
    VoidCallback onChanged,
  ) async {
    final repo = context.read<PbmsRepository>();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChangeTimeSheet(reservation: r, repo: repo),
    );
    if (changed == true) {
      onChanged();
      if (context.mounted) showSnack(context, 'Đã đổi giờ vào bãi.');
    }
  }
}

class _ChangeTimeSheet extends StatefulWidget {
  final ReservationModel reservation;
  final PbmsRepository repo;

  const _ChangeTimeSheet({required this.reservation, required this.repo});

  @override
  State<_ChangeTimeSheet> createState() => _ChangeTimeSheetState();
}

class _ChangeTimeSheetState extends State<_ChangeTimeSheet> {
  DateTime? _time;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final time = _time;
    if (time == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.changeReservationTime(widget.reservation.reservationId, time);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đổi giờ vào bãi', style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Đang giữ: ${DateFormatter.formatDayTime(widget.reservation.expectedEntryTime)}',
            style: t.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          EntryTimePicker(value: _time, onChanged: (v) => setState(() => _time = v)),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: t.bodyMedium?.copyWith(color: p.danger)),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _time == null || _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Xác nhận giờ mới'),
          ),
        ],
      ),
    );
  }
}

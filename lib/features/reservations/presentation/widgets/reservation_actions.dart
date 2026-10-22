import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Giới hạn đặt trước của backend: sau hiện tại và tối đa 5 giờ.
class ReservationWindow {
  ReservationWindow._();
  static const maxAhead = Duration(hours: 5);

  static bool isValid(DateTime t) {
    final now = DateTime.now();
    return t.isAfter(now.add(const Duration(minutes: 1))) &&
        !t.isAfter(now.add(maxAhead));
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

  const EntryTimePicker(
      {super.key, required this.value, required this.onChanged});

  static const _offsets = [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
  ];

  String _label(Duration d) =>
      d.inMinutes < 60 ? '+${d.inMinutes} phút' : '+${d.inHours} giờ';

  Future<void> _custom(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ??
        ReservationWindow.roundUp(now.add(const Duration(minutes: 30)));
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
      showPbmsSnack(context, 'Chỉ đặt trước được trong vòng 5 giờ tới.',
          error: true);
      return;
    }
    onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(v == null ? '--:--' : DateFormatter.formatTime(v),
                style: PbmsText.display(40)),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  v == null
                      ? 'Chọn giờ vào bãi'
                      : '${DateFormatter.formatDay(v)}, sau ${DateFormatter.humanDuration(v.difference(now))}',
                  style: PbmsText.caption,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _offsets)
              ChoiceChip(
                label: Text(_label(d)),
                selected:
                    v != null && (v.difference(now) - d).inMinutes.abs() < 3,
                selectedColor: PbmsTokens.tealTint,
                side: const BorderSide(color: PbmsTokens.border),
                labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PbmsTokens.ink),
                showCheckmark: false,
                onSelected: (_) => onChanged(
                    ReservationWindow.roundUp(DateTime.now().add(d))),
              ),
            ActionChip(
              avatar: const Icon(Icons.schedule_rounded,
                  size: 18, color: PbmsTokens.teal),
              label: const Text('Giờ khác'),
              side: const BorderSide(color: PbmsTokens.border),
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

  const ReservationCard(
      {super.key, required this.reservation, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final ticket = r.ticket;
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 8, 6),
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
                    Text(DateFormatter.formatTime(r.expectedEntryTime),
                        style: PbmsText.figure(20)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          DateFormatter.formatDay(r.expectedEntryTime),
                          r.licensePlate ?? r.vehicleTypeName,
                          if (r.depositAmount != null)
                            'cọc ${CurrencyFormatter.format(r.depositAmount!)}',
                        ].join(', '),
                        style: PbmsText.caption),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: PbmsStatusPill(StatusInfo.reservation(r.status)),
              ),
            ],
          ),
          if (r.canModify)
            Wrap(
              children: [
                if (r.isPending)
                  _action(Icons.payments_outlined, 'Đặt cọc',
                      () => ReservationActions.payDeposit(context, r, onChanged)),
                if (r.isUpcoming && ticket != null)
                  _action(
                    Icons.qr_code_2_rounded,
                    'Mã QR',
                    () => PbmsQrDialog.show(
                      context,
                      title: 'Mã QR vào cổng',
                      payload: ticket.qrPayload,
                      plate: r.licensePlate,
                      isMotorbike: r.vehicleTypeName.toLowerCase().contains('máy'),
                      headline: r.vehicleTypeName,
                      rows: [
                        (Icons.location_on_outlined, 'Địa điểm', PbmsFacility.name),
                        (Icons.schedule_rounded, 'Giờ vào dự kiến',
                            DateFormatter.formatDayTime(r.expectedEntryTime)),
                      ],
                    ),
                  ),
                if (r.canChangeTime)
                  _action(Icons.edit_calendar_outlined, 'Đổi giờ',
                      () => ReservationActions.changeTime(context, r, onChanged)),
                TextButton(
                  onPressed: () =>
                      ReservationActions.cancel(context, r, onChanged),
                  style: TextButton.styleFrom(
                      foregroundColor: PbmsTokens.danger,
                      minimumSize: const Size(48, 44)),
                  child: const Text('Huỷ'),
                ),
              ],
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
          foregroundColor: PbmsTokens.teal, minimumSize: const Size(48, 44)),
    );
  }
}

class ReservationActions {
  ReservationActions._();

  /// Mở PayOS và xác nhận tiền cọc. Trả về `true` nếu đã thanh toán.
  static Future<bool> _verifyAndPay(
    BuildContext context,
    PaymentLinkModel link,
    VoidCallback onChanged,
  ) async {
    final repo = context.read<PbmsRepository>();
    final paid = await PbmsPaymentSheet.show(
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
      showPbmsSnack(context, 'Đặt cọc thành công. Chỗ của bạn đã được giữ.');
    }
    return paid;
  }

  /// Gọi sau khi tạo đặt chỗ mới.
  static Future<bool> payNew(BuildContext context, PaymentLinkModel link,
          VoidCallback onChanged) =>
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
      if (context.mounted) showPbmsSnack(context, errorText(e), error: true);
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Huỷ đặt chỗ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PbmsRepository>().cancelReservation(r.reservationId);
      if (context.mounted) showPbmsSnack(context, 'Đã huỷ đặt chỗ.');
      onChanged();
    } catch (e) {
      if (context.mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  static Future<void> changeTime(
    BuildContext context,
    ReservationModel r,
    VoidCallback onChanged,
  ) async {
    final repo = context.read<PbmsRepository>();
    final changed = await PbmsSheetFrame.show<bool>(
      context,
      (_) => _ChangeTimeSheet(reservation: r, repo: repo),
    );
    if (changed == true) {
      onChanged();
      if (context.mounted) showPbmsSnack(context, 'Đã đổi giờ vào bãi.');
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
      await widget.repo
          .changeReservationTime(widget.reservation.reservationId, time);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Đổi giờ vào bãi',
      subtitle:
          'Đang giữ: ${DateFormatter.formatDayTime(widget.reservation.expectedEntryTime)}',
      children: [
        EntryTimePicker(value: _time, onChanged: (v) => setState(() => _time = v)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(
          label: 'Xác nhận giờ mới',
          busy: _busy,
          onPressed: _time == null ? null : _submit,
        ),
      ],
    );
  }
}

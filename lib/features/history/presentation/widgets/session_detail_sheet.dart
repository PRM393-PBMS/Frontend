import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Chi tiết một lượt gửi xe: phí tạm tính, mã QR ra cổng, thanh toán.
class SessionDetailSheet extends StatefulWidget {
  final ParkingSessionModel session;

  const SessionDetailSheet({super.key, required this.session});

  static Future<void> show(BuildContext context, ParkingSessionModel session) =>
      PbmsSheetFrame.show<void>(
          context, (_) => SessionDetailSheet(session: session));

  @override
  State<SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<SessionDetailSheet> {
  AsyncCubit<FeePreviewModel>? _fee;
  bool _checkingPayment = false;

  ParkingSessionModel get s => widget.session;

  @override
  void initState() {
    super.initState();
    if (s.isActive) {
      final repo = context.read<PbmsRepository>();
      _fee = AsyncCubit(() => repo.getFeePreview(s.sessionId));
    }
  }

  @override
  void dispose() {
    _fee?.close();
    super.dispose();
  }

  Future<void> _openCheckout() async {
    final repo = context.read<PbmsRepository>();
    setState(() => _checkingPayment = true);
    try {
      final checkout = await repo.getCheckoutPayment(s.sessionId);
      if (!mounted) return;
      final payment = checkout.payment;
      final online = checkout.online;
      if (payment == null) {
        showPbmsSnack(context,
            'Chưa có yêu cầu thanh toán. Nhân viên sẽ tạo khi xe ra cổng.');
        return;
      }
      if (online == null || !online.hasUrl) {
        showPbmsSnack(
          context,
          'Thanh toán ${CurrencyFormatter.format(payment.amount)} bằng ${payment.paymentMethod} tại cổng ra.',
        );
        return;
      }
      final paid = await PbmsPaymentSheet.show(
        context,
        title: 'Thanh toán phí gửi xe',
        link: PaymentLinkModel(
          paymentUrl: online.paymentUrl,
          orderCode: online.orderCode,
          paymentLinkId: online.paymentLinkId,
          amount: payment.amount,
        ),
        verify: online.orderCode == null
            ? null
            : () async {
                final st = await repo.checkPaymentStatus(online.orderCode!);
                return st.isPaid ? PaymentCheck.paid : PaymentCheck.pending;
              },
      );
      if (paid && mounted) {
        showPbmsSnack(context, 'Đã thanh toán. Barie sẽ mở khi xe tới cổng ra.');
      }
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _checkingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = s.ticket;
    return PbmsSheetFrame(
      title: s.licensePlateIn,
      subtitle: s.vehicleTypeName == null
          ? PbmsFacility.name
          : '${s.vehicleTypeName}, ${PbmsFacility.name}',
      children: [
        Row(
          children: [
            PbmsStatusPill(StatusInfo.session(s.status)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(s.isActive ? 'Đã đỗ' : 'Thời lượng',
                    style: PbmsText.caption),
                Text(DateFormatter.clock(s.parkedDuration),
                    style: PbmsText.figure(22, color: PbmsTokens.teal)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _box([
          PbmsDetailRow(
              icon: Icons.login_rounded,
              label: 'Giờ vào',
              value: DateFormatter.formatDateTime(s.entryTime)),
          if (s.entryGateName != null)
            PbmsDetailRow(
                icon: Icons.sensor_door_outlined,
                label: 'Cổng vào',
                value: s.entryGateName!),
          if (s.exitTime != null)
            PbmsDetailRow(
                icon: Icons.logout_rounded,
                label: 'Giờ ra',
                value: DateFormatter.formatDateTime(s.exitTime)),
          if (s.exitGateName != null)
            PbmsDetailRow(
                icon: Icons.sensor_door_outlined,
                label: 'Cổng ra',
                value: s.exitGateName!),
          PbmsDetailRow(
              icon: Icons.local_parking_rounded,
              label: 'Vị trí đỗ',
              value: s.slotCode ?? 'Chưa phân ô'),
        ]),
        if (s.isActive) ...[
          const SizedBox(height: 18),
          const Text('Phí tạm tính', style: PbmsText.section),
          const SizedBox(height: 8),
          PbmsAsync<FeePreviewModel>(
            cubit: _fee!,
            loadingHeight: 150,
            errorTitle: 'Chưa tính được phí',
            builder: (fee) => _FeeBreakdown(fee: fee),
          ),
          const SizedBox(height: 16),
          PbmsPrimaryButton(
            label: ticket == null ? 'Chưa có mã QR ra cổng' : 'Mở mã QR ra cổng',
            icon: Icons.qr_code_2_rounded,
            onPressed: ticket == null
                ? null
                : () => PbmsQrDialog.show(
                      context,
                      title: 'Mã QR ra cổng',
                      payload: ticket.qrPayload,
                      headline: s.licensePlateIn,
                      rows: [
                        (Icons.local_parking_rounded, 'Vị trí đỗ',
                            s.slotCode ?? 'Chưa phân ô'),
                        (Icons.schedule_rounded, 'Vào bãi',
                            DateFormatter.formatDateTime(s.entryTime)),
                      ],
                    ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _checkingPayment ? null : _openCheckout,
              icon: _checkingPayment
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.payments_outlined, size: 19),
              label: const Text('Thanh toán khi ra bãi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PbmsTokens.teal,
                backgroundColor: PbmsTokens.tealTint,
                side: const BorderSide(color: PbmsTokens.tealLine),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 18),
          const Text('Thanh toán', style: PbmsText.section),
          const SizedBox(height: 8),
          _box([
            PbmsDetailRow(
              label: 'Số tiền',
              value: s.paymentAmount == null
                  ? 'Chưa có'
                  : CurrencyFormatter.format(s.paymentAmount!),
            ),
            if (s.paymentMethod != null)
              PbmsDetailRow(label: 'Phương thức', value: s.paymentMethod!),
            if (s.paymentStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Trạng thái', style: PbmsText.caption)),
                    PbmsStatusPill(StatusInfo.payment(s.paymentStatus!)),
                  ],
                ),
              ),
          ]),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () =>
              ReportIncidentSheet.show(context, sessionId: s.sessionId),
          icon: const Icon(Icons.report_gmailerrorred_rounded, size: 20),
          label: const Text('Báo sự cố cho lượt gửi này'),
          style: TextButton.styleFrom(
              foregroundColor: PbmsTokens.muted,
              minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _box(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      decoration: BoxDecoration(
        color: PbmsTokens.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PbmsTokens.border),
      ),
      child: Column(children: rows),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final FeePreviewModel fee;

  const _FeeBreakdown({required this.fee});

  @override
  Widget build(BuildContext context) {
    if (fee.isCoveredBySubscription) {
      return const PbmsCard(
        color: PbmsTokens.tealTint,
        borderColor: PbmsTokens.tealLine,
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: PbmsTokens.teal),
            SizedBox(width: 10),
            Expanded(
              child: Text('Lượt gửi này nằm trong vé tháng, không phát sinh phí.',
                  style: PbmsText.body),
            ),
          ],
        ),
      );
    }
    final extraHours = (fee.billedHours - fee.baseHours).clamp(0, 999);
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PbmsDetailRow(
              label: 'Lượt đầu (${fee.baseHours} giờ)',
              value: CurrencyFormatter.format(fee.basePrice)),
          if (extraHours > 0)
            PbmsDetailRow(
                label: '$extraHours giờ tiếp theo',
                value: CurrencyFormatter.format(extraHours * fee.extraHourPrice)),
          if (fee.nightSurchargeCount > 0)
            PbmsDetailRow(
                label: 'Phụ thu qua đêm x${fee.nightSurchargeCount}',
                value: CurrencyFormatter.format(
                    fee.nightSurchargeCount * fee.nightSurcharge)),
          if (fee.depositAmount > 0)
            PbmsDetailRow(
                label: 'Đã đặt cọc',
                value: '-${CurrencyFormatter.format(fee.depositAmount)}',
                valueColor: PbmsTokens.ok),
          const Divider(height: 14, color: PbmsTokens.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                  child: Text('Cần trả nếu ra bây giờ',
                      style: PbmsText.bodyStrong)),
              Text(CurrencyFormatter.format(fee.amount),
                  style: PbmsText.figure(19, color: PbmsTokens.teal)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Tính theo ${fee.billedHours} giờ, làm tròn từ ${fee.totalHours.toStringAsFixed(1)} giờ đỗ.',
              style: PbmsText.caption),
        ],
      ),
    );
  }
}

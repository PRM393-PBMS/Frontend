import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_tag.dart';
import '../../core/widgets/ticket_qr.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';
import '../account/incidents_screen.dart';

/// Chi tiết một lượt gửi xe.
class SessionDetailSheet extends StatefulWidget {
  final ParkingSessionModel session;
  final ScrollController? controller;

  const SessionDetailSheet({super.key, required this.session, this.controller});

  static Future<void> show(BuildContext context, ParkingSessionModel session) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => SessionDetailSheet(
          session: session,
          controller: controller,
        ),
      ),
    );
  }

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
        showSnack(context, 'Chưa có yêu cầu thanh toán. Nhân viên sẽ tạo khi xe ra cổng.');
        return;
      }
      if (online == null || !online.hasUrl) {
        showSnack(
          context,
          'Thanh toán ${CurrencyFormatter.format(payment.amount)} bằng ${payment.paymentMethod} tại cổng ra.',
        );
        return;
      }
      final link = PaymentLinkModel(
        paymentUrl: online.paymentUrl,
        orderCode: online.orderCode,
        paymentLinkId: online.paymentLinkId,
        amount: payment.amount,
      );
      final paid = await PaymentSheet.show(
        context,
        title: 'Thanh toán phí gửi xe',
        link: link,
        verify: online.orderCode == null
            ? null
            : () async {
                final st = await repo.checkPaymentStatus(online.orderCode!);
                return st.isPaid ? PaymentCheck.paid : PaymentCheck.pending;
              },
      );
      if (paid && mounted) {
        showSnack(context, 'Đã thanh toán. Barie sẽ mở khi xe tới cổng ra.');
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _checkingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final status = StatusInfo.session(s.status);

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        Row(
          children: [
            PlateBadge(plate: s.licensePlateIn, fontSize: 18),
            const Spacer(),
            StatusTag.of(status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Gauge(
                label: s.isActive ? 'Đã đỗ' : 'Thời lượng',
                value: DateFormatter.clock(s.parkedDuration),
                size: 30,
              ),
            ),
            if (s.slotCode != null)
              Gauge(label: 'Vị trí', value: s.slotCode!, size: 22),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              InfoRow(label: 'Giờ vào', value: DateFormatter.formatDateTime(s.entryTime), mono: true),
              if (s.entryGateName != null) InfoRow(label: 'Cổng vào', value: s.entryGateName!),
              if (s.exitTime != null)
                InfoRow(label: 'Giờ ra', value: DateFormatter.formatDateTime(s.exitTime), mono: true),
              if (s.exitGateName != null) InfoRow(label: 'Cổng ra', value: s.exitGateName!),
              if (s.vehicleTypeName != null) InfoRow(label: 'Loại xe', value: s.vehicleTypeName!),
            ],
          ),
        ),
        if (s.isActive) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Phí tạm tính', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<AsyncCubit<FeePreviewModel>, AsyncState<FeePreviewModel>>(
            bloc: _fee,
            builder: (context, st) {
              final fee = st.data;
              if (fee == null) {
                return st.status == AsyncStatus.error
                    ? ErrorState(
                        title: 'Chưa tính được phí',
                        message: st.error ?? '',
                        onRetry: _fee!.load,
                      )
                    : const SkeletonCard(height: 150);
              }
              return _FeeBreakdown(fee: fee);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          if (s.ticket != null)
            FilledButton.icon(
              onPressed: () => TicketQr.present(
                context,
                payload: s.ticket!.qrPayload,
                title: 'Mã QR ra cổng',
                plate: s.licensePlateIn,
              ),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Mở mã QR ra cổng'),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _checkingPayment ? null : _openCheckout,
            icon: _checkingPayment
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payments_outlined),
            label: const Text('Thanh toán khi ra bãi'),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Thanh toán', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                InfoRow(
                  label: 'Số tiền',
                  value: s.paymentAmount == null ? '—' : CurrencyFormatter.format(s.paymentAmount!),
                  mono: true,
                ),
                if (s.paymentMethod != null) InfoRow(label: 'Phương thức', value: s.paymentMethod!),
                if (s.paymentStatus != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Trạng thái',
                              style: t.bodyMedium?.copyWith(color: p.textSecondary)),
                        ),
                        StatusTag.of(StatusInfo.payment(s.paymentStatus!)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => ReportIncidentSheet.show(context, sessionId: s.sessionId),
          icon: const Icon(Icons.report_gmailerrorred_rounded, size: 20),
          label: const Text('Báo sự cố cho lượt gửi này'),
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
        ),
      ],
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final FeePreviewModel fee;

  const _FeeBreakdown({required this.fee});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final extraHours = (fee.billedHours - fee.baseHours).clamp(0, 999);
    if (fee.isCoveredBySubscription) {
      return AppPanel(
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: p.ok),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text('Lượt gửi này nằm trong vé tháng, không phát sinh phí.',
                  style: t.bodyMedium),
            ),
          ],
        ),
      );
    }
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(
            label: 'Lượt đầu (${fee.baseHours} giờ)',
            value: CurrencyFormatter.format(fee.basePrice),
            mono: true,
          ),
          if (extraHours > 0)
            InfoRow(
              label: '$extraHours giờ tiếp theo',
              value: CurrencyFormatter.format(extraHours * fee.extraHourPrice),
              mono: true,
            ),
          if (fee.nightSurchargeCount > 0)
            InfoRow(
              label: 'Phụ thu qua đêm × ${fee.nightSurchargeCount}',
              value: CurrencyFormatter.format(fee.nightSurchargeCount * fee.nightSurcharge),
              mono: true,
            ),
          if (fee.depositAmount > 0)
            InfoRow(
              label: 'Đã đặt cọc',
              value: '−${CurrencyFormatter.format(fee.depositAmount)}',
              mono: true,
              valueColor: p.ok,
            ),
          Divider(color: p.line, height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('Cần trả nếu ra bây giờ', style: t.titleSmall)),
              Text(
                CurrencyFormatter.format(fee.amount),
                style: AppTypography.mono(size: 22, weight: FontWeight.w700, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tính theo ${fee.billedHours} giờ làm tròn từ ${fee.totalHours.toStringAsFixed(1)} giờ đỗ.',
              style: t.bodySmall),
        ],
      ),
    );
  }
}

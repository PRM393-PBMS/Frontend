import '../../../core/utils/settle.dart';
import '../../../core/l10n/locale_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/ticket_qr.dart';
import '../../payments/data/payment_models.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../reservations/data/reservation_repository.dart';
import '../data/session_repository.dart';
import 'session_widgets.dart';

class SessionDetailData extends Equatable {
  final ParkingSession session;
  final FeeBreakdown? fee;
  final Object? feeError;
  final CheckoutPaymentInfo? checkout;

  const SessionDetailData(
      {required this.session, this.fee, this.feeError, this.checkout});

  @override
  List<Object?> get props => [session, fee, feeError, checkout];
}

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final ParkingSession? initial;

  const SessionDetailScreen({super.key, required this.sessionId, this.initial});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final SessionRepository _repo = context.read<SessionRepository>();
  late final DataCubit<SessionDetailData> _cubit = DataCubit(_load)..load();
  bool _first = true;

  Future<SessionDetailData> _load() async {
    final notFound = context.l10n.sessNotFound;
    ParkingSession? session = _first ? widget.initial : null;
    _first = false;
    if (session == null) {
      final mine = await _repo.mine();
      for (final s in mine) {
        if (s.id == widget.sessionId) session = s;
      }
    }
    if (session == null) {
      throw NotFoundException(message: notFound);
    }
    if (!session.isActive) return SessionDetailData(session: session);

    final feeF = settle(_repo.myFeePreview(session.id));
    // Không có yêu cầu thanh toán checkout: hiển thị như phiên đang gửi bình thường.
    final checkoutF = settle(_repo.myCheckoutPayment(session.id));
    final fee = await feeF;
    final checkout = await checkoutF;
    return SessionDetailData(
        session: session,
        fee: fee.value,
        feeError: fee.error,
        checkout: checkout.value);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pay(CheckoutPaymentInfo info) async {
    final payment = info.payment!;
    final link = PaymentLink(
      paymentId: payment.id,
      paymentUrl: info.paymentUrl ?? '',
      orderCode: info.orderCode ?? payment.reference ?? '',
      amount: payment.amount,
    );
    final reservationRepo = context.read<ReservationRepository>();
    final paid = await PaymentSheet.show(
      context,
      title: context.l10n.sessPayTitle,
      description: context.l10n.sessPayDesc,
      link: link,
      checkStatus: () => reservationRepo.paymentStatus(link.orderCode),
    );
    if (paid && mounted) showAppSnack(context, context.l10n.sessPaid);
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.sessTitle)),
      body: LoadStateView<SessionDetailData>(
        cubit: _cubit,
        builder: (context, d) {
          final s = d.session;
          final checkout = d.checkout;
          final pendingPayment =
              checkout?.payment != null && checkout!.payment!.isPending;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EdgeRow(
                        leading: PlateTag(s.licensePlateIn, large: true),
                        trailing: StatusBadge(
                            StatusLabels.session(context.l10n, s.status))),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      s.isActive
                          ? context.l10n.homeParkedFor(
                              DateFormatter.formatDuration(
                                  context.l10n, s.elapsed))
                          : context.l10n.sessTotal(DateFormatter.formatDuration(
                              context.l10n, s.elapsed)),
                      style: AppTypography.title.copyWith(color: p.textPrimary),
                    ),
                    if (s.isActive && s.ticket != null && !pendingPayment) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: TicketQr(
                          payload: s.ticket!.qrPayload,
                          caption: context.l10n.sessShowAtExit,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (pendingPayment) ...[
                const SizedBox(height: AppSpacing.md),
                AppSurface(
                  color: p.warningSoft,
                  borderColor: p.warningSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.sessNeedPay,
                          style: AppTypography.label
                              .copyWith(color: p.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.sessNeedPayDetail(
                            CurrencyFormatter.format(checkout.payment!.amount),
                            StatusLabels.paymentMethod(
                                    context.l10n, checkout.payment!.method)
                                .toLowerCase()),
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textSecondary),
                      ),
                      if (checkout.payment!.isPayOS &&
                          checkout.paymentUrl != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: context.l10n.payWithPayOS,
                          icon: Icons.payments_outlined,
                          onPressed: () => _pay(checkout),
                        ),
                      ] else if (!checkout.payment!.isPayOS) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.l10n.sessPayCash,
                            style: AppTypography.caption
                                .copyWith(color: p.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
              if (d.fee != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppSurface(child: FeeBreakdownView(fee: d.fee!)),
              ] else if (d.feeError != null) ...[
                const SizedBox(height: AppSpacing.md),
                InlineMessage(errorText(d.feeError, context.l10n)),
              ],
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                child: Column(
                  children: [
                    KeyValueRow(
                        context.l10n.fieldVehicleType, s.vehicleTypeName),
                    KeyValueRow(context.l10n.sessEntry,
                        DateFormatter.formatDateTime(s.entryTime)),
                    KeyValueRow(context.l10n.sessEntryGate, s.entryGateName),
                    if (s.slotCode != null)
                      KeyValueRow(context.l10n.sessSpot, s.slotCode!),
                    if (s.exitTime != null)
                      KeyValueRow(context.l10n.sessExit,
                          DateFormatter.formatDateTime(s.exitTime)),
                    if (s.exitGateName != null)
                      KeyValueRow(context.l10n.sessExitGate, s.exitGateName!),
                    if (s.reservationId != null)
                      KeyValueRow(
                          context.l10n.sessMode, context.l10n.sessModeBooked),
                    if (!s.isActive && s.paymentAmount != null)
                      KeyValueRow(context.l10n.sessPaidAmount,
                          CurrencyFormatter.format(s.paymentAmount!),
                          emphasize: true),
                    if (!s.isActive && s.paymentMethod != null)
                      KeyValueRow(
                          context.l10n.sessMethod,
                          StatusLabels.paymentMethod(
                              context.l10n, s.paymentMethod)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.secondary(
                label: context.l10n.sessReport,
                icon: Icons.report_gmailerrorred_rounded,
                onPressed: () =>
                    context.push('${RouteNames.newIncident}?sessionId=${s.id}'),
              ),
            ],
          );
        },
      ),
    );
  }
}

import '../../../core/l10n/locale_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/data/catalog_models.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/presentation/session_widgets.dart';
import 'gate_selector.dart';

enum _Identify { ticket, plate }

/// Nhân viên cổng ra: xác định lượt gửi, tính phí, thu tiền mặt hoặc PayOS.
class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  late final SessionRepository _repo = context.read<SessionRepository>();

  GateItem? _gate;
  _Identify _identify = _Identify.ticket;
  String _method = 'Cash';
  String? _sessionId;
  String? _ticketLabel;
  bool _scanning = false;
  bool _submitting = false;
  String? _error;
  CheckoutResult? _result;
  Timer? _poll;

  @override
  void dispose() {
    _plate.dispose();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _scanTicket() async {
    final file =
        await ImageCapture.pick(context, title: context.l10n.coTicketPhoto);
    if (file == null) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final r = await _repo.decodeQrImage(file);
      if (!mounted) return;
      if (r.sessionId == null) {
        setState(() => _error = context.l10n.coNotActiveQr);
      } else {
        final session = await _repo.byId(r.sessionId!);
        if (!mounted) return;
        setState(() {
          _sessionId = session.id;
          _ticketLabel =
              '${session.licensePlateIn}, ${session.vehicleTypeName}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit() async {
    final gate = _gate;
    if (gate == null) {
      setState(() => _error = context.l10n.coPickGate);
      return;
    }
    if (_identify == _Identify.ticket && _sessionId == null) {
      setState(() => _error = context.l10n.coScanFirst);
      return;
    }
    if (_identify == _Identify.plate &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _repo.checkOut(
        gateId: gate.id,
        sessionId: _identify == _Identify.ticket ? _sessionId : null,
        licensePlate: _identify == _Identify.plate
            ? Validators.normalizePlate(_plate.text)
            : null,
        paymentMethod: _method,
      );
      if (!mounted) return;
      setState(() => _result = result);
      _startPolling(result);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPolling(CheckoutResult result) {
    _poll?.cancel();
    final payment = result.payment;
    if (payment == null || !payment.isPending || !payment.isPayOS) return;
    _poll = Timer.periodic(AppConfig.paymentPollInterval, (_) async {
      try {
        final status = await _repo.checkoutPaymentStatus(payment.id);
        if (!mounted) return;
        if (status.payment != null && !status.payment!.isPending) {
          _poll?.cancel();
          setState(() => _result = CheckoutResult(
                message: status.payment!.isSuccess
                    ? context.l10n.coPayOSReceived
                    : context.l10n.coPaymentCancelled,
                session: status.session,
                payment: status.payment,
                fee: _result?.fee,
              ));
        }
      } catch (_) {}
    });
  }

  Future<void> _confirmCash() async {
    final payment = _result?.payment;
    if (payment == null) return;
    setState(() => _submitting = true);
    try {
      final r = await _repo.confirmCash(payment.id);
      if (mounted) {
        setState(() => _result = CheckoutResult(
              message: r.message,
              session: r.session,
              payment: r.payment,
              fee: _result?.fee,
            ));
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel() async {
    final payment = _result?.payment;
    if (payment == null) return;
    final ok = await confirmAction(
      context,
      title: context.l10n.coCancelTitle,
      message: context.l10n.coCancelMessage,
      confirmLabel: context.l10n.coCancelAction,
      destructive: true,
    );
    if (!ok) return;
    setState(() => _submitting = true);
    try {
      await _repo.cancelCheckout(payment.id);
      _poll?.cancel();
      if (mounted) {
        showAppSnack(context, context.l10n.coCancelled);
        setState(() => _result = null);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    _poll?.cancel();
    setState(() {
      _result = null;
      _sessionId = null;
      _ticketLabel = null;
      _plate.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.coTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.sm, AppSpacing.page, 120),
        children: [
          ContentWidth(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _result != null
                  ? _buildResult(context, _result!)
                  : _buildForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final p = context.palette;
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GateSelector(entry: false, onChanged: (g) => _gate = g),
          const SizedBox(height: AppSpacing.xl),
          SegmentedButton<_Identify>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: _Identify.ticket,
                  label: Text(context.l10n.coByTicket)),
              ButtonSegment(
                  value: _Identify.plate, label: Text(context.l10n.coByPlate)),
            ],
            selected: {_identify},
            onSelectionChanged: (s) => setState(() {
              _identify = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_identify == _Identify.ticket)
            AppSurface(
              onTap: _scanning ? null : _scanTicket,
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: p.accent, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ticketLabel ?? context.l10n.coScanPrompt,
                            style: AppTypography.label
                                .copyWith(color: p.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                            _ticketLabel != null
                                ? context.l10n.coRescan
                                : context.l10n.coAutoFind,
                            style: AppTypography.caption
                                .copyWith(color: p.textSecondary)),
                      ],
                    ),
                  ),
                  if (_scanning)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            )
          else
            AppTextField(
              label: context.l10n.fieldPlate,
              controller: _plate,
              hint: '51H12345',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [PlateInputFormatter()],
              validator: (v) => Validators.plate(context.l10n, v),
              style: AppTypography.mono
                  .copyWith(fontSize: 20, color: p.textPrimary),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.coMethod,
              style: AppTypography.labelSmall.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: 'Cash',
                  label: Text(context.l10n.payMethodCash),
                  icon: const Icon(Icons.payments_outlined)),
              ButtonSegment(
                  value: 'PayOS',
                  label: const Text('PayOS'),
                  icon: const Icon(Icons.qr_code_2_rounded)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.coPassFree,
              style: AppTypography.caption.copyWith(color: p.textSecondary)),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InlineMessage(_error!),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
              label: context.l10n.coSubmit,
              icon: Icons.logout_rounded,
              loading: _submitting,
              onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, CheckoutResult r) {
    final p = context.palette;
    final payment = r.payment;
    final pending = payment != null && payment.isPending;
    final failed = payment != null && !payment.isPending && !payment.isSuccess;
    return Column(
      key: ValueKey('result-${payment?.id}-${payment?.status}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!pending)
          InlineMessage(
            failed ? context.l10n.coFailedNote : context.l10n.coDone,
            isError: failed,
          ),
        if (!pending) const SizedBox(height: AppSpacing.lg),
        if (r.session != null) ...[
          Row(
            children: [
              PlateTag(r.session!.licensePlateIn, large: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(r.session!.vehicleTypeName,
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (r.fee != null)
          AppSurface(
              child: FeeBreakdownView(
                  fee: r.fee!,
                  title: pending
                      ? context.l10n.coToCollect
                      : context.l10n.payTypeCheckout))
        else if (!pending)
          AppSurface(
            child: Text(context.l10n.coNoFee,
                style:
                    AppTypography.bodySmall.copyWith(color: p.textSecondary)),
          ),
        if (pending && payment.isPayOS && r.paymentUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppSurface(
            child: Column(
              children: [
                Text(
                    context.l10n
                        .coScanToPay(CurrencyFormatter.format(payment.amount)),
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: AppSpacing.control),
                  child: QrImageView(
                      data: r.paymentUrl!,
                      size: 200,
                      backgroundColor: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: p.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(context.l10n.coWaitingPayOS,
                        style: AppTypography.caption
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (pending && !payment.isPayOS)
          AppButton(
            label: context.l10n
                .coCashCollected(CurrencyFormatter.format(payment.amount)),
            icon: Icons.check_rounded,
            loading: _submitting,
            onPressed: _confirmCash,
          ),
        if (pending) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
              label: context.l10n.coCancelExit,
              onPressed: _submitting ? null : _cancel),
        ] else
          AppButton(
              label: context.l10n.coNext,
              icon: Icons.add_rounded,
              onPressed: _reset),
      ],
    );
  }
}

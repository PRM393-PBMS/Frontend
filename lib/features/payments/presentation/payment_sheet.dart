import '../../../core/l10n/locale_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../data/payment_models.dart';

enum _PayPhase { waiting, success, failed }

/// Sheet thanh toán PayOS: mở trang thanh toán, tự kiểm tra trạng thái định kỳ
/// (webhook PayOS cập nhật backend). Trả về `true` khi thanh toán thành công.
class PaymentSheet extends StatefulWidget {
  final String title;
  final String description;
  final PaymentLink link;
  final Future<String> Function() checkStatus;

  const PaymentSheet({
    super.key,
    required this.title,
    required this.description,
    required this.link,
    required this.checkStatus,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required PaymentLink link,
    required Future<String> Function() checkStatus,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentSheet(
        title: title,
        description: description,
        link: link,
        checkStatus: checkStatus,
      ),
    );
    return result ?? false;
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  Timer? _timer;
  _PayPhase _phase = _PayPhase.waiting;
  bool _checking = false;
  bool _opened = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        AppConfig.paymentPollInterval, (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.link.paymentUrl);
    if (uri == null) {
      setState(() => _error = context.l10n.payInvalidLink);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _opened = ok;
      _error = ok ? null : context.l10n.payCantOpen;
    });
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking || _phase != _PayPhase.waiting) return;
    setState(() {
      _checking = true;
      if (!silent) _error = null;
    });
    try {
      final status = (await widget.checkStatus()).toLowerCase();
      if (!mounted) return;
      if (status == 'success') {
        _timer?.cancel();
        setState(() => _phase = _PayPhase.success);
      } else if (status == 'failed' || status == 'cancelled') {
        _timer?.cancel();
        setState(() => _phase = _PayPhase.failed);
      } else if (!silent) {
        setState(() => _error = context.l10n.payNotYet);
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _error = errorText(e, context.l10n));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_phase) {
          _PayPhase.success => _Result(
              key: const ValueKey('ok'),
              icon: Icons.check_circle_rounded,
              color: p.success,
              title: context.l10n.paySuccessTitle,
              message: context.l10n.paySuccessMessage,
              onDone: () => Navigator.pop(context, true),
            ),
          _PayPhase.failed => _Result(
              key: const ValueKey('fail'),
              icon: Icons.cancel_rounded,
              color: p.danger,
              title: context.l10n.payFailedTitle,
              message: context.l10n.payFailedMessage,
              onDone: () => Navigator.pop(context, false),
            ),
          _PayPhase.waiting => Column(
              key: const ValueKey('wait'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: AppTypography.title.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.description,
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                Text(context.l10n.payAmount,
                    style:
                        AppTypography.labelSmall.copyWith(color: p.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Text(CurrencyFormatter.format(widget.link.amount),
                    style: AppTypography.figure.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                KeyValueRow(context.l10n.payOrderCode, widget.link.orderCode,
                    valueStyle: AppTypography.mono
                        .copyWith(fontSize: 13, color: p.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: p.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _opened
                            ? context.l10n.payWaiting
                            : context.l10n.payHint,
                        style: AppTypography.caption
                            .copyWith(color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineMessage(_error!),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _opened
                      ? context.l10n.payReopen
                      : context.l10n.payWithPayOS,
                  icon: Icons.open_in_new_rounded,
                  onPressed: _open,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: context.l10n.payCheckStatus,
                  loading: _checking,
                  onPressed: () => _check(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: AppButton.text(
                    label: context.l10n.payLater,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final VoidCallback onDone;

  const _Result({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        Icon(icon, color: color, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTypography.title.copyWith(color: p.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Text(message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: p.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: context.l10n.commonDone, onPressed: onDone),
      ],
    );
  }
}

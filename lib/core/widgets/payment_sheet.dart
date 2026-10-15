import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/pbms_models.dart';
import '../error/error_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';
import 'panels.dart';

/// Kết quả kiểm tra thanh toán do màn hình gọi cung cấp.
enum PaymentCheck { paid, pending }

/// Bảng thanh toán PayOS: mở trang thanh toán và kiểm tra kết quả.
/// Trả về `true` nếu đã xác nhận thanh toán thành công.
class PaymentSheet extends StatefulWidget {
  final String title;
  final PaymentLinkModel link;
  final Future<PaymentCheck> Function()? verify;

  const PaymentSheet({
    super.key,
    required this.title,
    required this.link,
    this.verify,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required PaymentLinkModel link,
    Future<PaymentCheck> Function()? verify,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentSheet(title: title, link: link, verify: verify),
    );
    return result ?? false;
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  bool _opened = false;
  bool _checking = false;
  String? _note;
  bool _noteIsError = false;

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.link.paymentUrl);
    if (uri == null) {
      setState(() {
        _note = 'Liên kết thanh toán không hợp lệ.';
        _noteIsError = true;
      });
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    setState(() {
      _opened = ok;
      _note = ok ? null : 'Không mở được trình duyệt. Hãy sao chép liên kết để thanh toán.';
      _noteIsError = !ok;
    });
  }

  Future<void> _check() async {
    final verify = widget.verify;
    if (verify == null) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _checking = true;
      _note = null;
    });
    try {
      final result = await verify();
      if (!mounted) return;
      if (result == PaymentCheck.paid) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _note = 'Chưa ghi nhận thanh toán. Hoàn tất trên trang PayOS rồi kiểm tra lại.';
        _noteIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _note = errorText(e);
        _noteIsError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final link = widget.link;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Thanh toán qua cổng PayOS (chuyển khoản QR, thẻ ATM).',
            style: t.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: AppSpacing.roundedLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số tiền', style: t.labelSmall),
                const SizedBox(height: 4),
                Text(
                  link.amount == null ? '—' : CurrencyFormatter.format(link.amount!),
                  style: AppTypography.mono(size: 30, weight: FontWeight.w700, color: p.text),
                ),
                const SizedBox(height: 6),
                if (link.orderCode != null)
                  InfoRow(label: 'Mã đơn', value: link.orderCode!, mono: true),
              ],
            ),
          ),
          if (_note != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _noteIsError ? Icons.error_outline_rounded : Icons.schedule_rounded,
                  size: 18,
                  color: _noteIsError ? p.danger : p.warn,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_note!, style: t.bodyMedium)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: link.hasUrl ? _open : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            label: Text(_opened ? 'Mở lại trang thanh toán' : 'Thanh toán với PayOS'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _checking ? null : _check,
            child: _checking
                ? const SizedBox.square(
                    dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.verify == null ? 'Để sau' : 'Tôi đã thanh toán, kiểm tra'),
          ),
          if (link.hasUrl)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link.paymentUrl));
                if (context.mounted) showSnack(context, 'Đã sao chép liên kết thanh toán');
              },
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Sao chép liên kết'),
            ),
        ],
      ),
    );
  }
}

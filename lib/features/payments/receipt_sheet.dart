import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Biên nhận của một thanh toán thành công: tải PDF, và gửi thông tin công ty để kế toán xuất hoá đơn GTGT.
class ReceiptSheet extends StatefulWidget {
  final PaymentModel payment;

  const ReceiptSheet({super.key, required this.payment});

  static Future<void> show(BuildContext context, PaymentModel payment) =>
      PbmsSheetFrame.show<void>(context, (_) => ReceiptSheet(payment: payment));

  /// Nạp ví không xuất hoá đơn: hoá đơn xuất theo từng lần dùng dịch vụ.
  static bool canInvoice(PaymentModel p) => (p.paymentType ?? '').toLowerCase() != 'wallettopup';

  /// Kiểm tra như máy chủ; trả lỗi hoặc null.
  static String? validateInvoice(String company, String taxCode, String address, String email) {
    if (company.trim().isEmpty || address.trim().isEmpty) return 'Nhập tên công ty và địa chỉ.';
    if (!RegExp(r'^\d{10}(-\d{3})?$').hasMatch(taxCode.trim())) {
      return 'Mã số thuế gồm 10 số, hoặc 10 số kèm -3 số chi nhánh.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) return 'Email nhận hoá đơn không hợp lệ.';
    return null;
  }

  @override
  State<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<ReceiptSheet> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  final _company = TextEditingController();
  final _taxCode = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  bool _opening = false;
  bool _sending = false;
  bool _showInvoice = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    for (final c in [_company, _taxCode, _address, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _openPdf() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final url = await _repo.getReceiptUrl(widget.payment.paymentId);
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) setState(() => _error = 'Không mở được trình duyệt để tải biên nhận.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _sendInvoice() async {
    final invalid = ReceiptSheet.validateInvoice(_company.text, _taxCode.text, _address.text, _email.text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _repo.requestInvoice(
        widget.payment.paymentId,
        companyName: _company.text.trim(),
        taxCode: _taxCode.text.trim(),
        address: _address.text.trim(),
        email: _email.text.trim(),
      );
      if (mounted) {
        setState(() {
          _done = 'Đã gửi yêu cầu. Hoá đơn điện tử sẽ được gửi tới ${_email.text.trim()} sau khi kế toán xuất.';
          _showInvoice = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? type, List<TextInputFormatter>? formatters, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PbmsText.label),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: type,
            inputFormatters: formatters,
            decoration: pbmsInputDecoration(hint: hint),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return PbmsSheetFrame(
      title: 'Biên nhận',
      subtitle: '${p.paymentTypeLabel ?? p.paymentType ?? 'Thanh toán'} · ${CurrencyFormatter.format(p.amount)}',
      children: [
        PbmsPrimaryButton(
          label: 'Tải biên nhận PDF',
          icon: Icons.download_rounded,
          busy: _opening,
          onPressed: _openPdf,
        ),
        const SizedBox(height: 6),
        const Text('Biên nhận không thay thế hoá đơn GTGT.', style: PbmsText.caption),
        if (ReceiptSheet.canInvoice(p)) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: PbmsTokens.divider),
          if (_done != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_done!, style: PbmsText.caption.copyWith(color: PbmsTokens.ok)),
            )
          else if (!_showInvoice)
            TextButton.icon(
              onPressed: () => setState(() => _showInvoice = true),
              icon: const Icon(Icons.business_rounded, size: 18),
              label: const Text('Yêu cầu xuất hoá đơn GTGT (hoá đơn đỏ)'),
              style: TextButton.styleFrom(foregroundColor: PbmsTokens.teal, minimumSize: const Size(48, 44)),
            )
          else ...[
            const SizedBox(height: 12),
            _field('Tên công ty', _company),
            _field('Mã số thuế', _taxCode,
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), LengthLimitingTextInputFormatter(14)],
                hint: '0312345678'),
            _field('Địa chỉ công ty', _address),
            _field('Email nhận hoá đơn', _email, type: TextInputType.emailAddress),
            PbmsPrimaryButton(label: 'Gửi yêu cầu xuất hoá đơn', busy: _sending, onPressed: _sendInvoice),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
      ],
    );
  }
}

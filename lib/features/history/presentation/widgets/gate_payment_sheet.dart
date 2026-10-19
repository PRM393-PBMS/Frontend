import 'dart:async';

import 'package:prm393_frontend/core/widgets/payos_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Thanh toán tại cổng ra: trạm thu phí tạo yêu cầu khi xe tới cổng.
/// - PayOS: hiện mã VietQR do trạm tạo để quét bằng app ngân hàng, tự kiểm tra kết quả.
/// - Tiền mặt: hướng dẫn trả cho nhân viên tại trạm.
class GatePaymentSheet extends StatefulWidget {
  final String sessionId;

  const GatePaymentSheet({super.key, required this.sessionId});

  /// Trả `true` nếu đã xác nhận thanh toán xong.
  static Future<bool?> show(BuildContext context, String sessionId) =>
      PbmsSheetFrame.show<bool>(context, (_) => GatePaymentSheet(sessionId: sessionId));

  @override
  State<GatePaymentSheet> createState() => _GatePaymentSheetState();
}

class _GatePaymentSheetState extends State<GatePaymentSheet> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  CheckoutPaymentModel? _checkout;
  bool _loading = true;
  bool _paid = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Khách quét mã bằng app ngân hàng khác: tự kiểm tra mỗi 4 giây.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await _repo.getCheckoutPayment(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _checkout = c;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check({bool silent = false}) async {
    final payment = _checkout?.payment;
    if (_paid || payment == null || _checkout?.online == null) {
      // Chưa có yêu cầu: tải lại để bắt kịp lúc trạm vừa tạo.
      if (!_paid && payment == null) await _load();
      return;
    }
    try {
      final ok = await _repo.checkPayment(payment.paymentId);
      if (!mounted) return;
      if (ok) {
        _poll?.cancel();
        setState(() => _paid = true);
      } else if (!silent) {
        showPbmsSnack(context, 'Chưa ghi nhận thanh toán. Quét mã rồi kiểm tra lại.');
      }
    } catch (e) {
      if (!silent && mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _checkout?.payment;
    final online = _checkout?.online;
    return PbmsSheetFrame(
      title: 'Thanh toán tại cổng ra',
      subtitle: 'Trạm thu phí tạo yêu cầu thanh toán khi xe tới cổng.',
      children: [
        if (_loading)
          const PbmsLoadingBox(height: 260)
        else if (_error != null)
          PbmsErrorView(title: 'Không tải được yêu cầu thanh toán', message: _error!, onRetry: _load)
        else if (_paid)
          _paidView()
        else if (payment == null)
          const PbmsEmptyView(
            icon: Icons.sensor_door_outlined,
            title: 'Chưa có yêu cầu thanh toán',
            message:
                'Khi xe tới cổng ra, trạm sẽ tạo mã thanh toán và mã sẽ hiện ở đây. Bạn cũng có thể trả tiền mặt cho nhân viên.',
          )
        else if (online == null)
          _cashView(payment)
        else
          _qrView(payment, online),
      ],
    );
  }

  Widget _amount(PaymentModel p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: PbmsTokens.tealTint,
          border: Border.all(color: PbmsTokens.tealLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Expanded(child: Text('Số tiền cần trả', style: PbmsText.caption)),
            Text(CurrencyFormatter.format(p.amount),
                style: PbmsText.figure(19, color: PbmsTokens.teal)),
          ],
        ),
      );

  Widget _qrView(PaymentModel p, PaymentLinkModel online) {
    final qr = online.qrCode;
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _amount(p),
        const SizedBox(height: 16),
        if (qr != null && qr.isNotEmpty) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: PbmsTokens.border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: qr,
                version: QrVersions.auto,
                size: (width - 120).clamp(180.0, 260.0),
                backgroundColor: Colors.white,
                semanticsLabel: 'Mã VietQR thanh toán phí gửi xe',
                eyeStyle: const QrEyeStyle(color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mã VietQR do trạm tạo. Quét bằng app ngân hàng bất kỳ; app sẽ tự báo khi trả xong.',
            textAlign: TextAlign.center,
            style: PbmsText.caption,
          ),
          const SizedBox(height: 14),
        ],
        if (online.hasUrl)
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await PayosCheckoutScreen.open(context, online.paymentUrl);
                // Trang PayOS đóng (trả xong, huỷ hoặc tự đóng): hỏi máy chủ ngay.
                if (mounted) await _check(silent: true);
              },
              icon: const Icon(Icons.lock_rounded, size: 19),
              label: const Text('Mở trang PayOS (thẻ, ví, ngân hàng)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PbmsTokens.teal,
                backgroundColor: PbmsTokens.tealTint,
                side: const BorderSide(color: PbmsTokens.tealLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        const SizedBox(height: 9),
        PbmsPrimaryButton(label: 'Tôi đã thanh toán, kiểm tra', onPressed: _check),
      ],
    );
  }

  Widget _cashView(PaymentModel p) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amount(p),
          const SizedBox(height: 14),
          const PbmsCard(
            child: Row(
              children: [
                Icon(Icons.payments_rounded, color: PbmsTokens.teal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trạm chọn thu tiền mặt. Trả cho nhân viên tại trạm, barie mở sau khi nhân viên xác nhận.',
                    style: PbmsText.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _paidView() => Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: PbmsTokens.tealTint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 36, color: PbmsTokens.teal),
          ),
          const SizedBox(height: 12),
          const Text('Đã thanh toán', style: PbmsText.title),
          const SizedBox(height: 4),
          const Text('Barie sẽ mở khi xe tới cổng ra.', style: PbmsText.caption),
          const SizedBox(height: 18),
          PbmsPrimaryButton(label: 'Xong', onPressed: () => Navigator.pop(context, true)),
        ],
      );
}

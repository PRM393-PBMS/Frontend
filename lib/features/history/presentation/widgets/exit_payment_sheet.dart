import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/wallet/presentation/screens/wallet_screen.dart';

enum _Method { wallet, payos, atGate }

/// Thanh toán để lấy xe. Trả về mã ra cổng nếu đã thanh toán trước thành công.
///
/// - Ví PBMS: trừ số dư ngay.
/// - Ngân hàng / thẻ: QR ngân hàng hoặc thẻ Visa, Mastercard, Napas trên trang PayOS.
/// - Tại cổng: tiền mặt hoặc quét mã do trạm thu phí tạo khi xe ra.
class ExitPaymentSheet extends StatefulWidget {
  final ParkingSessionModel session;
  final FeePreviewModel? fee;
  final VoidCallback onPayAtGate;

  const ExitPaymentSheet({
    super.key,
    required this.session,
    required this.fee,
    required this.onPayAtGate,
  });

  static Future<ExitPassModel?> show(
    BuildContext context, {
    required ParkingSessionModel session,
    FeePreviewModel? fee,
    required VoidCallback onPayAtGate,
  }) =>
      PbmsSheetFrame.show<ExitPassModel>(
        context,
        (_) => ExitPaymentSheet(session: session, fee: fee, onPayAtGate: onPayAtGate),
      );

  @override
  State<ExitPaymentSheet> createState() => _ExitPaymentSheetState();
}

class _ExitPaymentSheetState extends State<ExitPaymentSheet> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  _Method _method = _Method.wallet;
  double? _balance;
  bool _busy = false;
  String? _error;
  bool _needsTopUp = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final w = await _repo.getWallet();
      if (mounted) setState(() => _balance = w.balance);
    } catch (_) {
      // Không chặn: vẫn chọn được PayOS hoặc tại cổng.
    }
  }

  double? get _amount => widget.fee?.amount;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _needsTopUp = false;
    });
    try {
      switch (_method) {
        case _Method.atGate:
          Navigator.pop(context);
          widget.onPayAtGate();
          return;
        case _Method.wallet:
          final result = await _repo.prepaySession(widget.session.sessionId, 'Wallet');
          if (mounted) Navigator.pop(context, result.exitPass);
          return;
        case _Method.payos:
          final result = await _repo.prepaySession(widget.session.sessionId, 'PayOS');
          if (!mounted) return;
          if (result.exitPass != null) {
            Navigator.pop(context, result.exitPass);
            return;
          }
          final link = result.online;
          if (link == null) {
            setState(() => _error = 'Không tạo được liên kết thanh toán.');
            return;
          }
          ExitPassModel? pass;
          final paid = await PbmsPaymentSheet.show(
            context,
            title: 'Thanh toán để lấy xe',
            link: link,
            verify: () async {
              pass = (await _repo.getExitPass(widget.session.sessionId)).exitPass;
              return pass != null ? PaymentCheck.paid : PaymentCheck.pending;
            },
          );
          if (mounted && paid) Navigator.pop(context, pass);
          return;
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorText(e);
        _needsTopUp = e.statusCode == 402;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final balance = _balance;
    final walletShort = amount != null && balance != null && balance < amount;

    return PbmsSheetFrame(
      title: 'Thanh toán để lấy xe',
      subtitle: amount == null
          ? 'Chọn cách thanh toán phí gửi xe ${widget.session.licensePlateIn}.'
          : 'Phí hiện tại ${CurrencyFormatter.format(amount)}. Trả trước sẽ nhận mã ra cổng, '
              'mã dùng được tới khi xe ra, không tính thêm giờ.',
      children: [
        _option(
          _Method.wallet,
          Icons.account_balance_wallet_rounded,
          'Ví PBMS',
          balance == null
              ? 'Trừ trực tiếp từ số dư ví'
              : 'Số dư ${CurrencyFormatter.format(balance)}${walletShort ? ', không đủ' : ''}',
        ),
        const SizedBox(height: 8),
        _option(
          _Method.payos,
          Icons.credit_card_rounded,
          'Ngân hàng hoặc thẻ',
          'QR ngân hàng, thẻ Visa, Mastercard, Napas qua PayOS',
        ),
        const SizedBox(height: 8),
        _option(
          _Method.atGate,
          Icons.storefront_rounded,
          'Thanh toán tại cổng ra',
          'Tiền mặt hoặc quét mã do trạm thu phí tạo khi xe ra',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
          if (_needsTopUp)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await WalletScreen.open(context);
                  _loadBalance();
                },
                style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.teal, minimumSize: const Size(48, 44)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nạp tiền vào ví'),
              ),
            ),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(
          label: switch (_method) {
            _Method.wallet =>
              amount == null ? 'Thanh toán bằng ví' : 'Trả ${CurrencyFormatter.format(amount)} bằng ví',
            _Method.payos => 'Mở trang thanh toán',
            _Method.atGate => 'Xem yêu cầu tại cổng',
          },
          busy: _busy,
          onPressed: _method == _Method.wallet && walletShort ? null : _submit,
        ),
      ],
    );
  }

  Widget _option(_Method m, IconData icon, String title, String subtitle) {
    final selected = _method == m;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? PbmsTokens.tealTint : Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() {
            _method = m;
            _error = null;
          }),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? PbmsTokens.teal : PbmsTokens.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : PbmsTokens.surfaceLow,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: PbmsTokens.teal),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PbmsText.bodyStrong),
                      const SizedBox(height: 2),
                      Text(subtitle, style: PbmsText.caption),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected ? PbmsTokens.teal : PbmsTokens.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ mã ra cổng: mã chữ để đọc cho nhân viên + QR để quét.
class ExitPassCard extends StatelessWidget {
  final ExitPassModel pass;
  final String plate;
  final bool isMotorbike;

  const ExitPassCard({super.key, required this.pass, required this.plate, this.isMotorbike = false});

  void _showQr(BuildContext context) => PbmsQrDialog.show(
        context,
        title: 'Mã ra cổng',
        payload: pass.qrPayload,
        plate: plate,
        isMotorbike: isMotorbike,
        code: pass.code,
        rows: [
          if (pass.prepaidAt != null)
            (Icons.verified_rounded, 'Đã thanh toán', DateFormatter.formatDateTime(pass.prepaidAt)),
          (Icons.timer_outlined, 'Hiệu lực', 'Tới khi xe ra khỏi bãi'),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return PbmsTicketStub(
      onTap: () => _showQr(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PbmsPaidStamp(),
          const SizedBox(height: 12),
          const Text('Mã ra cổng', style: PbmsText.label),
          Text(pass.code, style: PbmsText.display(40).copyWith(letterSpacing: 6)),
        ],
      ),
      stub: PbmsPrimaryButton(
        label: 'Mở mã ra cổng',
        icon: Icons.qr_code_2_rounded,
        onPressed: () => _showQr(context),
      ),
    );
  }
}

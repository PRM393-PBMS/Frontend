import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';

/// Thanh toán một đơn vé tháng đang chờ: chọn (hoặc đổi) hình thức PayOS / Ví PBMS.
/// Trả 'PayOS' hoặc 'Wallet', null nếu khách đóng.
class PayPendingSheet extends StatefulWidget {
  final MonthlySubscriptionModel pass;

  const PayPendingSheet({super.key, required this.pass});

  static Future<String?> show(BuildContext context, MonthlySubscriptionModel pass) =>
      PbmsSheetFrame.show<String>(context, (_) => PayPendingSheet(pass: pass));

  @override
  State<PayPendingSheet> createState() => _PayPendingSheetState();
}

class _PayPendingSheetState extends State<PayPendingSheet> {
  String _method = 'PayOS';

  Widget _option(String value, IconData icon, String title, String subtitle) {
    final selected = _method == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? PbmsTokens.tealTint : Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() => _method = value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? PbmsTokens.teal : PbmsTokens.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(icon, color: PbmsTokens.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PbmsText.bodyStrong),
                      Text(subtitle, style: PbmsText.caption),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? PbmsTokens.teal : PbmsTokens.muted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pass;
    return PbmsSheetFrame(
      title: 'Thanh toán đơn vé tháng',
      subtitle: '${p.packageName}, xe ${p.licensePlate}',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: PbmsTokens.tealTint,
            border: Border.all(color: PbmsTokens.tealLine),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Expanded(child: Text('Số tiền', style: PbmsText.caption)),
              Text(CurrencyFormatter.format(p.price), style: PbmsText.figure(18, color: PbmsTokens.teal)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Hình thức thanh toán', style: PbmsText.label),
        const SizedBox(height: 6),
        _option('PayOS', Icons.qr_code_2_rounded, 'PayOS', 'Chuyển khoản QR ngân hàng, thẻ ATM / quốc tế'),
        _option('Wallet', Icons.account_balance_wallet_rounded, 'Ví PBMS', 'Trừ thẳng số dư ví, kích hoạt ngay'),
        const SizedBox(height: 4),
        const Text(
          'Đổi sang ví sẽ đóng link PayOS cũ của đơn này để không bị trả hai lần.',
          style: PbmsText.caption,
        ),
        const SizedBox(height: 16),
        PbmsPrimaryButton(
          label: _method == 'Wallet' ? 'Trả bằng ví' : 'Thanh toán với PayOS',
          icon: _method == 'Wallet' ? Icons.account_balance_wallet_rounded : Icons.lock_rounded,
          onPressed: () => Navigator.pop(context, _method),
        ),
      ],
    );
  }
}

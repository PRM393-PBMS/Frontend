import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../wallet/data/wallet_repository.dart';
import '../data/subscription_repository.dart';

/// Chọn PayOS hoặc Ví PBMS để thanh toán vé tháng. Trả về null nếu người dùng đóng sheet.
class PaymentMethodSheet extends StatefulWidget {
  final double amount;

  const PaymentMethodSheet({super.key, required this.amount});

  static Future<PassPaymentMethod?> show(BuildContext context, double amount) =>
      showModalBottomSheet<PassPaymentMethod>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => PaymentMethodSheet(amount: amount),
      );

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  late final DataCubit<Wallet> _wallet =
      DataCubit(context.read<WalletRepository>().ensure)..load();
  PassPaymentMethod _method = PassPaymentMethod.payos;

  @override
  void dispose() {
    _wallet.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
      child: BlocBuilder<DataCubit<Wallet>, LoadState<Wallet>>(
        bloc: _wallet,
        builder: (context, state) {
          final balance = state.data?.balance;
          final enough = balance != null && balance >= widget.amount;
          final String walletSubtitle;
          if (balance == null) {
            walletSubtitle =
                state.isFailure ? errorText(state.error, t) : t.commonLoading;
          } else if (enough) {
            walletSubtitle =
                t.payMethodWalletBalance(CurrencyFormatter.format(balance));
          } else {
            walletSubtitle = t.payMethodWalletShort(
                CurrencyFormatter.format(widget.amount - balance));
          }
          if (!enough && _method == PassPaymentMethod.wallet) {
            _method = PassPaymentMethod.payos;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.passPayChoose,
                  style: AppTypography.title.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              _MethodOption(
                icon: Icons.qr_code_2_rounded,
                title: t.payWithPayOS,
                subtitle: t.payMethodPayOSHint,
                selected: _method == PassPaymentMethod.payos,
                onTap: () => setState(() => _method = PassPaymentMethod.payos),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MethodOption(
                icon: Icons.account_balance_wallet_outlined,
                title: t.payMethodWallet,
                subtitle: walletSubtitle,
                selected: _method == PassPaymentMethod.wallet,
                warn: balance != null && !enough,
                onTap: enough
                    ? () => setState(() => _method = PassPaymentMethod.wallet)
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label:
                    t.passPayConfirm(CurrencyFormatter.format(widget.amount)),
                onPressed: () => Navigator.pop(context, _method),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool warn;
  final VoidCallback? onTap;

  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: AppSurface(
        onTap: onTap,
        color: selected ? p.accentSoft : null,
        borderColor: selected ? p.accent : null,
        child: Row(
          children: [
            Icon(icon, color: selected ? p.accent : p.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTypography.label.copyWith(color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.caption
                          .copyWith(color: warn ? p.warning : p.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? p.accent : p.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/titanium_card.dart';
import '../../payments/presentation/payment_sheet.dart';
import '../../reservations/data/reservation_repository.dart';
import '../data/wallet_repository.dart';

enum _TxFilter { all, topUps, spends }

/// Ví PBMS: số dư, nạp tiền qua PayOS và lịch sử giao dịch.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletRepository _repo = context.read<WalletRepository>();
  late final DataCubit<Wallet> _cubit = DataCubit(_repo.mine)..load();
  _TxFilter _filter = _TxFilter.all;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _topUp(Wallet wallet) async {
    final reservations = context.read<ReservationRepository>();
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TopUpSheet(),
    );
    if (amount == null || !mounted) return;
    try {
      final link = await _repo.topUp(wallet.id, amount);
      if (!mounted) return;
      final paid = await PaymentSheet.show(
        context,
        title: context.l10n.walletTopUpTitle,
        description: context.l10n.walletTopUpDesc,
        link: link,
        checkStatus: () => reservations.paymentStatus(link.orderCode),
      );
      if (paid && mounted) showAppSnack(context, context.l10n.walletToppedUp);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    }
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.walletTitle)),
      body: LoadStateView<Wallet>(
        cubit: _cubit,
        loading: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
                height: 150, radius: BorderRadius.all(Radius.circular(14))),
            SizedBox(height: AppSpacing.xl),
            SkeletonList(count: 3, itemHeight: 64),
          ],
        ),
        builder: (context, wallet) {
          final list = wallet.transactions.where((t) {
            switch (_filter) {
              case _TxFilter.all:
                return true;
              case _TxFilter.topUps:
                return t.isCredit;
              case _TxFilter.spends:
                return !t.isCredit;
            }
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitaniumCard(
                child: Builder(builder: (context) {
                  const dark = AppPalette.dark;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(context.l10n.walletBalance,
                              style: AppTypography.labelSmall
                                  .copyWith(color: dark.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(CurrencyFormatter.format(wallet.balance),
                            style: AppTypography.figure.copyWith(
                                color: dark.textPrimary, fontSize: 32)),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: context.l10n.walletTopUp,
                        icon: Icons.add_rounded,
                        onPressed: () => _topUp(wallet),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(context.l10n.walletHistory),
              SegmentedButton<_TxFilter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: _TxFilter.all,
                      label: Text(context.l10n.commonAll)),
                  ButtonSegment(
                      value: _TxFilter.topUps,
                      label: Text(context.l10n.walletFilterTopUps)),
                  ButtonSegment(
                      value: _TxFilter.spends,
                      label: Text(context.l10n.walletFilterSpends)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: context.l10n.walletEmptyTitle,
                  message: context.l10n.walletEmptyMessage,
                )
              else
                for (final t in list) _TxRow(tx: t),
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.walletPendingNote,
                  style: AppTypography.caption.copyWith(color: p.textMuted)),
            ],
          );
        },
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final WalletTransaction tx;

  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.l10n;
    final title = tx.isCredit
        ? t.walletTxTopUp
        : (tx.packageName != null
            ? t.walletTxSpend(tx.packageName!)
            : t.walletTxSpendGeneric);
    final color = tx.isCredit ? p.success : p.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tx.isCredit ? p.successSoft : p.surfaceMuted,
              borderRadius: AppSpacing.control,
            ),
            child: Icon(
              tx.isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: tx.isCredit ? p.success : p.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.label.copyWith(color: p.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormatter.formatDateTime(tx.createdAt),
                    if (tx.licensePlate != null) tx.licensePlate!,
                  ].join(', '),
                  style: AppTypography.caption.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                    t.walletBalanceAfter(
                        CurrencyFormatter.format(tx.balanceAfter)),
                    style: AppTypography.caption.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
              '${tx.isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.absoluteAmount)}',
              style: AppTypography.label.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _presets = [50000, 100000, 200000, 500000];
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));

  String? _validate(String? _) {
    final v = _value;
    if (v == null || v < WalletLimits.minTopUp || v > WalletLimits.maxTopUp) {
      return context.l10n.vAmountRange(
        CurrencyFormatter.format(WalletLimits.minTopUp),
        CurrencyFormatter.format(WalletLimits.maxTopUp),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.l10n;
    final value = _value;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.walletTopUpTitle,
                style: AppTypography.title.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(t.walletTopUpDesc,
                style:
                    AppTypography.bodySmall.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final v in _presets)
                  ChoiceChip(
                    label: Text(CurrencyFormatter.format(v)),
                    selected: value == v,
                    onSelected: (_) => setState(() => _amount.text = '$v'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: t.walletAmount,
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              helper: t.walletAmountHint(
                CurrencyFormatter.format(WalletLimits.minTopUp),
                CurrencyFormatter.format(WalletLimits.maxTopUp),
              ),
              validator: _validate,
              onChanged: (_) => setState(() {}),
              style: AppTypography.mono
                  .copyWith(color: p.textPrimary, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: value == null
                  ? t.walletTopUp
                  : t.walletTopUpSubmit(CurrencyFormatter.format(value)),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, _value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

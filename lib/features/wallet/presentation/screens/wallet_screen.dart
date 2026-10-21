import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Ví PBMS: nạp tiền qua PayOS (QR ngân hàng, thẻ Visa/Mastercard/Napas),
/// dùng số dư để thanh toán phí gửi xe trước khi ra bãi.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const WalletScreen()));

  /// Mở từ nút Ví ở giữa thanh dưới: trang trồi lên và nở ra từ đáy giữa màn hình.
  static Route<void> riseRoute() => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => const WalletScreen(),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
              child: ScaleTransition(
                alignment: Alignment.bottomCenter,
                scale: Tween(begin: 0.92, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      );

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _filters = [
    (Icons.list_alt_rounded, 'Tất cả', WalletHistoryFilter.all),
    (Icons.south_west_rounded, 'Nạp', WalletHistoryFilter.topUps),
    (Icons.north_east_rounded, 'Chi', WalletHistoryFilter.spends),
  ];

  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _wallet = AsyncCubit(_repo.getWallet);
  int _filter = 0;
  late final _history = AsyncCubit(() => _repo.getWalletHistory(_filters[_filter].$3));

  @override
  void dispose() {
    _wallet.close();
    _history.close();
    super.dispose();
  }

  void _reload() {
    _wallet.load();
    _history.load();
  }

  Future<void> _topUp(WalletModel wallet) async {
    final topped = await TopUpSheet.show(context, wallet);
    _reload();
    if (topped == true && mounted) {
      showPbmsSnack(context, 'Đã nạp tiền vào ví.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Ví PBMS',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: PbmsTokens.teal,
        onRefresh: () async => _reload(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 14, 16, 32 + bottomInset),
              children: [
                PbmsAsync<WalletModel>(
                  cubit: _wallet,
                  loadingHeight: 180,
                  errorTitle: 'Không tải được ví',
                  builder: (w) => _BalanceCard(wallet: w, onTopUp: () => _topUp(w)),
                ),
                const SizedBox(height: 22),
                const PbmsSectionTitle('Lịch sử giao dịch'),
                PbmsSegmentedTabs(
                  tabs: [for (final f in _filters) (f.$1, f.$2)],
                  selected: _filter,
                  onChanged: (i) {
                    if (i == _filter) return;
                    setState(() => _filter = i);
                    _history.load();
                  },
                ),
                const SizedBox(height: 12),
                PbmsAsync<List<WalletTransactionModel>>(
                  cubit: _history,
                  loadingHeight: 220,
                  errorTitle: 'Chưa tải được lịch sử giao dịch',
                  isEmpty: (d) => d.isEmpty,
                  empty: PbmsEmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: switch (_filters[_filter].$3) {
                      WalletHistoryFilter.topUps => 'Chưa có lần nạp nào',
                      WalletHistoryFilter.spends => 'Chưa chi tiêu từ ví',
                      WalletHistoryFilter.all => 'Chưa có giao dịch',
                    },
                  ),
                  builder: (items) => PbmsCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: PbmsTokens.divider),
                          _TransactionRow(tx: items[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onTopUp;

  const _BalanceCard({required this.wallet, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số dư khả dụng', style: PbmsText.label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(CurrencyFormatter.format(wallet.balance), style: PbmsText.display(48)),
          ),
          const SizedBox(height: 16),
          PbmsPrimaryButton(label: 'Nạp tiền', icon: Icons.add_rounded, onPressed: onTopUp),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final WalletTransactionModel tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final inbound = tx.isTopUp;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: inbound ? PbmsTokens.tealTint : PbmsTokens.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              inbound ? Icons.south_west_rounded : Icons.local_parking_rounded,
              size: 19,
              color: inbound ? PbmsTokens.teal : PbmsTokens.muted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description ?? (inbound ? 'Nạp tiền' : 'Thanh toán'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PbmsText.bodyStrong),
                const SizedBox(height: 2),
                Text(DateFormatter.formatDateTime(tx.createdAt),
                    style: PbmsText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${inbound ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: PbmsText.figure(14,
                    color: inbound ? PbmsTokens.ok : PbmsTokens.ink),
              ),
              const SizedBox(height: 2),
              Text('Còn ${CurrencyFormatter.format(tx.balanceAfter)}',
                  style: PbmsText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nạp ví: chọn số tiền rồi thanh toán trên trang PayOS.
class TopUpSheet extends StatefulWidget {
  final WalletModel wallet;

  const TopUpSheet({super.key, required this.wallet});

  /// Trả `true` nếu PayOS đã xác nhận lệnh nạp.
  static Future<bool?> show(BuildContext context, WalletModel wallet) =>
      PbmsSheetFrame.show<bool>(context, (_) => TopUpSheet(wallet: wallet));

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  static const _presets = [50000, 100000, 200000, 500000];
  final _amount = TextEditingController(text: '100000');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text) ?? 0;

  Future<void> _submit() async {
    final min = widget.wallet.topUpMin, max = widget.wallet.topUpMax;
    if (_value < min || _value > max) {
      setState(() => _error =
          'Nhập từ ${CurrencyFormatter.format(min)} đến ${CurrencyFormatter.format(max)}.');
      return;
    }
    final repo = context.read<PbmsRepository>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await repo.topUpWallet(_value);
      if (!mounted) return;
      final paid = await PbmsPaymentSheet.show(
        context,
        title: 'Nạp ví PBMS',
        link: link,
        verify: link.paymentId == null
            ? null
            : () async => await repo.checkTopUp(link.paymentId!)
                ? PaymentCheck.paid
                : PaymentCheck.pending,
      );
      if (mounted) Navigator.pop(context, paid);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Nạp tiền vào ví',
      subtitle:
          'Thanh toán qua PayOS bằng QR ngân hàng hoặc thẻ Visa, Mastercard, Napas.',
      children: [
        const Text('Số tiền', style: PbmsText.label),
        const SizedBox(height: 6),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: PbmsText.figure(18),
          decoration: pbmsInputDecoration().copyWith(suffixText: 'đ'),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text(CurrencyFormatter.format(p)),
                selected: _value == p,
                selectedColor: PbmsTokens.tealTint,
                showCheckmark: false,
                side: BorderSide(
                    color: _value == p ? PbmsTokens.teal : PbmsTokens.border),
                onSelected: (_) => setState(() {
                  _amount.text = '$p';
                  _error = null;
                }),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(
          label: 'Tiếp tục thanh toán',
          busy: _busy,
          onPressed: _value > 0 ? _submit : null,
        ),
      ],
    );
  }
}

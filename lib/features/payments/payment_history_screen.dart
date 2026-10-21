import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Lịch sử thanh toán của tôi: tiền cọc, phí gửi xe, vé tháng, gia hạn, nạp ví.
/// Tải từng trang 20 dòng, kéo tới cuối danh sách thì tải tiếp.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  static const _filters = [
    (Icons.list_alt_rounded, 'Tất cả', null),
    (Icons.check_circle_outline_rounded, 'Thành công', 'Success'),
    (Icons.hourglass_empty_rounded, 'Đang chờ', 'Pending'),
  ];

  late final PbmsRepository _repo = context.read<PbmsRepository>();
  final _items = <PaymentModel>[];
  int _filter = 0;
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  /// Mỗi lần đổi bộ lọc/làm mới tăng số này, kết quả cũ về muộn bị bỏ qua.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.getMyPayments(page: _page + 1, status: _filters[_filter].$3);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = errorText(e));
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
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
        title: const Text('Lịch sử thanh toán',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: PbmsTokens.teal,
        onRefresh: _reload,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 240) _loadMore();
            return false;
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 32 + bottomInset),
                children: [
                  PbmsSegmentedTabs(
                    tabs: [for (final f in _filters) (f.$1, f.$2)],
                    selected: _filter,
                    onChanged: (i) {
                      if (i == _filter) return;
                      setState(() => _filter = i);
                      _reload();
                    },
                  ),
                  const SizedBox(height: 14),
                  ..._content(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    if (_items.isEmpty && _loading) {
      return const [PbmsLoadingBox(height: 260)];
    }
    if (_items.isEmpty && _error != null) {
      return [PbmsErrorView(title: 'Không tải được lịch sử thanh toán', message: _error!, onRetry: _reload)];
    }
    if (_items.isEmpty) {
      return const [
        PbmsEmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'Chưa có thanh toán nào',
          message: 'Tiền cọc, phí gửi xe, vé tháng và nạp ví sẽ hiện ở đây.',
        ),
      ];
    }
    return [
      PbmsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: PbmsTokens.divider),
              PaymentRow(payment: _items[i]),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox.square(
                dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: PbmsTokens.teal)),
          ),
        )
      else if (_error != null)
        TextButton(onPressed: _loadMore, child: Text('$_error Thử lại'))
      else if (!_hasMore)
        const Center(child: Text('Đã hiện toàn bộ thanh toán', style: PbmsText.caption)),
    ];
  }
}

/// Một dòng thanh toán: loại, biển số/gói, thời gian, số tiền và trạng thái.
class PaymentRow extends StatelessWidget {
  final PaymentModel payment;

  const PaymentRow({super.key, required this.payment});

  static String methodLabel(String method) => switch (method.toLowerCase()) {
        'wallet' => 'Ví PBMS',
        'cash' => 'Tiền mặt',
        'payos' => 'Chuyển khoản/thẻ',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final detail = [
      p.packageName ?? p.licensePlate,
      methodLabel(p.paymentMethod),
    ].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.paymentTypeLabel ?? p.paymentType ?? 'Thanh toán',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.bodyStrong),
                const SizedBox(height: 2),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: PbmsText.caption),
                if (p.paymentTime != null)
                  Text(DateFormatter.formatDateTime(p.paymentTime), style: PbmsText.caption),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.format(p.amount), style: PbmsText.figure(14, color: PbmsTokens.ink)),
              const SizedBox(height: 4),
              PbmsStatusPill(StatusInfo.payment(p.paymentStatus)),
            ],
          ),
        ],
      ),
    );
  }
}

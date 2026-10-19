import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Trang kết quả thanh toán PayOS trong app.
///
/// - Trên điện thoại: mở ngay sau khi trang PayOS (WebView) đóng.
/// - Bản web: PayOS chuyển thẳng về /payment/success hoặc /payment/cancel của app.
/// Có [orderCode] thì hỏi máy chủ (/payment/result) để lấy trạng thái thật, không tin URL.
class PaymentResultScreen extends StatefulWidget {
  final PaymentResultState initialState;
  final String? orderCode;
  final double? amount;
  final String? typeLabel;

  /// Cho phép thanh toán lại (đóng trang, quay về bước thanh toán).
  final bool canRetry;

  const PaymentResultScreen({
    super.key,
    required this.initialState,
    this.orderCode,
    this.amount,
    this.typeLabel,
    this.canRetry = false,
  });

  /// Từ URL PayOS chuyển về: /payment/success?orderCode=..&status=PAID&cancel=false.
  factory PaymentResultScreen.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final cancelled = uri.path.contains('cancel') || q['cancel'] == 'true' || q['status']?.toUpperCase() == 'CANCELLED';
    return PaymentResultScreen(
      initialState: cancelled ? PaymentResultState.cancelled : PaymentResultState.pending,
      orderCode: q['orderCode'],
    );
  }

  static Future<void> open(
    BuildContext context, {
    required PaymentResultState state,
    String? orderCode,
    double? amount,
    String? typeLabel,
    bool canRetry = false,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymentResultScreen(
          initialState: state,
          orderCode: orderCode,
          amount: amount,
          typeLabel: typeLabel,
          canRetry: canRetry,
        ),
      ));

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  late PaymentResultState _state = widget.initialState;
  late double? _amount = widget.amount;
  late String? _typeLabel = widget.typeLabel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderCode != null) _refresh();
  }

  Future<void> _refresh() async {
    final code = widget.orderCode;
    if (code == null) return;
    setState(() => _loading = true);
    final r = await context
        .read<PbmsRepository>()
        .getPaymentResult(code, cancelled: widget.initialState == PaymentResultState.cancelled);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r != null) {
        _state = r.state;
        _amount = r.amount ?? _amount;
        _typeLabel = r.typeLabel ?? _typeLabel;
      }
    });
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Bản web mở thẳng từ PayOS: không có trang trước, về trang chủ.
      context.go(RouteNames.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, body) = switch (_state) {
      PaymentResultState.success => (
          Icons.check_rounded,
          PbmsTokens.ok,
          'Thanh toán thành công',
          'PBMS đã nhận tiền. Vé, mã ra cổng hoặc số dư ví đã được cập nhật.',
        ),
      PaymentResultState.pending => (
          Icons.hourglass_top_rounded,
          PbmsTokens.warn,
          'Đang chờ xác nhận',
          'Ngân hàng chưa báo kết quả. Trạng thái sẽ tự cập nhật sau ít phút.',
        ),
      PaymentResultState.cancelled => (
          Icons.close_rounded,
          PbmsTokens.muted,
          'Đã huỷ thanh toán',
          'Bạn chưa bị trừ tiền. Có thể thanh toán lại bất cứ lúc nào.',
        ),
      PaymentResultState.failed => (
          Icons.priority_high_rounded,
          PbmsTokens.danger,
          'Thanh toán không thành công',
          'Giao dịch hết hạn hoặc bị từ chối. Bạn chưa bị trừ tiền.',
        ),
      PaymentResultState.unknown => (
          Icons.help_outline_rounded,
          PbmsTokens.muted,
          'Không tìm thấy giao dịch',
          'Kiểm tra lại thanh toán trong mục Lịch sử hoặc Ví.',
        ),
    };
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Kết quả thanh toán',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PbmsTokens.ink)),
        actions: [
          IconButton(tooltip: 'Đóng', onPressed: _close, icon: const Icon(Icons.close_rounded)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
            children: [
              Semantics(
                liveRegion: true,
                label: title,
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(icon, color: color, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(_loading ? 'Đang kiểm tra thanh toán...' : title,
                  textAlign: TextAlign.center, style: PbmsText.headline),
              const SizedBox(height: 8),
              if (!_loading) Text(body, textAlign: TextAlign.center, style: PbmsText.caption.copyWith(fontSize: 14)),
              const SizedBox(height: 22),
              if (_typeLabel != null || _amount != null || widget.orderCode != null)
                PbmsCard(
                  child: Column(
                    children: [
                      if (_typeLabel != null) PbmsDetailRow(label: 'Nội dung', value: _typeLabel!),
                      if (_amount != null) PbmsDetailRow(label: 'Số tiền', value: CurrencyFormatter.format(_amount!)),
                      if (widget.orderCode != null) PbmsDetailRow(label: 'Mã đơn hàng', value: widget.orderCode!),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              if (_state == PaymentResultState.pending && widget.orderCode != null) ...[
                OutlinedButton.icon(
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kiểm tra lại'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: PbmsTokens.teal,
                    side: const BorderSide(color: PbmsTokens.tealLine),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              PbmsPrimaryButton(
                label: widget.canRetry &&
                        (_state == PaymentResultState.cancelled || _state == PaymentResultState.failed)
                    ? 'Thanh toán lại'
                    : 'Xong',
                onPressed: _close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

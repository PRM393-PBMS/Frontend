import 'package:prm393_frontend/core/widgets/payos_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/pbms_models.dart';
import '../error/error_text.dart';
import '../state/async_cubit.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Bảng màu dùng chung cho các màn hình khách hàng (giữ thiết kế gốc).
class PbmsTokens {
  PbmsTokens._();

  static const teal = AppColors.brand;
  static const tealTint = AppColors.brandTint;
  static const tealLine = Color(0xFF97DFEB);
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const surfaceLow = Color(0xFFF8FAFC);
  static const divider = Color(0xFFF1F5F9);

  // Màu trạng thái đủ tương phản (>= 4.5:1) khi dùng làm chữ trên nền trắng.
  static const ok = Color(0xFF047857);
  static const warn = Color(0xFFB45309);
  static const danger = Color(0xFFDC2626);
}

/// Thang chữ cố định (sp) cho màn hình thao tác: bước nhỏ, không dưới 12sp.
class PbmsText {
  PbmsText._();

  static const headline = TextStyle(
      fontSize: 22, height: 1.2, fontWeight: FontWeight.w700, color: PbmsTokens.ink);
  static const title = TextStyle(
      fontSize: 17, height: 1.25, fontWeight: FontWeight.w700, color: PbmsTokens.ink);
  static const section = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, color: PbmsTokens.ink);
  static const body = TextStyle(fontSize: 14, height: 1.4, color: PbmsTokens.ink);
  static const bodyStrong = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600, color: PbmsTokens.ink);
  static const caption =
      TextStyle(fontSize: 12, height: 1.35, color: PbmsTokens.muted);
  static const label = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: PbmsTokens.muted);

  /// Số liệu: chữ số đều độ rộng để không nhảy khi cập nhật.
  static TextStyle figure(double size, {Color color = PbmsTokens.ink}) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
      fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Thẻ trắng viền mảnh, bo 16, khối giao diện cơ bản.
class PbmsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  const PbmsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.color = Colors.white,
    this.borderColor = PbmsTokens.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      // ListTile / InkWell bên trong vẽ hiệu ứng chạm lên nền thẻ, không bị nền trắng che.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Tiêu đề mục: "Gợi ý bãi gần nhất · Còn chỗ".
class PbmsSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const PbmsSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: PbmsText.section),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Nhãn trạng thái dạng viên thuốc có chấm màu.
class PbmsStatusPill extends StatelessWidget {
  final StatusInfo info;

  const PbmsStatusPill(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = info.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 5),
          Text(info.label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Ánh xạ trạng thái backend → nhãn tiếng Việt + màu.
class StatusInfo {
  final String label;
  final Color color;

  const StatusInfo(this.label, this.color);

  static const _neutral = PbmsTokens.muted;
  static const _accent = PbmsTokens.teal;
  static const _ok = PbmsTokens.ok;
  static const _warn = PbmsTokens.warn;
  static const _danger = PbmsTokens.danger;

  static String _k(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  static StatusInfo session(String s) => switch (_k(s)) {
        'active' => const StatusInfo('Đang gửi', _accent),
        'completed' => const StatusInfo('Đã ra bãi', _neutral),
        'cancelled' => const StatusInfo('Đã huỷ', _danger),
        'exception' => const StatusInfo('Cần bãi xử lý', _warn),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo reservation(String s) => switch (_k(s)) {
        'pending' => const StatusInfo('Chờ đặt cọc', _warn),
        'confirmed' => const StatusInfo('Đã xác nhận', _ok),
        'modified' => const StatusInfo('Đã đổi giờ', _ok),
        'checkedin' => const StatusInfo('Đã vào bãi', _accent),
        'completed' => const StatusInfo('Hoàn tất', _neutral),
        'cancelled' => const StatusInfo('Đã huỷ', _danger),
        'noshow' => const StatusInfo('Không đến', _danger),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo subscription(String s) => switch (_k(s)) {
        'active' => const StatusInfo('Kích hoạt', _ok),
        'pendingpayment' || 'pending' =>
          const StatusInfo('Chờ thanh toán', _warn),
        'expired' => const StatusInfo('Đã hết hạn', _neutral),
        'cancelled' => const StatusInfo('Đã huỷ', _danger),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo payment(String s) => switch (_k(s)) {
        'success' || 'paid' => const StatusInfo('Đã thanh toán', _ok),
        'pending' => const StatusInfo('Chờ thanh toán', _warn),
        'cancelled' => const StatusInfo('Đã huỷ', _neutral),
        'failed' => const StatusInfo('Thất bại', _danger),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo vehicleChange(String s) => switch (_k(s)) {
        'pending' => const StatusInfo('Chờ duyệt', _warn),
        'approved' => const StatusInfo('Đã duyệt', _ok),
        'rejected' => const StatusInfo('Bị từ chối', _danger),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo contract(String s) => switch (_k(s)) {
        'pendingsignature' => const StatusInfo('Chờ ký', _warn),
        'signed' => const StatusInfo('Đã ký', _ok),
        'void' => const StatusInfo('Đã huỷ', _neutral),
        _ => StatusInfo(s, _neutral),
      };

  static StatusInfo incident(String s) => switch (_k(s)) {
        'open' => const StatusInfo('Đã tiếp nhận', _warn),
        'assigned' || 'inprogress' => const StatusInfo('Đang xử lý', _accent),
        'resolved' => const StatusInfo('Đã xử lý', _ok),
        'closed' => const StatusInfo('Đã đóng', _neutral),
        'cancelled' => const StatusInfo('Đã huỷ', _neutral),
        _ => StatusInfo(s, _neutral),
      };
}

/// Thông báo nổi phía trên thanh điều hướng.
void showPbmsSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? PbmsTokens.danger : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      ),
    );
}

/// Khối skeleton nhấp nháy nhẹ, giữ đúng chiều cao nội dung sắp hiện.
class PbmsLoadingBox extends StatefulWidget {
  final double height;

  const PbmsLoadingBox({super.key, this.height = 96});

  @override
  State<PbmsLoadingBox> createState() => _PbmsLoadingBoxState();
}

class _PbmsLoadingBoxState extends State<PbmsLoadingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final box = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: PbmsTokens.divider,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Semantics(
      label: 'Đang tải',
      child: reduceMotion
          ? box
          : FadeTransition(
              opacity: Tween(begin: 1.0, end: 0.55).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: box,
            ),
    );
  }
}

class PbmsErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const PbmsErrorView({
    super.key,
    this.title = 'Không tải được dữ liệu',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PbmsTokens.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 20, color: PbmsTokens.danger),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PbmsText.bodyStrong),
                const SizedBox(height: 3),
                Text(message, style: PbmsText.caption),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: PbmsTokens.teal),
              child: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }
}

class PbmsEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const PbmsEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: PbmsTokens.tealTint, shape: BoxShape.circle),
            child: Icon(icon, color: PbmsTokens.teal, size: 24),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: PbmsText.bodyStrong),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, textAlign: TextAlign.center, style: PbmsText.caption),
          ],
          if (action != null) ...[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Dựng một phần giao diện theo trạng thái của [AsyncCubit].
class PbmsAsync<T> extends StatelessWidget {
  final AsyncCubit<T> cubit;
  final Widget Function(T data) builder;
  final double loadingHeight;
  final String errorTitle;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  const PbmsAsync({
    super.key,
    required this.cubit,
    required this.builder,
    this.loadingHeight = 96,
    this.errorTitle = 'Không tải được dữ liệu',
    this.isEmpty,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AsyncCubit<T>, AsyncState<T>>(
      bloc: cubit,
      builder: (context, st) {
        final data = st.data;
        if (data == null) {
          if (st.status == AsyncStatus.error) {
            return PbmsErrorView(
              title: errorTitle,
              message: st.error ?? '',
              onRetry: cubit.load,
            );
          }
          return PbmsLoadingBox(height: loadingHeight);
        }
        if (isEmpty != null && empty != null && isEmpty!(data)) return empty!;
        return builder(data);
      },
    );
  }
}

/// Hộp thoại mã QR ra/vào cổng (payload do backend cấp).
class PbmsQrDialog {
  PbmsQrDialog._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String payload,
    String? headline,
    List<(IconData, String, String)> rows = const [],
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final qrSize =
            (MediaQuery.sizeOf(dialogContext).width - 104).clamp(180.0, 252.0);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 390,
              maxHeight: MediaQuery.sizeOf(dialogContext).height - 48,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PbmsTokens.ink)),
                      ),
                      IconButton(
                        tooltip: 'Đóng mã QR',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (headline != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: PbmsTokens.tealTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_rounded,
                              size: 17, color: PbmsTokens.teal),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: PbmsTokens.ink)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: PbmsTokens.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        size: qrSize,
                        backgroundColor: Colors.white,
                        semanticsLabel: title,
                        eyeStyle: const QrEyeStyle(color: Colors.black),
                        dataModuleStyle:
                            const QrDataModuleStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 4),
                      decoration: BoxDecoration(
                        color: PbmsTokens.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PbmsTokens.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  height: 1, color: PbmsTokens.border),
                            PbmsDetailRow(
                                icon: rows[i].$1,
                                label: rows[i].$2,
                                value: rows[i].$3),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dòng "icon · nhãn ........ giá trị".
class PbmsDetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color valueColor;

  const PbmsDetailRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor = PbmsTokens.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: PbmsTokens.teal),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: PbmsTokens.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

/// Kết quả kiểm tra thanh toán do màn hình gọi cung cấp.
enum PaymentCheck { paid, pending }

/// Bảng thanh toán PayOS: mở trang thanh toán và kiểm tra kết quả.
/// Trả về `true` nếu đã xác nhận thanh toán thành công.
class PbmsPaymentSheet extends StatefulWidget {
  final String title;
  final PaymentLinkModel link;
  final Future<PaymentCheck> Function()? verify;

  const PbmsPaymentSheet({
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PbmsPaymentSheet(title: title, link: link, verify: verify),
    );
    return result ?? false;
  }

  @override
  State<PbmsPaymentSheet> createState() => _PbmsPaymentSheetState();
}

class _PbmsPaymentSheetState extends State<PbmsPaymentSheet> {
  bool _opened = false;
  bool _checking = false;
  String? _note;
  bool _noteIsError = false;

  /// Mở trang PayOS trong app; PayOS chuyển về returnUrl / cancelUrl thì app
  /// đóng trang và hỏi máy chủ trạng thái thật.
  Future<void> _open() async {
    if (Uri.tryParse(widget.link.paymentUrl)?.hasScheme != true) {
      setState(() {
        _note = 'Liên kết thanh toán không hợp lệ.';
        _noteIsError = true;
      });
      return;
    }
    final outcome = await PayosCheckoutScreen.open(context, widget.link.paymentUrl);
    if (!mounted) return;
    setState(() => _opened = true);
    if (outcome?.cancelled == true) {
      // Vẫn hỏi máy chủ để thanh toán được ghi nhận là đã huỷ.
      await _check(silent: true);
      if (!mounted) return;
      setState(() {
        _note = 'Bạn đã huỷ thanh toán, chưa bị trừ tiền. Có thể thanh toán lại.';
        _noteIsError = false;
      });
      return;
    }
    await _check();
  }

  Future<void> _check({bool silent = false}) async {
    final verify = widget.verify;
    if (verify == null) {
      if (!silent) Navigator.pop(context, false);
      return;
    }
    if (silent) {
      try {
        if (await verify() == PaymentCheck.paid && mounted) Navigator.pop(context, true);
      } catch (_) {}
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
        _note =
            'Chưa ghi nhận thanh toán. Hoàn tất trên trang PayOS rồi kiểm tra lại.';
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
    final link = widget.link;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: PbmsTokens.border,
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 18),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PbmsTokens.ink)),
            const SizedBox(height: 4),
            const Text('Thanh toán qua cổng PayOS (chuyển khoản QR, thẻ ATM).',
                style: PbmsText.caption),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: PbmsTokens.tealTint,
                border: Border.all(color: PbmsTokens.tealLine),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Số tiền cần thanh toán',
                        style:
                            TextStyle(fontSize: 12, color: PbmsTokens.muted)),
                  ),
                  Text(
                    link.amount == null
                        ? 'Chưa rõ'
                        : CurrencyFormatter.format(link.amount!),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PbmsTokens.teal),
                  ),
                ],
              ),
            ),
            if (link.orderCode != null)
              PbmsDetailRow(label: 'Mã đơn hàng', value: link.orderCode!),
            if (_note != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _noteIsError
                        ? Icons.error_outline_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                    color: _noteIsError ? PbmsTokens.danger : PbmsTokens.warn,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_note!,
                        style: const TextStyle(
                            fontSize: 12, color: PbmsTokens.ink)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: link.hasUrl ? _open : null,
                icon: const Icon(Icons.lock_rounded, size: 19),
                label: Text(
                    _opened ? 'Mở lại trang thanh toán' : 'Thanh toán với PayOS',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: PbmsTokens.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _checking ? null : () => _check(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PbmsTokens.teal,
                  backgroundColor: PbmsTokens.tealTint,
                  side: const BorderSide(color: PbmsTokens.tealLine),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                child: _checking
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.verify == null
                        ? 'Để sau'
                        : 'Tôi đã thanh toán, kiểm tra'),
              ),
            ),
            if (link.hasUrl)
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: link.paymentUrl));
                  if (context.mounted) {
                    showPbmsSnack(context, 'Đã sao chép liên kết thanh toán');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: PbmsTokens.muted),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Sao chép liên kết'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Khung bottom sheet chuẩn: tay nắm + tiêu đề + nội dung cuộn.
class PbmsSheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const PbmsSheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: PbmsTokens.border,
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PbmsTokens.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style:
                      const TextStyle(fontSize: 12, color: PbmsTokens.muted)),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Ô nhập liệu nền xám nhạt, viền mảnh.
InputDecoration pbmsInputDecoration({String? hint, Color focus = PbmsTokens.teal}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: PbmsTokens.surfaceLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: PbmsTokens.border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: PbmsTokens.border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: focus, width: 1.5)),
  );
}

/// Nút chính teal cao 50.
class PbmsPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;

  const PbmsPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.color = PbmsTokens.teal,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700));
    final style = FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: PbmsTokens.border,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: icon == null || busy
          ? FilledButton(
              onPressed: busy ? null : onPressed, style: style, child: child)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 19),
              label: child),
    );
  }
}

/// Thanh chuyển mục dạng viên (nền xám, mục chọn nổi trắng).
class PbmsSegmentedTabs extends StatelessWidget {
  final List<(IconData, String)> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const PbmsSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PbmsTokens.divider,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                child: TextButton.icon(
                  onPressed: () => onChanged(i),
                  icon: Icon(tabs[i].$1, size: 18),
                  label: Text(tabs[i].$2,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor:
                        i == selected ? Colors.white : Colors.transparent,
                    foregroundColor:
                        i == selected ? PbmsTokens.ink : PbmsTokens.muted,
                    elevation: i == selected ? 1 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thanh tiêu đề của các tab: tiêu đề lớn căn trái trên cùng màu nền trang,
/// nút hành động dạng tròn viền mảnh giống nút chuông ở trang chủ.
PreferredSizeWidget pbmsTabAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.bgLight,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    toolbarHeight: 64,
    titleSpacing: 20,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: PbmsTokens.ink),
    ),
    actions: [...?actions, const SizedBox(width: 12)],
  );
}

/// Nút hành động trên thanh tiêu đề (cùng kiểu nút chuông ở trang chủ).
class PbmsHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const PbmsHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: PbmsTokens.ink,
          side: const BorderSide(color: PbmsTokens.border),
          minimumSize: const Size(44, 44),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

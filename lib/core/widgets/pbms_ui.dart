import 'package:prm393_frontend/core/widgets/payos_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/pbms_models.dart';
import '../error/error_text.dart';
import '../state/async_cubit.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'parking/exit_qr_screen.dart';

export 'parking/exit_qr_screen.dart';
export 'parking/pbms_led_counter.dart';
export 'parking/pbms_plate.dart';
export 'parking/pbms_slot_tag.dart';
export 'parking/pbms_ticket_stub.dart';

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
  static const body =
      TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w400, color: PbmsTokens.ink);
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

  /// Con số chính của màn hình (giờ đỗ, phí, số dư, mã ra cổng): 40-52sp, w800.
  static TextStyle display(double size, {Color color = PbmsTokens.ink}) => TextStyle(
      fontSize: size,
      height: 1.05,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -size * 0.02,
      fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Con dấu "Đã thanh toán" in nghiêng trên vé.
class PbmsPaidStamp extends StatelessWidget {
  final String label;

  const PbmsPaidStamp({super.key, this.label = 'Đã thanh toán'});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: PbmsTokens.teal, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: PbmsTokens.teal)),
      ),
    );
  }
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

/// Nhóm cài đặt phẳng: tiêu đề nhỏ phía trên, các dòng chung một khối, kẻ mảnh giữa dòng.
class PbmsSettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const PbmsSettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(title!, style: PbmsText.label.copyWith(fontSize: 13)),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: PbmsTokens.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 52, color: PbmsTokens.divider),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Một dòng cài đặt: icon mảnh, tên, mũi tên hoặc công tắc ở cuối.
class PbmsSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color iconColor;

  const PbmsSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.onTap,
    this.trailing,
    this.iconColor = PbmsTokens.muted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PbmsText.body.copyWith(fontSize: 15)),
                    if (detail != null) Text(detail!, style: PbmsText.caption),
                  ],
                ),
              ),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : const Icon(Icons.chevron_right_rounded, color: PbmsTokens.muted)),
            ],
          ),
        ),
      ),
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
        'refunded' => const StatusInfo('Đã hoàn tiền', _accent),
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

/// Khung chờ khi đang tải: giữ đúng chiều cao nội dung sắp hiện, vẽ sẵn các dòng
/// giả (ô biểu tượng, hai dòng chữ, số liệu bên phải) với vệt sáng lướt qua.
/// Thấp hơn 64 thì chỉ là một thanh bo góc.
class PbmsLoadingBox extends StatefulWidget {
  final double height;

  const PbmsLoadingBox({super.key, this.height = 96});

  @override
  State<PbmsLoadingBox> createState() => _PbmsLoadingBoxState();
}

class _PbmsLoadingBoxState extends State<PbmsLoadingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  static const _rowHeight = 44.0;
  static const _rowGap = 16.0;
  static const _padding = 14.0;
  static const _boneColor = Color(0xFFE3E8EE);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  static Widget _bone({double? width, required double height, double radius = 6}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _boneColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  Widget _row(int i) {
    // Độ dài dòng chữ đổi theo từng dòng để khung trông như nội dung thật.
    final titleFactor = const [0.62, 0.48, 0.7, 0.55][i % 4];
    final subFactor = const [0.4, 0.52, 0.34, 0.46][i % 4];
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          _bone(width: 40, height: 40, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(width: c.maxWidth * titleFactor, height: 12),
                  const SizedBox(height: 8),
                  _bone(width: c.maxWidth * subFactor, height: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _bone(width: 48, height: 12),
        ],
      ),
    );
  }

  /// Vệt sáng chỉ phủ lên các khối xám (srcATop trên nền trong suốt).
  Widget _shimmer(Widget bones) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) return bones;
    return AnimatedBuilder(
      animation: _sweep,
      child: bones,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: const [_boneColor, Color(0xFFF4F6F9), _boneColor],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(_sweep.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final Widget frame;
    if (h < 64) {
      frame = _shimmer(_bone(height: h, radius: 16));
    } else {
      final rows = ((h - 2 * _padding - 2 + _rowGap) / (_rowHeight + _rowGap)).floor().clamp(1, 99);
      frame = Container(
        height: h,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PbmsTokens.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRect(
          child: _shimmer(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows; i++) ...[
                if (i > 0) const SizedBox(height: _rowGap),
                _row(i),
              ],
            ],
          )),
        ),
      );
    }
    return Semantics(label: 'Đang tải', child: ExcludeSemantics(child: frame));
  }
}

/// Dịch dải sáng của khung chờ từ trái sang phải theo [t] (0 → 1).
class _SlideGradient extends GradientTransform {
  final double t;

  const _SlideGradient(this.t);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: PbmsTokens.muted, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: PbmsText.bodyStrong)),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: PbmsText.caption),
          ],
          if (action != null) ...[
            const SizedBox(height: 8),
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

/// Mã QR ra/vào cổng (payload do backend cấp): mở màn hình toàn màn, sáng tối đa.
class PbmsQrDialog {
  PbmsQrDialog._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String payload,
    String? headline,
    String? plate,
    bool isMotorbike = false,
    String? code,
    List<(IconData, String, String)> rows = const [],
  }) {
    return ExitQrScreen.open(
      context,
      ExitQrScreen(
        title: title,
        payload: payload,
        plate: plate,
        isMotorbike: isMotorbike,
        code: code,
        headline: headline,
        rows: rows,
      ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor:
                        i == selected ? Colors.white : Colors.transparent,
                    foregroundColor:
                        i == selected ? PbmsTokens.ink : PbmsTokens.muted,
                    elevation: i == selected ? 1 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

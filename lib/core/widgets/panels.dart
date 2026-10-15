import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bề mặt nội dung: nền surface + viền 1px, không đổ bóng.
class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: color ?? p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedLg,
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Tiêu đề mục: chữ đậm bên trái, hành động text bên phải.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section, bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (trailing != null) trailing!,
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Dòng nhãn — giá trị dùng trong chi tiết vé/phiên.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: t.bodyMedium?.copyWith(color: p.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: mono
                  ? AppTypography.mono(size: 14, weight: FontWeight.w600, color: valueColor ?? p.text)
                  : t.titleSmall?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Số liệu lớn kiểu đồng hồ: nhãn nhỏ phía trên, giá trị mono phía dưới.
class Gauge extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? labelColor;
  final Color? valueColor;
  final double size;

  const Gauge({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.labelColor,
    this.valueColor,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.labelSmall?.copyWith(color: labelColor ?? p.textSecondary)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: value,
              style: AppTypography.mono(
                size: size,
                weight: FontWeight.w600,
                color: valueColor ?? p.text,
                letterSpacing: -0.5,
              ),
            ),
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: t.labelMedium?.copyWith(color: labelColor ?? p.textSecondary),
              ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
      ],
    );
  }
}

/// Thanh sức chứa phân đoạn như vạch nhiên liệu.
class CapacityBar extends StatelessWidget {
  final int available;
  final int total;
  final Color? track;

  const CapacityBar({super.key, required this.available, required this.total, this.track});

  static Color toneFor(BuildContext context, int available, int total) {
    final p = context.palette;
    if (total == 0 || available == 0) return p.danger;
    final ratio = available / total;
    if (ratio < 0.15) return p.warn;
    return p.ok;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = total == 0 ? 0.0 : (available / total).clamp(0.0, 1.0);
    final color = toneFor(context, available, total);
    const segments = 20;
    final filled = (ratio * segments).round();
    return Semantics(
      label: 'Còn $available trên $total chỗ',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < segments; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i < filled ? color : (track ?? p.surfaceRaised),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hiện snackbar ngắn gọn.
void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final p = context.palette;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: error ? p.danger : p.ok,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ));
}

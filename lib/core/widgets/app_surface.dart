import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Bề mặt chuẩn (thẻ). Dựng trên [Material] để ripple của InkWell / ListTile bên trong hiển thị đúng.
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool elevated;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Padding(padding: padding, child: child);
    final surface = Material(
      color: color ?? p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.surface,
        side: BorderSide(color: borderColor ?? p.border),
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (!elevated) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.surface,
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: surface,
    );
  }
}

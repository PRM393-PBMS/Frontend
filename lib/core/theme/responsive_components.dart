import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// =============================================================================
// 1. RESPONSIVE TYPOGRAPHY
// =============================================================================

enum ResponsiveTextVariant {
  displayLarge,
  displayMedium,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final ResponsiveTextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final double? letterSpacing;
  final double? height;

  const ResponsiveText(
    this.text, {
    super.key,
    this.variant = ResponsiveTextVariant.bodyMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.letterSpacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? overflow : TextOverflow.visible,
      style: style.copyWith(
        color: color,
        fontWeight: fontWeight ?? style.fontWeight,
        letterSpacing: letterSpacing ?? style.letterSpacing,
        height: height ?? style.height,
      ),
    );
  }

  TextStyle _resolveStyle(BuildContext context) {
    switch (variant) {
      case ResponsiveTextVariant.displayLarge:
        return AppTypography.displayLarge.copyWith(fontSize: context.sp(32));
      case ResponsiveTextVariant.displayMedium:
        return AppTypography.displayMedium.copyWith(fontSize: context.sp(26));
      case ResponsiveTextVariant.titleLarge:
        return AppTypography.titleLarge.copyWith(fontSize: context.sp(20));
      case ResponsiveTextVariant.titleMedium:
        return AppTypography.titleMedium.copyWith(fontSize: context.sp(17));
      case ResponsiveTextVariant.titleSmall:
        return AppTypography.titleSmall.copyWith(fontSize: context.sp(15));
      case ResponsiveTextVariant.bodyLarge:
        return AppTypography.bodyLarge.copyWith(fontSize: context.sp(15));
      case ResponsiveTextVariant.bodyMedium:
        return AppTypography.bodyMedium.copyWith(fontSize: context.sp(13.5));
      case ResponsiveTextVariant.bodySmall:
        return AppTypography.bodySmall.copyWith(fontSize: context.sp(12));
      case ResponsiveTextVariant.labelLarge:
        return AppTypography.labelLarge.copyWith(fontSize: context.sp(13.5));
      case ResponsiveTextVariant.labelMedium:
        return AppTypography.labelMedium.copyWith(fontSize: context.sp(11.5));
    }
  }
}

// =============================================================================
// 2. RESPONSIVE BUTTON
// =============================================================================

enum ResponsiveButtonType { primary, secondary, outlined, text }

class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ResponsiveButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ResponsiveButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? context.space(52);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(context.space(16));
    final effectivePadding = EdgeInsets.symmetric(
      horizontal: context.wp(4),
      vertical: context.space(10),
    );

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: context.iconSize(20),
            height: context.iconSize(20),
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ResponsiveButtonType.outlined
                    ? (foregroundColor ?? AppColors.primary)
                    : Colors.white,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: context.iconSize(18)),
            SizedBox(width: context.space(8)),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge.copyWith(
                fontSize: context.sp(14.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    if (type == ResponsiveButtonType.outlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            side: BorderSide(color: backgroundColor ?? AppColors.primary, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            padding: effectivePadding,
          ),
          child: child,
        ),
      );
    }

    if (type == ResponsiveButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? AppColors.primary,
          padding: effectivePadding,
        ),
        child: child,
      );
    }

    final bg = backgroundColor ?? (type == ResponsiveButtonType.secondary ? AppColors.secondary : AppColors.primary);

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: onPressed == null || isLoading
            ? null
            : [
                BoxShadow(
                  color: bg.withValues(alpha: 0.28),
                  blurRadius: context.space(16),
                  offset: Offset(0, context.space(6)),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: foregroundColor ?? Colors.white,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          padding: effectivePadding,
        ),
        child: child,
      ),
    );
  }
}

// =============================================================================
// 3. RESPONSIVE TEXT BOX (WITH FOCUS GLOW & 1PX BORDER)
// =============================================================================

class ResponsiveTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const ResponsiveTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<ResponsiveTextField> createState() => _ResponsiveTextFieldState();
}

class _ResponsiveTextFieldState extends State<ResponsiveTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          ResponsiveText(
            widget.label!,
            variant: ResponsiveTextVariant.labelLarge,
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: context.space(8)),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.space(14)),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: context.space(12),
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: context.sp(14),
              color: AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: widget.hintText,
              helperText: widget.helperText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMutedLight,
                fontSize: context.sp(13.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.space(14),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: context.iconSize(20),
                      color: _hasFocus ? AppColors.primary : AppColors.textSecondaryLight,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.space(14)),
                borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.space(14)),
                borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.space(14)),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.space(14)),
                borderSide: const BorderSide(color: AppColors.error, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 4. RESPONSIVE CHECKBOX (48DP TOUCH ZONE & 22DP SOFT VISUAL)
// =============================================================================

class ResponsiveCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final Widget? trailing;

  const ResponsiveCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final visualSize = context.iconSize(22);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48), // WCAG minimum touch target
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.space(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: visualSize,
                height: visualSize,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(context.space(6)),
                  border: Border.all(
                    color: value ? AppColors.primary : AppColors.borderLight,
                    width: 1.5,
                  ),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: context.space(8),
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        size: visualSize * 0.75,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (label != null) ...[
                SizedBox(width: context.space(10)),
                Expanded(
                  child: ResponsiveText(
                    label!,
                    variant: ResponsiveTextVariant.bodyMedium,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 5. RESPONSIVE CARD & BOTTOM SHEET
// =============================================================================

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(context.space(20));
    final effectivePadding = padding ?? EdgeInsets.all(context.space(18));

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: context.space(16),
                offset: Offset(0, context.space(4)),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// Helper mở Responsive Bottom Sheet tự động co theo Keyboard Insets và bo góc lớn 24dp
Future<T?> showResponsiveBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(modalContext.space(24)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: modalContext.keyboardInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: modalContext.wp(5),
                vertical: modalContext.space(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle Bar
                  Container(
                    width: modalContext.space(40),
                    height: modalContext.space(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(height: modalContext.space(16)),
                  builder(modalContext),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

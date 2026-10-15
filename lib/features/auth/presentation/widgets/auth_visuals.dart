import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Biểu tượng thương hiệu: ô vuông carbon với chữ P như biển báo bãi đỗ.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PBMS Parking',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(size * 0.24),
          border: Border.all(color: AppColors.panelLine),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'P',
              style: AppTypography.mono(
                size: size * 0.56,
                weight: FontWeight.w800,
                color: AppColors.panelText,
              ),
            ),
            Positioned(
              bottom: size * 0.14,
              child: Container(
                width: size * 0.36,
                height: size * 0.07,
                decoration: BoxDecoration(
                  color: AppColors.cobaltBright,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung chung cho các màn xác thực.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack
          ? AppBar(
              leading: IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
            )
          : null,
      body: SafeArea(
        top: !showBack,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, showBack ? 0 : 28, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!showBack) ...[
                    const Align(alignment: Alignment.centerLeft, child: BrandMark()),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                  Text(title, style: t.displaySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, style: t.bodyLarge?.copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô nhập dùng chung cho form xác thực.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool mono;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      autofillHints: autofillHints,
      style: mono ? AppTypography.mono(size: 15, color: context.palette.text) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Nút ẩn/hiện mật khẩu.
class ObscureToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const ObscureToggle({super.key, required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      onPressed: onPressed,
      icon: Icon(obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
    );
  }
}

/// Nút hành động chính có trạng thái đang xử lý.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final String busyLabel;
  final bool busy;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busyLabel,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.palette.textMuted),
                ),
                const SizedBox(width: 10),
                Text(busyLabel),
              ],
            )
          : Text(label),
    );
  }
}

/// Báo lỗi/thành công từ AuthBloc qua snackbar.
void showAuthMessage(BuildContext context, String message, {bool error = true}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
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

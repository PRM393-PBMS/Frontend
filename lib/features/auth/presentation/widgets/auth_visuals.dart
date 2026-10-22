import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:prm393_frontend/core/widgets/pbms_logo.dart';

class AuthScreenHeader extends StatelessWidget {
  final bool isRegister;
  final String title;
  final String subtitle;
  final VoidCallback onSelectRegister;
  final VoidCallback onSelectLogin;

  const AuthScreenHeader({
    super.key,
    required this.isRegister,
    required this.title,
    required this.subtitle,
    required this.onSelectRegister,
    required this.onSelectLogin,
  });

  static const _ink = AppColors.textPrimaryLight;
  static const _muted = AppColors.textSecondaryLight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const PbmsLogo(size: 64),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _muted,
            ),
          ),
        ),
        const SizedBox(height: 19),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _AuthTab(
                    label: 'Đăng ký',
                    selected: isRegister,
                    onPressed: onSelectRegister,
                  ),
                ),
                Expanded(
                  child: _AuthTab(
                    label: 'Đăng nhập',
                    selected: !isRegister,
                    onPressed: onSelectLogin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _AuthTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      label: label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(36),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor:
              selected ? AppColors.brand : Colors.transparent,
          foregroundColor: selected ? Colors.white : AppColors.textSecondaryLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.validator,
    this.onChanged,
  });

  static const _brand = AppColors.brand;
  static const _ink = AppColors.textPrimaryLight;
  static const _muted = AppColors.textSecondaryLight;
  static const _border = AppColors.borderLight;

  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              prefixIcon: Icon(icon, size: 20, color: _brand),
              prefix: prefix,
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: outline,
              enabledBorder: outline,
              focusedBorder: outline.copyWith(
                borderSide: const BorderSide(color: _brand, width: 1.6),
              ),
              errorBorder: outline.copyWith(
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: outline.copyWith(
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'hoặc'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.brandTint)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.brandTint)),
      ],
    );
  }
}

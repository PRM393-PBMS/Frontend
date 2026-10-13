import 'package:flutter/material.dart';

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

  static const _brand = Color(0xFF087B8C);
  static const _ink = Color(0xFF111C2D);
  static const _muted = Color(0xFF3E484B);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brand, Color(0xFF8AD2DE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2600616E),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  size: 31,
                  color: Colors.white,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA3EBF7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: _brand,
                  ),
                ),
              ),
            ],
          ),
        ),
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
              color: const Color(0xFFE7EEFF),
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
              selected ? const Color(0xFF00616E) : Colors.transparent,
          foregroundColor: selected ? Colors.white : const Color(0xFF3E484B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
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

  static const _brand = Color(0xFF00616E);
  static const _ink = Color(0xFF111C2D);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFBEC8CB);

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Color(0xFFBA1A1A))),
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
                  const TextStyle(fontSize: 13, color: Color(0xFF6E797C)),
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
                borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
              ),
              focusedErrorBorder: outline.copyWith(
                borderSide:
                    const BorderSide(color: Color(0xFFBA1A1A), width: 1.6),
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

  const AuthDivider({super.key, this.label = 'HOẶC'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDEE8FF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDEE8FF))),
      ],
    );
  }
}

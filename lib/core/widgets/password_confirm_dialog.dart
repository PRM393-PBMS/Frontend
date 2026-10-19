import 'package:flutter/material.dart';

import 'pbms_ui.dart';

/// Hộp thoại xác thực lại mật khẩu trước thao tác nhạy cảm (huỷ vé, gia hạn, đổi biển số).
/// Trả mật khẩu đã nhập, hoặc null nếu khách bỏ qua.
class PasswordConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool danger;

  const PasswordConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.danger = false,
  });

  static Future<String?> ask(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    bool danger = false,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => PasswordConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          danger: danger,
        ),
      );

  @override
  State<PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<PasswordConfirmDialog> {
  final _password = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Nhập mật khẩu để xác nhận');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger ? PbmsTokens.danger : PbmsTokens.teal;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message, style: PbmsText.body),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: !_show,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: pbmsInputDecoration(hint: 'Mật khẩu của bạn', focus: accent).copyWith(
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: PbmsTokens.muted),
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ bỏ')),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: accent),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

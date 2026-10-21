import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Đổi mật khẩu: nhập mật khẩu hiện tại, mật khẩu mới và nhập lại.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<bool?> show(BuildContext context) =>
      PbmsSheetFrame.show<bool>(context, (_) => const ChangePasswordSheet());

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<PbmsRepository>().changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      showPbmsSnack(context, 'Đã đổi mật khẩu.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, String? Function(String?) validator,
      {TextInputAction action = TextInputAction.next}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: PbmsText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          obscureText: !_show,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: action,
          onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
          decoration: pbmsInputDecoration().copyWith(
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: PbmsTokens.muted),
          ),
          validator: validator,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Đổi mật khẩu',
      subtitle: 'Đổi xong, các thiết bị khác sẽ phải đăng nhập lại.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_current, 'Mật khẩu hiện tại',
                  (v) => (v ?? '').isEmpty ? 'Nhập mật khẩu hiện tại' : null),
              _field(_next, 'Mật khẩu mới', (v) {
                final s = v ?? '';
                if (s.length < 6) return 'Mật khẩu mới tối thiểu 6 ký tự';
                if (s.length > 72) return 'Mật khẩu mới tối đa 72 ký tự';
                if (s == _current.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                return null;
              }),
              _field(_confirm, 'Nhập lại mật khẩu mới',
                  (v) => v != _next.text ? 'Mật khẩu nhập lại không khớp' : null,
                  action: TextInputAction.done),
            ],
          ),
        ),
        CheckboxListTile(
          value: _show,
          onChanged: (v) => setState(() => _show = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: PbmsTokens.teal,
          title: const Text('Hiện mật khẩu', style: PbmsText.body),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 14),
        PbmsPrimaryButton(label: 'Đổi mật khẩu', busy: _busy, onPressed: _submit),
      ],
    );
  }
}

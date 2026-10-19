import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';

/// Xoá tài khoản: giải thích hậu quả, nhập lại mật khẩu, xác nhận không khôi phục được.
class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  static Future<void> show(BuildContext context) =>
      PbmsSheetFrame.show<void>(context, (_) => const DeleteAccountSheet());

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _understood = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Nhập mật khẩu để xác nhận.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<PbmsRepository>().deleteAccount(_password.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final auth = context.read<AuthBloc>();
      Navigator.pop(context);
      auth.add(AuthLogoutRequested());
      messenger.showSnackBar(const SnackBar(
        content: Text('Đã xoá tài khoản. Cảm ơn bạn đã sử dụng PBMS.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const points = [
      'Họ tên, email, số điện thoại, ảnh đại diện bị xoá khỏi hồ sơ; bạn không đăng nhập lại được.',
      'Xe chưa từng gửi bị xoá; lịch sử gửi xe, thanh toán và hợp đồng được giữ lại theo quy định lưu chứng từ.',
      'Không xoá được khi còn xe trong bãi, vé tháng, đặt chỗ, thanh toán đang chờ hoặc tiền trong ví.',
      'Email và số điện thoại có thể dùng lại để đăng ký tài khoản mới.',
    ];
    return PbmsSheetFrame(
      title: 'Xoá tài khoản',
      subtitle: 'Thao tác này không thể hoàn tác.',
      children: [
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.info_outline_rounded, size: 16, color: PbmsTokens.muted),
                ),
                Expanded(child: Text(p, style: PbmsText.caption.copyWith(color: PbmsTokens.ink))),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text('Mật khẩu', style: PbmsText.label),
        const SizedBox(height: 6),
        TextField(
          controller: _password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: pbmsInputDecoration(hint: 'Nhập mật khẩu để xác nhận', focus: PbmsTokens.danger).copyWith(
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: PbmsTokens.muted),
          ),
        ),
        CheckboxListTile(
          value: _understood,
          onChanged: (v) => setState(() => _understood = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: PbmsTokens.danger,
          title: const Text('Tôi hiểu tài khoản đã xoá không khôi phục được', style: PbmsText.body),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _understood && !_busy ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: PbmsTokens.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.delete_forever_rounded),
            label: const Text('Xoá tài khoản vĩnh viễn'),
          ),
        ),
      ],
    );
  }
}

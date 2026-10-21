import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';

/// Đổi email đăng nhập: bước 1 nhập email mới + mật khẩu, bước 2 nhập mã OTP gửi tới email mới.
class ChangeEmailSheet extends StatefulWidget {
  final String currentEmail;

  const ChangeEmailSheet({super.key, required this.currentEmail});

  static Future<bool?> show(BuildContext context, String currentEmail) =>
      PbmsSheetFrame.show<bool>(context, (_) => ChangeEmailSheet(currentEmail: currentEmail));

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  late final PbmsRepository _repo = context.read<PbmsRepository>();

  /// Email đã gửi mã; khác null nghĩa là đang ở bước nhập OTP.
  String? _sentTo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        final email = _email.text.trim();
        await _repo.requestEmailChange(newEmail: email, password: _password.text);
        if (mounted) setState(() => _sentTo = email);
      });

  Future<void> _verify() => _run(() async {
        final email = await _repo.verifyEmailChange(_otp.text.trim());
        if (!mounted) return;
        context.read<AuthBloc>().add(AuthCheckRequested());
        Navigator.pop(context, true);
        showPbmsSnack(context, 'Đã đổi email đăng nhập thành $email.');
      });

  @override
  Widget build(BuildContext context) {
    final sentTo = _sentTo;
    return PbmsSheetFrame(
      title: 'Đổi email',
      subtitle: sentTo == null
          ? 'Email hiện tại: ${widget.currentEmail}'
          : 'Đã gửi mã 6 số tới $sentTo. Mã có hiệu lực 10 phút.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sentTo == null ? _stepOne() : _stepTwo(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
        ],
        const SizedBox(height: 18),
        PbmsPrimaryButton(
          label: sentTo == null ? 'Gửi mã xác nhận' : 'Xác nhận đổi email',
          busy: _busy,
          onPressed: sentTo == null ? _sendCode : _verify,
        ),
        if (sentTo != null)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _sentTo = null;
                      _otp.clear();
                      _error = null;
                    }),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Đổi email khác hoặc gửi lại mã'),
          ),
      ],
    );
  }

  List<Widget> _stepOne() => [
        const Text('Email mới', style: PbmsText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: pbmsInputDecoration(hint: 'ten@gmail.com'),
          validator: (v) {
            final value = (v ?? '').trim();
            if (!_emailRe.hasMatch(value)) return 'Email không hợp lệ';
            if (value.toLowerCase() == widget.currentEmail.toLowerCase()) {
              return 'Email mới phải khác email hiện tại';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        const Text('Mật khẩu hiện tại', style: PbmsText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: _password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendCode(),
          decoration: pbmsInputDecoration(),
          validator: (v) => (v ?? '').isEmpty ? 'Nhập mật khẩu để xác nhận' : null,
        ),
      ];

  List<Widget> _stepTwo() => [
        const Text('Mã xác nhận', style: PbmsText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: _otp,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _verify(),
          decoration: pbmsInputDecoration(hint: '6 chữ số'),
          validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Mã gồm 6 chữ số',
        ),
      ];
}

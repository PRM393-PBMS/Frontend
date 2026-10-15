import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_visuals.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final bool isResetPassword;
  final String? newPassword;
  final String? confirmPassword;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.isResetPassword = false,
    this.newPassword,
    this.confirmPassword,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otp = TextEditingController();
  String? _error;
  int _cooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _verify() {
    final otp = _otp.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Nhập đủ 6 chữ số trong email');
      return;
    }
    setState(() => _error = null);
    final bloc = context.read<AuthBloc>();
    if (widget.isResetPassword) {
      bloc.add(AuthVerifyResetPasswordSubmitted(
        email: widget.email,
        otp: otp,
        newPassword: widget.newPassword ?? '',
        confirmPassword: widget.confirmPassword ?? '',
      ));
    } else {
      bloc.add(AuthVerifyRegisterOtpSubmitted(email: widget.email, otp: otp));
    }
  }

  void _resend() {
    // Gửi lại mã đặt lại mật khẩu; đăng ký cần gửi lại toàn bộ biểu mẫu nên quay về bước trước.
    if (widget.isResetPassword) {
      context.read<AuthBloc>().add(AuthRequestResetPasswordSubmitted(email: widget.email));
      _startCooldown();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) => b.errorMessage != null && a.errorMessage != b.errorMessage,
          listener: (context, state) {
            setState(() => _error = state.errorMessage);
            context.read<AuthBloc>().add(AuthClearMessageRequested());
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) =>
              (!a.registeredSuccess && b.registeredSuccess) ||
              (!a.resetPasswordSuccess && b.resetPasswordSuccess),
          listener: (context, state) {
            showAuthMessage(context, state.successMessage ?? 'Xác thực thành công', error: false);
            context.goNamed(RouteNames.login);
          },
        ),
      ],
      child: AuthScaffold(
        showBack: true,
        title: 'Nhập mã xác thực',
        subtitle: 'Mã 6 số đã gửi tới ${widget.email}. Kiểm tra cả thư mục Spam.',
        children: [
          TextField(
            controller: _otp,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              if (_error != null) setState(() => _error = null);
              if (v.length == 6) _verify();
            },
            style: AppTypography.mono(size: 32, weight: FontWeight.w700, color: p.text, letterSpacing: 14),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: AppTypography.mono(size: 32, color: p.textMuted, letterSpacing: 14),
              errorText: _error,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) => a.isLoading != b.isLoading,
            builder: (context, state) => AuthSubmitButton(
              label: widget.isResetPassword ? 'Đặt mật khẩu mới' : 'Xác nhận tài khoản',
              busyLabel: 'Đang xác thực',
              busy: state.isLoading,
              onPressed: _verify,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _cooldown > 0
                ? Text('Gửi lại mã sau ${_cooldown}s', style: t.bodyMedium?.copyWith(color: p.textMuted))
                : TextButton(
                    onPressed: _resend,
                    child: Text(widget.isResetPassword ? 'Gửi lại mã' : 'Sửa thông tin và gửi lại'),
                  ),
          ),
        ],
      ),
    );
  }
}

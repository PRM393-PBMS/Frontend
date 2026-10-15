import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_visuals.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  bool _agreeError = false;

  @override
  void dispose() {
    for (final c in [_userName, _fullName, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _agreeError = !_agree);
    if (!valid || !_agree) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthSendRegisterOtpSubmitted(
          userName: _userName.text.trim(),
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phoneNumber: _phone.text.trim(),
          password: _password.text,
          confirmPassword: _confirm.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) =>
              b.errorMessage != null &&
              a.errorMessage != b.errorMessage &&
              (ModalRoute.of(context)?.isCurrent ?? false),
          listener: (context, state) {
            showAuthMessage(context, state.errorMessage!);
            context.read<AuthBloc>().add(AuthClearMessageRequested());
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          // successMessage được xoá mỗi lần gửi lại, nên mỗi lần gửi OTP thành công chỉ điều hướng một lần.
          listenWhen: (a, b) =>
              b.otpSent &&
              b.pendingEmail != null &&
              b.successMessage != null &&
              a.successMessage == null &&
              (ModalRoute.of(context)?.isCurrent ?? false),
          listener: (context, state) {
            showAuthMessage(context, state.successMessage ?? 'Đã gửi mã xác thực', error: false);
            context.pushNamed(
              RouteNames.verifyOtp,
              extra: {'email': state.pendingEmail!, 'isResetPassword': false},
            );
          },
        ),
      ],
      child: AuthScaffold(
        title: 'Tạo tài khoản',
        subtitle: 'Chúng tôi gửi mã 6 số về email để xác nhận.',
        children: [
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _fullName,
                    label: 'Họ và tên',
                    hint: 'Trần Minh Khoa',
                    icon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Nhập họ và tên' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _userName,
                    label: 'Tên đăng nhập',
                    hint: 'khoatran',
                    icon: Icons.alternate_email_rounded,
                    autofillHints: const [AutofillHints.newUsername],
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.length < 3) return 'Tối thiểu 3 ký tự';
                      if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(s)) {
                        return 'Chỉ dùng chữ không dấu, số, dấu chấm hoặc gạch dưới';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _phone,
                    label: 'Số điện thoại',
                    hint: '0912345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    mono: true,
                    validator: (v) => RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Số di động Việt Nam 10 số, ví dụ 0912345678',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _email,
                    label: 'Email',
                    hint: 'ban@gmail.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Email không hợp lệ',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _password,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    suffix: ObscureToggle(
                      obscured: _obscure,
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v ?? '').length < 6 ? 'Tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _confirm,
                    label: 'Nhập lại mật khẩu',
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v != _password.text ? 'Mật khẩu nhập lại không khớp' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: _agree,
                    onChanged: (v) => setState(() {
                      _agree = v ?? false;
                      _agreeError = false;
                    }),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tôi đồng ý với điều khoản sử dụng bãi xe', style: t.bodyMedium),
                    subtitle: _agreeError
                        ? Text('Cần đồng ý để tạo tài khoản', style: t.bodySmall?.copyWith(color: p.danger))
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (a, b) => a.isLoading != b.isLoading,
                    builder: (context, state) => AuthSubmitButton(
                      label: 'Gửi mã xác thực',
                      busyLabel: 'Đang gửi mã',
                      busy: state.isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Đã có tài khoản?', style: t.bodyMedium?.copyWith(color: p.textSecondary)),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.login),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

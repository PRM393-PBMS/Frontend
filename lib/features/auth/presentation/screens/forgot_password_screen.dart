import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_visuals.dart';

/// Bước 1 đặt lại mật khẩu: email + mật khẩu mới → nhận OTP.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthRequestResetPasswordSubmitted(email: _email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
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
          listenWhen: (a, b) =>
              b.otpSent &&
              b.pendingEmail != null &&
              b.successMessage != null &&
              a.successMessage == null &&
              (ModalRoute.of(context)?.isCurrent ?? false),
          listener: (context, state) {
            showAuthMessage(context, state.successMessage!, error: false);
            context.pushNamed(
              RouteNames.verifyOtp,
              extra: {
                'email': state.pendingEmail!,
                'isResetPassword': true,
                'newPassword': _password.text,
                'confirmPassword': _confirm.text,
              },
            );
          },
        ),
      ],
      child: AuthScaffold(
        showBack: true,
        title: 'Đặt lại mật khẩu',
        subtitle: 'Nhập email tài khoản và mật khẩu mới. Mã xác nhận sẽ được gửi về email.',
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  label: 'Mật khẩu mới',
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
                  label: 'Nhập lại mật khẩu mới',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _password.text ? 'Mật khẩu nhập lại không khớp' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (a, b) => a.isLoading != b.isLoading,
                  builder: (context, state) => AuthSubmitButton(
                    label: 'Gửi mã xác nhận',
                    busyLabel: 'Đang gửi mã',
                    busy: state.isLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

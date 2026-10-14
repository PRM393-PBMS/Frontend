import '../../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_layout.dart';

/// Nhập OTP: hoàn tất đăng ký, hoặc đặt lại mật khẩu (kèm mật khẩu mới).
class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final bool isResetPassword;

  const VerifyOtpScreen(
      {super.key, required this.email, required this.isResetPassword});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitted = true;
    final bloc = context.read<AuthBloc>();
    if (widget.isResetPassword) {
      bloc.add(AuthVerifyResetPasswordSubmitted(
        email: widget.email,
        otp: _otp.text.trim(),
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      ));
    } else {
      bloc.add(AuthVerifyRegisterOtpSubmitted(
          email: widget.email, otp: _otp.text.trim()));
    }
  }

  void _resend() {
    if (widget.isResetPassword) {
      context
          .read<AuthBloc>()
          .add(AuthRequestResetPasswordSubmitted(email: widget.email));
    } else {
      // Gửi lại OTP đăng ký cần đủ thông tin form, nên quay lại màn đăng ký.
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, cur) => prev.status != cur.status,
      listener: (context, state) {
        if (!_submitted || state.status != AuthStatus.unauthenticated) return;
        if (state.registeredSuccess || state.resetPasswordSuccess) {
          _submitted = false;
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        final showResent = !_submitted &&
            widget.isResetPassword &&
            state.successMessage != null &&
            state.status == AuthStatus.unauthenticated;
        return AuthLayout(
          showBack: true,
          title: widget.isResetPassword
              ? context.l10n.otpTitleReset
              : context.l10n.otpTitleRegister,
          subtitle: context.l10n.otpSubtitle(widget.email),
          children: [
            if (state.status == AuthStatus.failure) ...[
              InlineMessage((state.errorMessage ?? '').isEmpty
                  ? (widget.isResetPassword
                      ? context.l10n.resetFailed
                      : context.l10n.otpVerifyFailed)
                  : state.errorMessage!),
              const SizedBox(height: AppSpacing.lg),
            ] else if (showResent) ...[
              InlineMessage(context.l10n.otpResent, isError: false),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: context.l10n.fieldOtp,
                    controller: _otp,
                    hint: '000000',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: widget.isResetPassword
                        ? TextInputAction.next
                        : TextInputAction.done,
                    style: AppTypography.mono.copyWith(
                      fontSize: 22,
                      letterSpacing: 8,
                      color: p.textPrimary,
                    ),
                    validator: (v) => Validators.otp(context.l10n, v),
                    onSubmitted:
                        widget.isResetPassword ? null : (_) => _submit(),
                  ),
                  if (widget.isResetPassword) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.fieldNewPassword,
                      controller: _password,
                      obscure: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.password(context.l10n, v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.fieldNewPasswordConfirm,
                      controller: _confirm,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => Validators.confirmPassword(
                          context.l10n, v, _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: widget.isResetPassword
                  ? context.l10n.otpSubmitReset
                  : context.l10n.otpSubmitRegister,
              loading: state.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AppButton.text(
                label: widget.isResetPassword
                    ? context.l10n.otpResend
                    : context.l10n.otpEditAndResend,
                onPressed: state.isLoading ? null : _resend,
              ),
            ),
          ],
        );
      },
    );
  }
}

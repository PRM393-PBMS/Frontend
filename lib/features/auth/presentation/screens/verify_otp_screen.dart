import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/responsive_components.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

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
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isResetPassword) {
      context.read<AuthBloc>().add(
            AuthVerifyResetPasswordSubmitted(
              email: widget.email,
              otp: otp,
              newPassword: widget.newPassword ?? '',
              confirmPassword: widget.confirmPassword ?? '',
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthVerifyRegisterOtpSubmitted(
              email: widget.email,
              otp: otp,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthBloc>().add(AuthClearMessageRequested());
        }

        // Đăng ký thành công hoặc reset mật khẩu thành công -> quay về màn hình Đăng nhập
        if (state.registeredSuccess || state.resetPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'Thành công!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.goNamed(RouteNames.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: const Text('Xác thực OTP'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Kiểm tra hòm thư của bạn',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        children: [
                          const TextSpan(text: 'Mã xác thực OTP gồm 6 chữ số đã được gửi đến:\n'),
                          TextSpan(
                            text: widget.email,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.space(32)),

                    ResponsiveCard(
                      padding: EdgeInsets.all(context.space(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ResponsiveText(
                            'Nhập mã OTP 6 số',
                            variant: ResponsiveTextVariant.labelLarge,
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: context.space(12)),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              letterSpacing: 12.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: context.sp(26),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: TextStyle(
                                letterSpacing: 12.0,
                                color: Colors.black26,
                                fontSize: context.sp(26),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: context.space(14),
                              ),
                            ),
                          ),
                          SizedBox(height: context.space(28)),

                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return ResponsiveButton(
                                label: 'Kích hoạt tài khoản',
                                isLoading: state.isLoading,
                                onPressed: _onVerifyPressed,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.space(24)),

                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Chưa nhận được mã? Gửi lại'),
                        onPressed: () {
                          if (widget.isResetPassword) {
                            context.read<AuthBloc>().add(
                                  AuthRequestResetPasswordSubmitted(email: widget.email),
                                );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đợi vài giây và kiểm tra lại hộp thư'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

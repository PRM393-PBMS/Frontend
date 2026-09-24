import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/responsive_components.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;

  @override
  void dispose() {
    _userNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản dịch vụ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthSendRegisterOtpSubmitted(
              userName: _userNameController.text.trim(),
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
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

        if (state.otpSent && state.pendingEmail != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'Đã gửi mã OTP'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pushNamed(
            RouteNames.verifyOtp,
            extra: {'email': state.pendingEmail!, 'isResetPassword': false},
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: const ResponsiveText('Tạo tài khoản mới', variant: ResponsiveTextVariant.titleMedium),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: context.iconSize(20)),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(6),
                vertical: context.space(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResponsiveText(
                        'Đăng ký PBMS',
                        variant: ResponsiveTextVariant.displayMedium,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                      SizedBox(height: context.space(6)),
                      ResponsiveText(
                        'Nhập thông tin cá nhân để kích hoạt tài khoản bãi đỗ xe',
                        variant: ResponsiveTextVariant.bodyMedium,
                        color: AppColors.textSecondaryLight,
                      ),
                      SizedBox(height: context.space(24)),

                      ResponsiveCard(
                        padding: EdgeInsets.all(context.space(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username
                            ResponsiveTextField(
                              controller: _userNameController,
                              label: 'Tên đăng nhập (Username)',
                              hintText: 'ví dụ: seiryuu',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập tên đăng nhập' : null,
                            ),
                            SizedBox(height: context.space(16)),

                            // Full name
                            ResponsiveTextField(
                              controller: _fullNameController,
                              label: 'Họ và tên',
                              hintText: 'ví dụ: Nguyễn Văn A',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập họ và tên' : null,
                            ),
                            SizedBox(height: context.space(16)),

                            // Email
                            ResponsiveTextField(
                              controller: _emailController,
                              label: 'Email nhận mã OTP',
                              hintText: 'name@example.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                                if (!v.contains('@')) return 'Email không hợp lệ';
                                return null;
                              },
                            ),
                            SizedBox(height: context.space(16)),

                            // Phone
                            ResponsiveTextField(
                              controller: _phoneController,
                              label: 'Số điện thoại',
                              hintText: '0901234567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập số điện thoại' : null,
                            ),
                            SizedBox(height: context.space(16)),

                            // Password
                            ResponsiveTextField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: context.iconSize(20),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => (v == null || v.length < 3) ? 'Mật khẩu tối thiểu 3 ký tự' : null,
                            ),
                            SizedBox(height: context.space(16)),

                            // Confirm password
                            ResponsiveTextField(
                              controller: _confirmPasswordController,
                              label: 'Xác nhận mật khẩu',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_reset_rounded,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: context.iconSize(20),
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                                return null;
                              },
                            ),
                            SizedBox(height: context.space(14)),

                            // Terms Checkbox (Touch target >= 48dp)
                            ResponsiveCheckbox(
                              value: _agreeTerms,
                              onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                              label: 'Tôi đồng ý với Điều khoản và Chính sách bãi đỗ xe',
                            ),
                            SizedBox(height: context.space(20)),

                            // Submit Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return ResponsiveButton(
                                  label: 'Gửi mã xác thực OTP',
                                  isLoading: state.isLoading,
                                  onPressed: _onRegisterPressed,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.space(20)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ResponsiveText('Đã có tài khoản? ', variant: ResponsiveTextVariant.bodyMedium),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: ResponsiveText(
                              'Đăng nhập ngay',
                              variant: ResponsiveTextVariant.labelLarge,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

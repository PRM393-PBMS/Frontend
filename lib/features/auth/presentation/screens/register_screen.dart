import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_spacing.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
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

        // Khi OTP đã gửi thành công -> chuyển sang màn hình nhập OTP
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
          title: const Text('Tạo tài khoản mới'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Đăng ký PBMS',
                        style: AppTypography.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nhập thông tin cá nhân để kích hoạt tài khoản bãi đỗ xe',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedLg,
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username
                              Text('Tên đăng nhập (Username)', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _userNameController,
                                decoration: const InputDecoration(
                                  hintText: 'ví dụ: seiryuu',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập tên đăng nhập' : null,
                              ),
                              const SizedBox(height: 16),

                              // Full name
                              Text('Họ và tên', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  hintText: 'ví dụ: Nguyễn Văn A',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập họ và tên' : null,
                              ),
                              const SizedBox(height: 16),

                              // Email
                              Text('Email nhận mã OTP', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'name@example.com',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                                  if (!v.contains('@')) return 'Email không hợp lệ';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone number
                              Text('Số điện thoại', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '0901234567',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (v) => v?.trim().isEmpty ?? true ? 'Vui lòng nhập số điện thoại' : null,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              Text('Mật khẩu', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 3) ? 'Mật khẩu tối thiểu 3 ký tự' : null,
                              ),
                              const SizedBox(height: 16),

                              // Confirm password
                              Text('Xác nhận mật khẩu', style: AppTypography.labelLarge),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state.isLoading;
                                  return ElevatedButton(
                                    onPressed: isLoading ? null : _onRegisterPressed,
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text('Gửi mã xác thực OTP'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Đã có tài khoản? ', style: AppTypography.bodyMedium),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Đăng nhập ngay',
                              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
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

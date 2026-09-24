import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/theme/responsive_components.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import 'package:prm393_frontend/core/widgets/fade_in_up.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'fonHocPRM393@gmail.com');
  final _passwordController = TextEditingController(text: 'passcuafon@123');
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1D4ED8), // Deep Royal Blue
                Color(0xFF2563EB), // Vibrant Blue
                Color(0xFF3B82F6), // Sky Accent
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 60),

              // Header Branding with Fade In Animation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 150),
                      child: Text(
                        'Đăng nhập',
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'Chào mừng bạn quay lại hệ thống PBMS',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // White Bottom Rounded Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // Shadowed Input Card with Internal Divider
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 450),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.16),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      // Email / Phone field
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            hintText: 'Email hoặc Tên đăng nhập',
                                            hintStyle: TextStyle(color: Colors.grey.shade400),
                                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Vui lòng nhập email hoặc tài khoản';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      // Password field
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            hintText: 'Mật khẩu',
                                            hintStyle: TextStyle(color: Colors.grey.shade400),
                                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: Colors.grey.shade500,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập mật khẩu';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Remember Me Checkbox & Forgot Password Link
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 600),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ResponsiveCheckbox(
                                        value: _rememberMe,
                                        label: 'Ghi nhớ đăng nhập',
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: context.space(8)),
                                      ),
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(12.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.space(16)),

                              // Pill Login Button
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 750),
                                child: BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state.isLoading;
                                    return SizedBox(
                                      height: 52,
                                      child: MaterialButton(
                                        onPressed: isLoading ? null : _onLoginPressed,
                                        color: AppColors.primary,
                                        disabledColor: AppColors.primary.withValues(alpha: 0.6),
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Center(
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  'Đăng nhập',
                                                  style: AppTypography.labelLarge.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Register Button (Pill Outlined)
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 900),
                                child: Column(
                                  children: [
                                    Text(
                                      'Chưa có tài khoản tham gia hệ thống?',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 48,
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => context.pushNamed(RouteNames.register),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                        ),
                                        child: Text(
                                          'Tạo tài khoản mới',
                                          style: AppTypography.labelLarge.copyWith(
                                            color: AppColors.textPrimaryLight,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Quick Bypass / Preview Button
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 950),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      context.read<AuthBloc>().add(AuthDemoLoginRequested());
                                    },
                                    icon: const Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 20),
                                    label: Text(
                                      'Vào xem ngay giao diện Home (Bypass)',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        side: BorderSide(
                                          color: AppColors.accent.withValues(alpha: 0.3),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quick helper note for testers
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 1000),
                                child: Center(
                                  child: Text(
                                    'Bấm nút tím ở trên để xem trực tiếp giao diện bãi đỗ xe và thanh điều hướng',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

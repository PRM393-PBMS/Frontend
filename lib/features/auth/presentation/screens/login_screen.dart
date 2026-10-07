import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;

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
        backgroundColor: bgColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            if (isDesktop) {
              // ==============================================================
              // DESKTOP SPLIT SCREEN ARCHITECTURE
              // ==============================================================
              return Row(
                children: [
                  // Cột trái: Brand Showcase & Architectural Visualization
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: AppColors.surfaceDark,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: (constraints.maxHeight - 96).clamp(0, double.infinity)),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Logo
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.35),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.local_parking_rounded, color: Color(0xFF090D14), size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PBMS',
                                              style: AppTypography.displayMedium.copyWith(
                                                color: AppColors.textPrimaryDark,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            Text(
                                              'PARKING COCKPIT',
                                              style: AppTypography.badgeMono.copyWith(
                                                color: AppColors.primary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    const Spacer(),

                                    // Value Proposition
                                    Text(
                                      'Hệ thống quản lý bãi đỗ xe thông minh thế hệ mới',
                                      style: AppTypography.displayLarge.copyWith(
                                        color: AppColors.textPrimaryDark,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tích hợp nhận diện biển số tự động qua camera AI OCR, cảm biến siêu âm xác định vị trí tầng đỗ, và thanh toán VietQR tự động qua cổng PayOS.',
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.textSecondaryDark,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 36),

                                    // 3 Feature Badges
                                    _buildDesktopFeatureItem(
                                      Icons.camera_alt_outlined,
                                      'AI Plate Recognition',
                                      'Nhận diện biển số xe vào/ra dưới 0.3 giây',
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDesktopFeatureItem(
                                      Icons.sensors_rounded,
                                      'Ultrasonic Sensor Telemetry',
                                      'Giám sát slot đỗ thời gian thực với độ chính xác 99.8%',
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDesktopFeatureItem(
                                      Icons.qr_code_2_rounded,
                                      'Instant PayOS Settlement',
                                      'Tự động tính cước lũy tiến và xuất mã thanh toán VietQR',
                                    ),

                                    const Spacer(),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Bản quyền © 2026 PBMS Architecture. Tất cả quyền được bảo lưu.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMutedDark,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Cột phải: Precision Auth Form
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: bgColor,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(36),
                            child: _buildLoginFormCard(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // ==============================================================
            // MOBILE COMPACT ARCHITECTURE
            // ==============================================================
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Mobile Brand Header
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.local_parking_rounded, color: Color(0xFF090D14), size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'PBMS COCKPIT',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Smart Parking Mobility System',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildLoginFormCard(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopFeatureItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFormCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng nhập',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Truy cập tài khoản cư dân & quản lý phương tiện',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 24),

            // Email Field
            Text(
              'TÀI KHOẢN HOẶC EMAIL',
              style: AppTypography.badgeMono.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Nhập email hoặc tên đăng nhập',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tài khoản hoặc email';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Password Field
            Text(
              'MẬT KHẨU BẢO MẬT',
              style: AppTypography.badgeMono.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.primary,
                        checkColor: const Color(0xFF090D14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ghi nhớ',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Login Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.isLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF090D14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF090D14)),
                            ),
                          )
                        : Text(
                            'Đăng nhập ngay',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF090D14),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Demo Quick Bypass Button (Phục vụ Test & Trình diễn)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthDemoLoginRequested());
                },
                icon: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.accent),
                label: Text(
                  'Vào thẳng Home Cockpit (Demo Bypass)',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Register Link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chưa có tài khoản?',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed(RouteNames.register),
                    child: Text(
                      'Đăng ký tài khoản mới',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

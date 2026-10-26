import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/features/legal/legal_screen.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_visuals.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Phiên cũ của tài khoản nhân sự bị từ chối ngay ở màn khởi động.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthBloc>().state.staffAccountBlocked) {
        _showStaffBlockedDialog();
      }
    });
  }

  Future<void> _showStaffBlockedDialog() async {
    final bloc = context.read<AuthBloc>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.badge_outlined),
        title: const Text('Không thể đăng nhập'),
        content: const Text(
            'Tài khoản quản lý/quản trị vui lòng sử dụng cổng Web nội bộ.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
    bloc.add(AuthClearMessageRequested());
  }

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
        if (state.staffAccountBlocked) {
          _showStaffBlockedDialog();
          return;
        }
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgLight,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthScreenHeader(
                          isRegister: false,
                          title: 'Chào mừng trở lại',
                          subtitle:
                              'Đăng nhập để tìm bãi, quản lý vé và đặt chỗ dễ dàng',
                          onSelectRegister: _openRegister,
                          onSelectLogin: _keepLogin,
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  controller: _emailController,
                                  label: 'Email hoặc tên đăng nhập',
                                  hint: 'example@gmail.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập email hoặc tài khoản'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  controller: _passwordController,
                                  label: 'Mật khẩu',
                                  hint: 'Nhập mật khẩu',
                                  icon: Icons.lock_outline_rounded,
                                  textInputAction: TextInputAction.done,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Vui lòng nhập mật khẩu'
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.brand,
                                      onChanged: (value) => setState(
                                          () => _rememberMe = value ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Ghi nhớ đăng nhập',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context
                                          .pushNamed(RouteNames.forgotPassword),
                                      child: const Text('Quên mật khẩu?',
                                          style: TextStyle(
                                              color: AppColors.brand,
                                              fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) => SizedBox(
                                    height: 52,
                                    child: FilledButton.icon(
                                      onPressed: state.isLoading
                                          ? null
                                          : _onLoginPressed,
                                      icon: state.isLoading
                                          ? const SizedBox.square(
                                              dimension: 19,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 19),
                                      label: Text(state.isLoading
                                          ? 'Đang đăng nhập...'
                                          : 'Đăng nhập',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppColors.brand,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text('Chưa có tài khoản? ',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textSecondaryLight)),
                              TextButton(
                                onPressed: _openRegister,
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 44)),
                                child: const Text('Đăng ký ngay',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brand)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const LegalLinks(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _keepLogin() {}

  void _openRegister() => context.goNamed(RouteNames.register);
}

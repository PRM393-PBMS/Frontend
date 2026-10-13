import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/routes/route_names.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
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
  final _userNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;

  int get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1;
    if (password.length < 10) return 2;
    return 3;
  }

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
        backgroundColor: const Color(0xFFF7FAFC),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEFFBFC), Color(0xFFF7FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
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
                          isRegister: true,
                          title: 'Tạo tài khoản mới',
                          subtitle:
                              'Gia nhập mạng lưới đỗ xe thông minh, tiện lợi mọi lúc mọi nơi',
                          onSelectRegister: _keepRegister,
                          onSelectLogin: _openLogin,
                        ),
                        const SizedBox(height: 19),
                        Form(
                          key: _formKey,
                          child: Container(
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A0F172A),
                                  blurRadius: 14,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  controller: _fullNameController,
                                  label: 'Họ và tên',
                                  hint: 'Nguyễn Văn A',
                                  icon: Icons.person_outline_rounded,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập họ và tên'
                                          : null,
                                ),
                                const SizedBox(height: 13),
                                AuthTextField(
                                  controller: _userNameController,
                                  label: 'Tên đăng nhập',
                                  hint: 'Chọn tên đăng nhập',
                                  icon: Icons.alternate_email_rounded,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập tên đăng nhập'
                                          : null,
                                ),
                                const SizedBox(height: 13),
                                AuthTextField(
                                  controller: _phoneController,
                                  label: 'Số điện thoại',
                                  hint: '0912 345 678',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Text('+84  |',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF111C2D))),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập số điện thoại'
                                          : null,
                                ),
                                const SizedBox(height: 13),
                                AuthTextField(
                                  controller: _emailController,
                                  label: 'Gmail / Email',
                                  hint: 'example@gmail.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 13),
                                AuthTextField(
                                  controller: _passwordController,
                                  label: 'Mật khẩu',
                                  hint: 'Tối thiểu 3 ký tự',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  onChanged: (_) => setState(() {}),
                                  suffix: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (value) =>
                                      value == null || value.length < 3
                                          ? 'Mật khẩu tối thiểu 3 ký tự'
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                _PasswordStrength(strength: _passwordStrength),
                                const SizedBox(height: 13),
                                AuthTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Xác nhận mật khẩu',
                                  hint: 'Nhập lại mật khẩu',
                                  icon: Icons.lock_reset_rounded,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  suffix: IconButton(
                                    tooltip: _obscureConfirmPassword
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    icon: Icon(_obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                  validator: (value) =>
                                      value != _passwordController.text
                                          ? 'Mật khẩu xác nhận không khớp'
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _agreeTerms,
                                  onChanged: (value) => setState(
                                      () => _agreeTerms = value ?? false),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: const Color(0xFF00616E),
                                  title: const Text.rich(
                                    TextSpan(
                                      text: 'Tôi đồng ý với ',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF3E484B)),
                                      children: [
                                        TextSpan(
                                            text: 'Điều khoản dịch vụ',
                                            style: TextStyle(
                                                color: Color(0xFF00616E),
                                                fontWeight: FontWeight.w600)),
                                        TextSpan(text: ' và '),
                                        TextSpan(
                                            text: 'Chính sách bảo mật',
                                            style: TextStyle(
                                                color: Color(0xFF00616E),
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) => SizedBox(
                                    height: 52,
                                    child: FilledButton.icon(
                                      onPressed: state.isLoading
                                          ? null
                                          : _onRegisterPressed,
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
                                          ? 'Đang gửi mã...'
                                          : 'Gửi mã xác thực OTP'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF00616E),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text('Đã có tài khoản? ',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B))),
                              TextButton(
                                onPressed: _openLogin,
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 44)),
                                child: const Text('Đăng nhập ngay',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF00616E))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE7EEFF),
                              borderRadius: BorderRadius.circular(15)),
                          child: const Row(
                            children: [
                              Icon(Icons.local_parking_rounded,
                                  color: Color(0xFF00616E), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tìm chỗ tự động và giữ vị trí',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111C2D))),
                                    SizedBox(height: 3),
                                    Text(
                                        'Nhận diện biển số, thanh toán nhanh chóng',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF3E484B))),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }

  void _keepRegister() {}

  void _openLogin() => context.goNamed(RouteNames.login);
}

class _PasswordStrength extends StatelessWidget {
  final int strength;

  const _PasswordStrength({required this.strength});

  @override
  Widget build(BuildContext context) {
    final label = switch (strength) {
      0 => 'Chưa nhập',
      1 => 'Yếu',
      2 => 'Trung bình',
      _ => 'Mạnh',
    };
    final color =
        strength < 2 ? const Color(0xFFBA1A1A) : const Color(0xFF087B8C);

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('Độ bảo mật mật khẩu',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: strength == 0 ? const Color(0xFF64748B) : color)),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: List.generate(
              3,
              (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color:
                            index < strength ? color : const Color(0xFFE7EEFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )),
        ),
      ],
    );
  }
}

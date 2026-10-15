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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthLoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) =>
              b.errorMessage != null &&
              a.errorMessage != b.errorMessage &&
              (ModalRoute.of(context)?.isCurrent ?? false),
      listener: (context, state) {
        showAuthMessage(context, state.errorMessage!);
        context.read<AuthBloc>().add(AuthClearMessageRequested());
      },
      child: AuthScaffold(
        title: 'Đăng nhập',
        subtitle: 'Xem chỗ trống, giữ chỗ và quản lý vé xe của bạn.',
        children: [
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'ban@gmail.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Nhập email đã đăng ký' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    suffix: ObscureToggle(
                      obscured: _obscure,
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v ?? '').isEmpty ? 'Nhập mật khẩu' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (a, b) => a.isLoading != b.isLoading,
                    builder: (context, state) => AuthSubmitButton(
                      label: 'Đăng nhập',
                      busyLabel: 'Đang đăng nhập',
                      busy: state.isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Chưa có tài khoản?', style: t.bodyMedium?.copyWith(color: p.textSecondary)),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.register),
                child: const Text('Tạo tài khoản'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

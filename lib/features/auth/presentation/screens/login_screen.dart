import '../../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          AuthLoginSubmitted(
              email: _email.text.trim(), password: _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthLayout(
          showBrand: true,
          title: context.l10n.loginTitle,
          subtitle: context.l10n.loginSubtitle,
          children: [
            if (state.status == AuthStatus.failure) ...[
              InlineMessage((state.errorMessage ?? '').isEmpty
                  ? context.l10n.loginFailed
                  : state.errorMessage!),
              const SizedBox(height: AppSpacing.lg),
            ] else if (state.registeredSuccess ||
                state.resetPasswordSuccess) ...[
              InlineMessage(
                state.resetPasswordSuccess
                    ? context.l10n.loginPasswordReset
                    : context.l10n.loginRegistered,
                isError: false,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  children: [
                    AppTextField(
                      label: context.l10n.fieldEmail,
                      controller: _email,
                      hint: 'ten@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => Validators.email(context.l10n, v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.fieldPassword,
                      controller: _password,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => Validators.password(context.l10n, v),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: context.l10n.loginForgot,
                onPressed: () => context.push(RouteNames.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: context.l10n.loginSubmit,
                loading: state.isLoading,
                onPressed: _submit),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.l10n.loginNoAccount,
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary)),
                AppButton.text(
                  label: context.l10n.loginRegister,
                  onPressed: () => context.push(RouteNames.register),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

import '../../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    for (final c in [
      _userName,
      _fullName,
      _email,
      _phone,
      _password,
      _confirm
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitted = true;
    context.read<AuthBloc>().add(AuthSendRegisterOtpSubmitted(
          userName: _userName.text.trim(),
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phoneNumber: _phone.text.trim(),
          password: _password.text,
          confirmPassword: _confirm.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, cur) => prev.status != cur.status,
      listener: (context, state) {
        if (_submitted &&
            state.otpSent &&
            state.status == AuthStatus.unauthenticated) {
          _submitted = false;
          context.push(RouteNames.verifyOtp, extra: {
            'email': _email.text.trim(),
            'isResetPassword': false,
          });
        }
      },
      builder: (context, state) {
        return AuthLayout(
          showBack: true,
          title: context.l10n.registerTitle,
          subtitle: context.l10n.registerSubtitle,
          children: [
            if (state.status == AuthStatus.failure) ...[
              InlineMessage((state.errorMessage ?? '').isEmpty
                  ? context.l10n.otpSendFailed
                  : state.errorMessage!),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: context.l10n.fieldFullName,
                    controller: _fullName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => Validators.fullName(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldUserName,
                    controller: _userName,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    validator: (v) => Validators.userName(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    label: context.l10n.fieldPhone,
                    controller: _phone,
                    hint: '0912345678',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                    ],
                    validator: (v) => Validators.phone(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldPassword,
                    controller: _password,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => Validators.password(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldPasswordConfirm,
                    controller: _confirm,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirmPassword(
                        context.l10n, v, _password.text),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
                label: context.l10n.registerSubmit,
                loading: state.isLoading,
                onPressed: _submit),
          ],
        );
      },
    );
  }
}

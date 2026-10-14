import '../../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitted = true;
    context
        .read<AuthBloc>()
        .add(AuthRequestResetPasswordSubmitted(email: _email.text.trim()));
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
            'isResetPassword': true,
          });
        }
      },
      builder: (context, state) => AuthLayout(
        showBack: true,
        title: context.l10n.forgotTitle,
        subtitle: context.l10n.forgotSubtitle,
        children: [
          if (state.status == AuthStatus.failure) ...[
            InlineMessage((state.errorMessage ?? '').isEmpty
                ? context.l10n.resetRequestFailed
                : state.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          Form(
            key: _formKey,
            child: AppTextField(
              label: context.l10n.fieldEmail,
              controller: _email,
              hint: 'ten@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: (v) => Validators.email(context.l10n, v),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
              label: context.l10n.forgotSubmit,
              loading: state.isLoading,
              onPressed: _submit),
        ],
      ),
    );
  }
}

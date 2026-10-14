import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../data/profile_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProfileRepository>().update(password: _password.text);
      if (!mounted) return;
      showAppSnack(context, context.l10n.pwdChanged);
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pwdTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xxxl),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.pwdNote,
                      style: AppTypography.bodySmall
                          .copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: context.l10n.fieldNewPassword,
                    controller: _password,
                    obscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => Validators.password(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldNewPasswordConfirm,
                    controller: _confirm,
                    obscure: true,
                    validator: (v) => Validators.confirmPassword(
                        context.l10n, v, _password.text),
                    onSubmitted: (_) => _save(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineMessage(_error!),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                      label: context.l10n.pwdSubmit,
                      loading: _saving,
                      onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

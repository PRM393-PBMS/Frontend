import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/blocs/auth_bloc.dart';
import '../../auth/presentation/blocs/auth_event.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = context.read<AuthBloc>().state.user;
  late final _fullName = TextEditingController(text: _user?.fullName ?? '');
  late final _phone = TextEditingController(text: _user?.phoneNumber ?? '');
  late final _email = TextEditingController(text: _user?.email ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthBloc>();
    try {
      final updated = await context.read<ProfileRepository>().update(
            fullName: _fullName.text,
            phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text,
            email: _email.text,
          );
      auth.add(AuthProfileUpdated(updated));
      if (!mounted) return;
      showAppSnack(context, context.l10n.profileUpdated);
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
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
                  AppTextField(
                    label: context.l10n.fieldFullName,
                    controller: _fullName,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.fullName(context.l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldPhone,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
                    ],
                    validator: (v) =>
                        Validators.phone(context.l10n, v, optional: true),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.fieldEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    helper: context.l10n.profileEmailHelper,
                    validator: (v) => Validators.email(context.l10n, v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineMessage(_error!),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                      label: context.l10n.profileSave,
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

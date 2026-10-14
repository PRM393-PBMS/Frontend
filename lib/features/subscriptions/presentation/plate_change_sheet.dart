import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';

/// Sheet nhập biển số mới + lý do. [onSubmit] ném lỗi để hiển thị tại chỗ.
class PlateChangeSheet extends StatefulWidget {
  final String title;
  final String currentPlate;
  final String? initialPlate;
  final String? initialReason;
  final Future<void> Function(String plate, String reason) onSubmit;

  const PlateChangeSheet({
    super.key,
    required this.title,
    required this.currentPlate,
    required this.onSubmit,
    this.initialPlate,
    this.initialReason,
  });

  @override
  State<PlateChangeSheet> createState() => _PlateChangeSheetState();
}

class _PlateChangeSheetState extends State<PlateChangeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _plate = TextEditingController(text: widget.initialPlate ?? '');
  late final _reason = TextEditingController(text: widget.initialReason ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_plate.text, _reason.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: AppTypography.title.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.plateSheetCurrent(widget.currentPlate),
                style:
                    AppTypography.bodySmall.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: context.l10n.plateNew,
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [PlateInputFormatter()],
              style: AppTypography.mono
                  .copyWith(fontSize: 17, color: p.textPrimary),
              validator: (v) {
                final err = Validators.plate(context.l10n, v);
                if (err != null) return err;
                if (Validators.normalizePlate(v ?? '') == widget.currentPlate) {
                  return context.l10n.vPlateSame;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: context.l10n.plateReason,
              controller: _reason,
              maxLines: 3,
              maxLength: 500,
              validator: (v) => Validators.maxLength(
                  context.l10n, v, 500, context.l10n.plateReasonField),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineMessage(_error!),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
                label: context.l10n.plateSend,
                loading: _busy,
                onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

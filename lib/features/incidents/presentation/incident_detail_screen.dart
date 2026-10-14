import '../../../core/l10n/locale_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/blocs/auth_bloc.dart';
import '../data/incident_repository.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;

  /// Nhân viên: có thể nhận xử lý và đánh dấu đã xử lý.
  final bool staffMode;

  const IncidentDetailScreen(
      {super.key, required this.incidentId, this.staffMode = false});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late final IncidentRepository _repo = context.read<IncidentRepository>();
  late final DataCubit<IncidentReport> _cubit =
      DataCubit(() => _repo.byId(widget.incidentId))..load();
  bool _busy = false;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String get _myId => context.read<AuthBloc>().state.user?.id ?? '';

  Future<void> _assign() async {
    setState(() => _busy = true);
    try {
      await _repo.assign(widget.incidentId, _myId);
      if (mounted) showAppSnack(context, context.l10n.incAssigned);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _cubit.refresh();
    }
  }

  Future<void> _resolve() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResolveSheet(
        onSubmit: (notes) => _repo.resolve(widget.incidentId, _myId, notes),
      ),
    );
    if (done == true) {
      if (mounted) showAppSnack(context, context.l10n.incResolvedToast);
      _cubit.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.incDetailTitle)),
      body: LoadStateView<IncidentReport>(
        cubit: _cubit,
        builder: (context, i) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(StatusLabels.incident(context.l10n, i.status)),
                  const SizedBox(height: AppSpacing.md),
                  Text(i.issueType,
                      style:
                          AppTypography.title.copyWith(color: p.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(i.description,
                      style:
                          AppTypography.body.copyWith(color: p.textSecondary)),
                  if (i.proofImageUrl != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ClipRRect(
                      borderRadius: AppSpacing.control,
                      child: CachedNetworkImage(
                        imageUrl: i.proofImageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(height: 220, color: p.surfaceMuted),
                        errorWidget: (_, __, ___) => Container(
                          height: 120,
                          color: p.surfaceMuted,
                          alignment: Alignment.center,
                          child: Text(context.l10n.incImageFailed,
                              style: AppTypography.caption
                                  .copyWith(color: p.textMuted)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              child: Column(
                children: [
                  if (i.reporterName != null)
                    KeyValueRow(context.l10n.incReporter, i.reporterName!),
                  KeyValueRow(
                      context.l10n.incLinkedSession,
                      i.sessionId != null
                          ? context.l10n.commonYes
                          : context.l10n.commonNo),
                  KeyValueRow(context.l10n.incHandler,
                      i.handledByStaffName ?? context.l10n.incUnassigned),
                  if (i.resolvedAt != null)
                    KeyValueRow(context.l10n.incResolvedAt,
                        DateFormatter.formatDateTime(i.resolvedAt)),
                ],
              ),
            ),
            if (i.resolutionNotes != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppSurface(
                color: p.successSoft,
                borderColor: p.successSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.incResult,
                        style:
                            AppTypography.label.copyWith(color: p.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(i.resolutionNotes!,
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textPrimary)),
                  ],
                ),
              ),
            ],
            if (widget.staffMode && !i.isResolved) ...[
              const SizedBox(height: AppSpacing.xl),
              if (i.handledByStaffId != _myId)
                AppButton(
                  label: i.handledByStaffId == null
                      ? context.l10n.incTake
                      : context.l10n.incTakeOver,
                  icon: Icons.assignment_ind_outlined,
                  loading: _busy,
                  onPressed: _assign,
                ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: context.l10n.incMarkResolved,
                icon: Icons.task_alt_rounded,
                onPressed: _busy ? null : _resolve,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResolveSheet extends StatefulWidget {
  final Future<void> Function(String notes) onSubmit;

  const _ResolveSheet({required this.onSubmit});

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_notes.text);
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
            Text(context.l10n.incResult,
                style: AppTypography.title.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: context.l10n.incNotes,
              controller: _notes,
              maxLines: 4,
              hint: context.l10n.incNotesHint,
              validator: (v) => Validators.required(
                  context.l10n, v, context.l10n.incNotesField),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineMessage(_error!),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
                label: context.l10n.incConfirmResolved,
                loading: _busy,
                onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../../sessions/data/session_repository.dart';
import '../data/incident_repository.dart';

class CreateIncidentScreen extends StatefulWidget {
  final String? sessionId;

  const CreateIncidentScreen({super.key, this.sessionId});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _type = TextEditingController();
  final _description = TextEditingController();
  List<ParkingSession> _sessions = const [];
  late String? _sessionId = widget.sessionId;
  UploadFile? _photo;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<SessionRepository>().mine().then((list) {
      if (mounted) setState(() => _sessions = list.take(10).toList());
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _type.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file =
        await ImageCapture.pick(context, title: context.l10n.incPhotoTitle);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = context.read<IncidentRepository>();
    try {
      String? proofUrl;
      if (_photo != null) proofUrl = await repo.uploadProof(_photo!);
      final created = await repo.create(
        issueType: _type.text,
        description: _description.text,
        sessionId: _sessionId,
        proofImageUrl: proofUrl,
      );
      if (!mounted) return;
      showAppSnack(context, context.l10n.incSent);
      context.pushReplacement(RouteNames.incidentDetail(created.id));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sessionIds = _sessions.map((s) => s.id).toSet();
    final suggestions = [
      context.l10n.incSuggestCollision,
      context.l10n.incSuggestFee,
      context.l10n.incSuggestLost,
      context.l10n.incSuggestNoSpace
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.incNewTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.sm, AppSpacing.page, 140),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: context.l10n.incType,
                    controller: _type,
                    validator: (v) =>
                        Validators.required(
                            context.l10n, v, context.l10n.incTypeField) ??
                        Validators.maxLength(
                            context.l10n, v, 255, context.l10n.incType),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in suggestions)
                        ActionChip(
                            label: Text(s),
                            onPressed: () => setState(() => _type.text = s)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: context.l10n.incDescription,
                    controller: _description,
                    hint: context.l10n.incDescriptionHint,
                    maxLines: 5,
                    validator: (v) => Validators.required(
                        context.l10n, v, context.l10n.incDescriptionField),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(context.l10n.incSession,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue:
                        sessionIds.contains(_sessionId) || _sessionId == null
                            ? _sessionId
                            : null,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(context.l10n.incNoSession)),
                      if (_sessionId != null &&
                          !sessionIds.contains(_sessionId))
                        DropdownMenuItem<String?>(
                            value: _sessionId,
                            child: Text(context.l10n.incSelectedSession)),
                      for (final s in _sessions)
                        DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(
                              '${s.licensePlateIn}, ${DateFormatter.formatRelativeDay(context.l10n, s.entryTime)}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _sessionId = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(context.l10n.incPhotoTitle,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  if (_photo == null)
                    AppButton.secondary(
                      label: context.l10n.incAddPhoto,
                      icon: Icons.add_a_photo_outlined,
                      onPressed: _pickPhoto,
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppSpacing.surface,
                          child: Image.memory(_photo!.bytes,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: IconButton.filledTonal(
                            tooltip: context.l10n.incRemovePhoto,
                            onPressed: () => setState(() => _photo = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InlineMessage(_error!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
          child: ContentWidth(
            child: AppButton(
                label: context.l10n.incSubmit,
                loading: _submitting,
                onPressed: _submit),
          ),
        ),
      ),
    );
  }
}

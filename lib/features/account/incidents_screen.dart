import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_tag.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';

/// Loại sự cố gửi lên backend (mã ổn định) và nhãn hiển thị.
const incidentTypes = <String, String>{
  'SlotOccupied': 'Ô đỗ bị chiếm',
  'VehicleDamage': 'Xe bị trầy xước, hư hỏng',
  'GateError': 'Barie / đầu đọc lỗi',
  'PaymentIssue': 'Sai phí hoặc lỗi thanh toán',
  'LostTicket': 'Mất vé, không quét được mã',
  'Other': 'Vấn đề khác',
};

String incidentLabel(String code) => incidentTypes[code] ?? code;

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  late final _items = AsyncCubit(context.read<PbmsRepository>().getMyIncidents);

  @override
  void dispose() {
    _items.close();
    super.dispose();
  }

  Future<void> _report() async {
    final sent = await ReportIncidentSheet.show(context);
    if (sent == true) _items.load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo sự cố')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _report,
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Báo sự cố'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _items.load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            Text(
              'Bãi xe tiếp nhận và phản hồi trong giờ vận hành. Kèm ảnh để xử lý nhanh hơn.',
              style: t.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<AsyncCubit<List<IncidentModel>>, AsyncState<List<IncidentModel>>>(
              bloc: _items,
              builder: (context, st) => AsyncView(
                state: st,
                onRetry: _items.load,
                isEmpty: (d) => d.isEmpty,
                empty: const EmptyState(
                  icon: Icons.verified_user_outlined,
                  title: 'Chưa có báo cáo nào',
                  message: 'Nếu gặp vấn đề trong bãi, nhấn "Báo sự cố" để gửi cho đội vận hành.',
                ),
                builder: (items) => Column(
                  children: [
                    for (final it in items) ...[
                      _IncidentTile(
                        item: it,
                        onTap: () async {
                          await IncidentDetailSheet.show(context, it.incidentId);
                          _items.load();
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final IncidentModel item;
  final VoidCallback? onTap;

  const _IncidentTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return AppPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(incidentLabel(item.issueType), style: t.titleSmall)),
              StatusTag.of(StatusInfo.incident(item.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.description, style: t.bodyMedium?.copyWith(color: p.textSecondary)),
          if (item.proofImageUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppSpacing.roundedMd,
              child: Image.network(
                item.proofImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Ảnh minh chứng sự cố',
                errorBuilder: (_, __, ___) => Container(
                  height: 56,
                  color: p.surfaceRaised,
                  alignment: Alignment.center,
                  child: Text('Không tải được ảnh', style: t.bodySmall),
                ),
              ),
            ),
          ],
          if (item.resolutionNotes != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.okSoft, borderRadius: AppSpacing.roundedMd),
              child: Text(
                'Phản hồi${item.handledByStaffFullName != null ? ' từ ${item.handledByStaffFullName}' : ''}: '
                '${item.resolutionNotes}'
                '${item.resolvedAt != null ? '\n${DateFormatter.formatDateTime(item.resolvedAt)}' : ''}',
                style: t.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chi tiết sự cố, tải mới từ `GET /api/IncidentReport/:id`.
class IncidentDetailSheet extends StatefulWidget {
  final String incidentId;

  const IncidentDetailSheet({super.key, required this.incidentId});

  static Future<void> show(BuildContext context, String incidentId) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => IncidentDetailSheet(incidentId: incidentId),
      );

  @override
  State<IncidentDetailSheet> createState() => _IncidentDetailSheetState();
}

class _IncidentDetailSheetState extends State<IncidentDetailSheet> {
  late final _item = AsyncCubit(() => context.read<PbmsRepository>().getIncident(widget.incidentId));

  @override
  void dispose() {
    _item.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chi tiết sự cố', style: t.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<AsyncCubit<IncidentModel>, AsyncState<IncidentModel>>(
            bloc: _item,
            builder: (context, st) => AsyncView(
              state: st,
              onRetry: _item.load,
              loading: const SkeletonCard(height: 140),
              builder: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IncidentTile(item: item),
                  if (item.resolutionNotes == null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Đội vận hành chưa phản hồi. Bạn sẽ nhận thông báo khi có cập nhật.',
                      style: t.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Biểu mẫu báo sự cố, có thể gắn với một lượt gửi xe.
class ReportIncidentSheet extends StatefulWidget {
  final String? sessionId;

  const ReportIncidentSheet({super.key, this.sessionId});

  static Future<bool?> show(BuildContext context, {String? sessionId}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ReportIncidentSheet(sessionId: sessionId),
      );

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  String _type = incidentTypes.keys.first;
  Uint8List? _photo;
  String _photoName = 'proof.jpg';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoName = file.name;
      });
    } catch (_) {
      if (mounted) showSnack(context, 'Không mở được máy ảnh hoặc thư viện ảnh.', error: true);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final repo = context.read<PbmsRepository>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? url;
      if (_photo != null) url = await repo.uploadIncidentProof(_photo!, _photoName);
      await repo.createIncident(
        issueType: _type,
        description: _desc.text.trim(),
        sessionId: widget.sessionId,
        proofImageUrl: url,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showSnack(context, 'Đã gửi báo cáo. Đội vận hành sẽ liên hệ khi xử lý.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Báo sự cố', style: t.headlineSmall),
              if (widget.sessionId != null) ...[
                const SizedBox(height: 4),
                Text('Gắn với lượt gửi xe đang xem.',
                    style: t.bodyMedium?.copyWith(color: p.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.xl),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Loại sự cố'),
                items: [
                  for (final e in incidentTypes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Vị trí, thời điểm, điều bạn thấy',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v ?? '').trim().length < 10 ? 'Mô tả ít nhất 10 ký tự' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_photo != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppSpacing.roundedMd,
                      child: Image.memory(_photo!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        tooltip: 'Bỏ ảnh',
                        onPressed: () => setState(() => _photo = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 20),
                        label: const Text('Chụp ảnh'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text('Chọn ảnh'),
                      ),
                    ),
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: t.bodyMedium?.copyWith(color: p.danger)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Gửi báo cáo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

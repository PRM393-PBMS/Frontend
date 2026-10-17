import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Loại sự cố gửi lên backend (mã ổn định) và nhãn hiển thị.
const incidentTypes = <String, String>{
  'SlotOccupied': 'Ô đỗ bị chiếm',
  'VehicleDamage': 'Xe bị trầy xước, hư hỏng',
  'GateError': 'Barie hoặc đầu đọc lỗi',
  'PaymentIssue': 'Sai phí hoặc lỗi thanh toán',
  'LostTicket': 'Mất vé, không quét được mã',
  'Other': 'Vấn đề khác',
};

String incidentLabel(String code) => incidentTypes[code] ?? code;

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const IncidentsScreen()));

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  late final _items =
      AsyncCubit(context.read<PbmsRepository>().getMyIncidents);

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Báo cáo sự cố',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _report,
        backgroundColor: PbmsTokens.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Báo sự cố'),
      ),
      body: RefreshIndicator(
        color: PbmsTokens.teal,
        onRefresh: () async => _items.load(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 14, 16, 96 + bottomInset),
              children: [
                const Text(
                  'Nhân viên bãi tiếp nhận và phản hồi trong giờ vận hành. Kèm ảnh để xử lý nhanh hơn.',
                  style: PbmsText.caption,
                ),
                const SizedBox(height: 14),
                PbmsAsync<List<IncidentModel>>(
                  cubit: _items,
                  loadingHeight: 120,
                  errorTitle: 'Không tải được báo cáo',
                  isEmpty: (d) => d.isEmpty,
                  empty: const PbmsEmptyView(
                    icon: Icons.verified_user_outlined,
                    title: 'Chưa có báo cáo nào',
                    message:
                        'Nếu gặp vấn đề trong bãi, nhấn "Báo sự cố" để gửi cho nhân viên vận hành.',
                  ),
                  builder: (items) => Column(
                    children: [
                      for (final it in items) ...[
                        _IncidentTile(
                          item: it,
                          onTap: () async {
                            await IncidentDetailSheet.show(
                                context, it.incidentId);
                            _items.load();
                          },
                        ),
                        const SizedBox(height: 11),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    final card = PbmsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(incidentLabel(item.issueType),
                      style: PbmsText.bodyStrong)),
              const SizedBox(width: 8),
              PbmsStatusPill(StatusInfo.incident(item.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.description, style: PbmsText.caption),
          if (item.proofImageUrl != null) ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.proofImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Ảnh minh chứng sự cố',
                errorBuilder: (_, __, ___) => Container(
                  height: 56,
                  color: PbmsTokens.surfaceLow,
                  alignment: Alignment.center,
                  child: const Text('Không tải được ảnh',
                      style: PbmsText.caption),
                ),
              ),
            ),
          ],
          if (item.resolutionNotes != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PbmsTokens.tealTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.handledByStaffFullName == null
                        ? 'Phản hồi của bãi'
                        : 'Phản hồi từ ${item.handledByStaffFullName}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PbmsTokens.teal),
                  ),
                  const SizedBox(height: 4),
                  Text(item.resolutionNotes!, style: PbmsText.body),
                  if (item.resolvedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(DateFormatter.formatDateTime(item.resolvedAt),
                        style: PbmsText.caption),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onTap, child: card);
  }
}

/// Chi tiết sự cố, tải mới từ `GET /api/IncidentReport/:id`.
class IncidentDetailSheet extends StatefulWidget {
  final String incidentId;

  const IncidentDetailSheet({super.key, required this.incidentId});

  static Future<void> show(BuildContext context, String incidentId) =>
      PbmsSheetFrame.show<void>(
          context, (_) => IncidentDetailSheet(incidentId: incidentId));

  @override
  State<IncidentDetailSheet> createState() => _IncidentDetailSheetState();
}

class _IncidentDetailSheetState extends State<IncidentDetailSheet> {
  late final _item = AsyncCubit(
      () => context.read<PbmsRepository>().getIncident(widget.incidentId));

  @override
  void dispose() {
    _item.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Chi tiết sự cố',
      children: [
        PbmsAsync<IncidentModel>(
          cubit: _item,
          loadingHeight: 140,
          builder: (item) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IncidentTile(item: item),
              if (item.resolutionNotes == null) ...[
                const SizedBox(height: 11),
                const Text(
                  'Nhân viên chưa phản hồi. Bạn sẽ nhận thông báo khi có cập nhật.',
                  style: PbmsText.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Biểu mẫu báo sự cố, có thể gắn với một lượt gửi xe.
class ReportIncidentSheet extends StatefulWidget {
  final String? sessionId;

  const ReportIncidentSheet({super.key, this.sessionId});

  static Future<bool?> show(BuildContext context, {String? sessionId}) =>
      PbmsSheetFrame.show<bool>(
          context, (_) => ReportIncidentSheet(sessionId: sessionId));

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
      final file = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoName = file.name;
      });
    } catch (_) {
      if (mounted) {
        showPbmsSnack(context, 'Không mở được máy ảnh hoặc thư viện ảnh.',
            error: true);
      }
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
      if (_photo != null) {
        url = await repo.uploadIncidentProof(_photo!, _photoName);
      }
      await repo.createIncident(
        issueType: _type,
        description: _desc.text.trim(),
        sessionId: widget.sessionId,
        proofImageUrl: url,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showPbmsSnack(
          context, 'Đã gửi báo cáo. Nhân viên sẽ liên hệ khi xử lý.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return PbmsSheetFrame(
      title: 'Báo sự cố',
      subtitle: widget.sessionId == null
          ? 'Mô tả vấn đề để nhân viên bãi hỗ trợ.'
          : 'Báo cáo được gắn với lượt gửi xe đang xem.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Loại sự cố', style: PbmsText.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: pbmsInputDecoration(),
                items: [
                  for (final e in incidentTypes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 14),
              const Text('Mô tả', style: PbmsText.label),
              const SizedBox(height: 6),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                maxLength: 1000,
                decoration:
                    pbmsInputDecoration(hint: 'Vị trí, thời điểm, điều bạn thấy'),
                validator: (v) => (v ?? '').trim().length < 10
                    ? 'Mô tả ít nhất 10 ký tự'
                    : null,
              ),
              const SizedBox(height: 6),
              const Text('Ảnh minh chứng (không bắt buộc)',
                  style: PbmsText.label),
              const SizedBox(height: 6),
              if (photo != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(photo,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover),
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
                      child: _photoButton(Icons.photo_camera_outlined,
                          'Chụp ảnh', () => _pick(ImageSource.camera)),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _photoButton(Icons.photo_library_outlined,
                          'Chọn ảnh', () => _pick(ImageSource.gallery)),
                    ),
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
              ],
              const SizedBox(height: 18),
              PbmsPrimaryButton(
                  label: 'Gửi báo cáo', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: PbmsTokens.ink,
        side: const BorderSide(color: PbmsTokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

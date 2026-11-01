import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/vehicles/presentation/widgets/vehicle_picker.dart';

/// Gửi xe một lần: đăng ký trước biển số một xe, tới cổng camera đọc biển số là vào được.
/// Mã QR đi kèm chỉ để dự phòng khi camera không đọc được biển. Dùng một lần trong 24 giờ.
class EntryPassScreen extends StatefulWidget {
  const EntryPassScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EntryPassScreen()));

  @override
  State<EntryPassScreen> createState() => _EntryPassScreenState();
}

class _EntryPassScreenState extends State<EntryPassScreen> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _passes = AsyncCubit<List<EntryPassModel>>(_repo.getMyEntryPasses);
  VehicleModel? _vehicle;
  bool _busy = false;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Cập nhật thời gian còn lại và tự chuyển sang "đã dùng" khi xe vừa vào cổng.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _passes.load();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _passes.close();
    super.dispose();
  }

  Future<void> _create() async {
    final v = _vehicle;
    if (v == null) {
      setState(() => _error = 'Chọn xe cần tạo mã.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.createEntryPass(v.id);
      await _passes.load();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(EntryPassModel pass) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ đăng ký gửi xe?'),
        content: Text('Xe ${pass.licensePlate} sẽ không vào bãi bằng đăng ký này nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Huỷ đăng ký'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.cancelEntryPass(pass.id);
      await _passes.load();
      if (mounted) showPbmsSnack(context, 'Đã huỷ đăng ký.');
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: const Text('Gửi xe 1 lần',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PbmsTokens.ink)),
      ),
      body: BlocBuilder<AsyncCubit<List<EntryPassModel>>, AsyncState<List<EntryPassModel>>>(
        bloc: _passes,
        builder: (context, st) {
          if (st.status == AsyncStatus.error && st.data == null) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PbmsErrorView(title: 'Chưa tải được đăng ký gửi xe', message: st.error ?? '', onRetry: _passes.load),
              ],
            );
          }
          if (st.data == null) {
            return const Padding(padding: EdgeInsets.all(20), child: PbmsLoadingBox(height: 320));
          }
          final active = st.data!.where((p) => p.isActive).toList();
          final recent = st.data!.where((p) => !p.isActive).take(5).toList();
          return RefreshIndicator(
            color: PbmsTokens.teal,
            onRefresh: _passes.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + bottom),
              children: [
                for (final p in active) ...[
                  _ActivePass(pass: p, onCancel: () => _cancel(p)),
                  const SizedBox(height: 16),
                ],
                PbmsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(active.isEmpty ? 'Đăng ký gửi xe' : 'Đăng ký cho xe khác',
                          style: PbmsText.title),
                      const SizedBox(height: 4),
                      const Text(
                        'Tới cổng vào, camera đọc biển số là xe được vào, không cần mở mã. '
                        'Đăng ký dùng một lần, hiệu lực 24 giờ; đăng ký lại cho cùng xe sẽ huỷ đăng ký cũ.',
                        style: PbmsText.caption,
                      ),
                      const SizedBox(height: 14),
                      VehiclePicker(
                        selectedId: _vehicle?.id,
                        emptyMessage: 'Thêm xe để đăng ký gửi xe.',
                        onChanged: (v) => setState(() {
                          _vehicle = v;
                          _error = null;
                        }),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: PbmsText.caption.copyWith(color: PbmsTokens.danger)),
                      ],
                      const SizedBox(height: 14),
                      PbmsPrimaryButton(
                        label: 'Đăng ký gửi xe',
                        icon: Icons.how_to_reg_rounded,
                        busy: _busy,
                        onPressed: _create,
                      ),
                    ],
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const PbmsSectionTitle('Đăng ký gần đây'),
                  for (final p in recent) _PastPass(pass: p),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivePass extends StatelessWidget {
  final EntryPassModel pass;
  final VoidCallback onCancel;

  const _ActivePass({required this.pass, required this.onCancel});

  /// Camera ở cổng không đọc được biển số (biển bẩn, mờ, mất điện camera):
  /// đưa mã QR hoặc đọc mã chữ cho nhân viên.
  void _showBackupQr(BuildContext context) => PbmsQrDialog.show(
        context,
        title: 'Mã QR dự phòng vào bãi',
        payload: pass.qrPayload ?? '',
        plate: pass.licensePlate,
        isMotorbike: pass.isMotorbike,
        code: pass.code,
        rows: [
          (Icons.info_outline_rounded, 'Dùng khi', 'Camera không đọc được biển số'),
          (Icons.timer_outlined, 'Hết hạn', DateFormatter.formatDateTime(pass.expiresAt)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final left = pass.expiresAt.difference(DateTime.now());
    final leftText = left.inHours >= 1
        ? 'Còn ${left.inHours} giờ ${left.inMinutes % 60} phút'
        : 'Còn ${left.inMinutes.clamp(0, 59)} phút';
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      borderColor: PbmsTokens.tealLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  [pass.vehicleName, pass.vehicleTypeName].whereType<String>().join(', '),
                  style: PbmsText.caption,
                ),
              ),
              const PbmsStatusPill(StatusInfo('Sẵn sàng vào bãi', PbmsTokens.ok)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              label: 'Biển số đã đăng ký ${pass.licensePlate}',
              child: PbmsPlate(licensePlate: pass.licensePlate, isMotorbike: pass.isMotorbike, fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.photo_camera_outlined, size: 18, color: PbmsTokens.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lái xe tới cổng vào, camera đọc biển số là xe được vào. Không cần mở mã.',
                  style: PbmsText.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$leftText, hết hạn ${DateFormatter.formatDateTime(pass.expiresAt)}', style: PbmsText.caption),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: pass.qrPayload == null ? null : () => _showBackupQr(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: PbmsTokens.teal,
              side: const BorderSide(color: PbmsTokens.tealLine),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
            label: const Text('Mã QR dự phòng'),
          ),
          const SizedBox(height: 2),
          Center(
            child: TextButton.icon(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger, minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('Huỷ đăng ký'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastPass extends StatelessWidget {
  final EntryPassModel pass;

  const _PastPass({required this.pass});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (pass.status.toLowerCase()) {
      'used' => ('Đã dùng', PbmsTokens.teal),
      'cancelled' => ('Đã huỷ', PbmsTokens.muted),
      _ => ('Hết hạn', PbmsTokens.warn),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PbmsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pass.licensePlate, style: PbmsText.bodyStrong),
                  Text(
                    pass.usedAt != null
                        ? 'Vào bãi ${DateFormatter.formatDateTime(pass.usedAt!)}'
                        : 'Tạo ${DateFormatter.formatDateTime(pass.createdAt)}',
                    style: PbmsText.caption,
                  ),
                ],
              ),
            ),
            PbmsStatusPill(StatusInfo(label, color)),
          ],
        ),
      ),
    );
  }
}

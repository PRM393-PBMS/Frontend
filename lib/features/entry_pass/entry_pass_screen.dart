import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/vehicles/presentation/widgets/vehicle_picker.dart';

/// Mã QR gửi xe một lần: tạo cho một xe, đưa ra ở cổng vào, dùng một lần trong 24 giờ.
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
        title: const Text('Huỷ mã vào bãi?'),
        content: Text('Mã của xe ${pass.licensePlate} sẽ không dùng được nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger),
            child: const Text('Huỷ mã'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.cancelEntryPass(pass.id);
      await _passes.load();
      if (mounted) showPbmsSnack(context, 'Đã huỷ mã.');
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
        title: const Text('Mã QR gửi xe 1 lần',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PbmsTokens.ink)),
      ),
      body: BlocBuilder<AsyncCubit<List<EntryPassModel>>, AsyncState<List<EntryPassModel>>>(
        bloc: _passes,
        builder: (context, st) {
          if (st.status == AsyncStatus.error && st.data == null) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PbmsErrorView(title: 'Chưa dùng được mã QR', message: st.error ?? '', onRetry: _passes.load),
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
                      Text(active.isEmpty ? 'Tạo mã vào bãi' : 'Tạo mã cho xe khác',
                          style: PbmsText.title),
                      const SizedBox(height: 4),
                      const Text(
                        'Đưa mã cho camera hoặc nhân viên ở cổng vào. Mã dùng một lần, hiệu lực 24 giờ; '
                        'tạo mã mới cho cùng xe sẽ huỷ mã cũ.',
                        style: PbmsText.caption,
                      ),
                      const SizedBox(height: 14),
                      VehiclePicker(
                        selectedId: _vehicle?.id,
                        emptyMessage: 'Thêm xe để tạo mã vào bãi.',
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
                        label: 'Tạo mã QR',
                        icon: Icons.qr_code_2_rounded,
                        busy: _busy,
                        onPressed: _create,
                      ),
                    ],
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const PbmsSectionTitle('Mã gần đây'),
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

  @override
  Widget build(BuildContext context) {
    final left = pass.expiresAt.difference(DateTime.now());
    final leftText = left.inHours >= 1
        ? 'Còn ${left.inHours} giờ ${left.inMinutes % 60} phút'
        : 'Còn ${left.inMinutes.clamp(0, 59)} phút';
    final size = (MediaQuery.sizeOf(context).width - 120).clamp(180.0, 260.0);
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      borderColor: PbmsTokens.tealLine,
      child: Column(
        children: [
          Row(
            children: [
              Icon(pass.isMotorbike ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                  color: PbmsTokens.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pass.vehicleName ?? pass.licensePlate, style: PbmsText.title),
                    Text(
                      [if (pass.vehicleName != null) pass.licensePlate, pass.vehicleTypeName].join(', '),
                      style: PbmsText.caption,
                    ),
                  ],
                ),
              ),
              const PbmsStatusPill(StatusInfo('Còn hiệu lực', PbmsTokens.ok)),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Mã QR vào bãi của xe ${pass.licensePlate}, mã ${pass.code}',
            image: true,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PbmsTokens.border),
              ),
              child: QrImageView(
                data: pass.qrPayload ?? '',
                size: size,
                errorCorrectionLevel: QrErrorCorrectLevel.Q,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: PbmsTokens.ink),
                dataModuleStyle:
                    const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: PbmsTokens.ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Mã ngắn để nhân viên nhập tay khi máy quét không đọc được.
          Text(pass.code, style: PbmsText.figure(26).copyWith(letterSpacing: 6)),
          const SizedBox(height: 4),
          Text('$leftText, hết hạn ${DateFormatter.formatDateTime(pass.expiresAt)}',
              textAlign: TextAlign.center, style: PbmsText.caption),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: PbmsTokens.danger, minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Huỷ mã'),
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
                  Text('${pass.licensePlate}, mã ${pass.code}', style: PbmsText.bodyStrong),
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

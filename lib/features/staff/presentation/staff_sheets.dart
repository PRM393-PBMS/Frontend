import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_verdict.dart';

/// Chọn cổng đang đứng quét, nhóm theo tầng.
Future<GateModel?> showGatePickerSheet(BuildContext context, {String? selectedId}) {
  final repo = context.read<PbmsRepository>();
  return PbmsSheetFrame.show<GateModel>(
    context,
    (context) => _GatePicker(
      cubit: AsyncCubit<List<GateModel>>(repo.getGates),
      selectedId: selectedId,
    ),
  );
}

class _GatePicker extends StatefulWidget {
  final AsyncCubit<List<GateModel>> cubit;
  final String? selectedId;

  const _GatePicker({required this.cubit, this.selectedId});

  @override
  State<_GatePicker> createState() => _GatePickerState();
}

class _GatePickerState extends State<_GatePicker> {
  @override
  void dispose() {
    widget.cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Bạn đang đứng ở cổng nào?',
      subtitle: 'Ảnh chụp sẽ gửi tới web staff đang mở cổng này.',
      children: [
        PbmsAsync<List<GateModel>>(
          cubit: widget.cubit,
          loadingHeight: 240,
          errorTitle: 'Không tải được danh sách cổng',
          isEmpty: (gates) => gates.isEmpty,
          empty: const PbmsEmptyView(icon: Icons.sensor_door_outlined, title: 'Chưa có cổng nào'),
          builder: (gates) {
            final byFloor = <String, List<GateModel>>{};
            for (final g in gates) {
              byFloor.putIfAbsent(g.floorName, () => []).add(g);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in byFloor.entries)
                  PbmsSettingsGroup(
                    title: entry.key.isEmpty ? null : entry.key,
                    children: [
                      for (final g in entry.value)
                        PbmsSettingsRow(
                          icon: g.isExit ? Icons.logout_rounded : Icons.login_rounded,
                          iconColor: g.isExit ? PbmsTokens.warn : PbmsTokens.teal,
                          title: g.gateName,
                          detail: g.isExit ? 'Cổng ra' : 'Cổng vào',
                          trailing: g.gateId == widget.selectedId
                              ? const Icon(Icons.check_rounded, color: PbmsTokens.teal)
                              : null,
                          onTap: () => Navigator.of(context).pop(g),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Tài khoản nhân viên: tên, lượt quét gần đây, đăng xuất.
Future<void> showStaffMenuSheet(
  BuildContext context, {
  required String staffName,
  required VoidCallback onLogout,
}) {
  return PbmsSheetFrame.show<void>(
    context,
    (sheetContext) => PbmsSheetFrame(
      title: staffName.isEmpty ? 'Nhân viên' : staffName,
      subtitle: 'Máy quét biển số. Đối chiếu và mở cổng thực hiện trên web staff.',
      children: [
        PbmsSettingsGroup(
          children: [
            PbmsSettingsRow(
              icon: Icons.history_rounded,
              title: 'Lượt quét gần đây',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showRecentScansSheet(context);
              },
            ),
            PbmsSettingsRow(
              icon: Icons.logout_rounded,
              iconColor: PbmsTokens.danger,
              title: 'Đăng xuất',
              onTap: () {
                Navigator.of(sheetContext).pop();
                onLogout();
              },
            ),
          ],
        ),
      ],
    ),
  );
}

/// Lượt quét của tôi trên máy chủ (mới nhất trước) và web đã xử lý hay chưa.
Future<void> showRecentScansSheet(BuildContext context) {
  final repo = context.read<PbmsRepository>();
  return PbmsSheetFrame.show<void>(
    context,
    (context) => _RecentScans(cubit: AsyncCubit<List<GateScanModel>>(repo.getMyRecentGateScans)),
  );
}

class _RecentScans extends StatefulWidget {
  final AsyncCubit<List<GateScanModel>> cubit;

  const _RecentScans({required this.cubit});

  @override
  State<_RecentScans> createState() => _RecentScansState();
}

class _RecentScansState extends State<_RecentScans> {
  @override
  void dispose() {
    widget.cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PbmsSheetFrame(
      title: 'Lượt quét gần đây',
      children: [
        PbmsAsync<List<GateScanModel>>(
          cubit: widget.cubit,
          loadingHeight: 300,
          errorTitle: 'Không tải được lượt quét',
          isEmpty: (items) => items.isEmpty,
          empty: const PbmsEmptyView(
            icon: Icons.document_scanner_outlined,
            title: 'Chưa có lượt quét nào',
            message: 'Ảnh bạn chụp ở cổng sẽ hiện ở đây.',
          ),
          builder: (items) => PbmsCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: PbmsTokens.divider),
                  _ScanRow(scan: items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanRow extends StatelessWidget {
  final GateScanModel scan;

  const _ScanRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    final verdict = ScanVerdict.of(scan);
    final src = resolveMediaUrl(scan.imageUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 42,
              child: src == null
                  ? const ColoredBox(color: PbmsTokens.divider)
                  : CachedNetworkImage(
                      imageUrl: src,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(color: PbmsTokens.divider),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.licensePlate ?? 'Chưa đọc được', style: PbmsText.bodyStrong),
                const SizedBox(height: 2),
                Text(verdict.label, style: PbmsText.caption.copyWith(color: verdict.color)),
                const SizedBox(height: 2),
                Text('${scan.gateName} · ${DateFormat('HH:mm dd/MM').format(scan.capturedAt)}',
                    style: PbmsText.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            scan.isHandled
                ? 'Web đã xử lý'
                : scan.isDismissed
                    ? 'Web bỏ qua'
                    : 'Chờ web',
            style: PbmsText.caption.copyWith(
              color: scan.isHandled ? PbmsTokens.ok : PbmsTokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/utils/media_url.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/exit_payment_sheet.dart';
import 'package:prm393_frontend/features/history/presentation/widgets/gate_payment_sheet.dart';
import 'package:prm393_frontend/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';

/// Chi tiết một lượt gửi xe: phí tạm tính, mã QR ra cổng, thanh toán.
class SessionDetailSheet extends StatefulWidget {
  final ParkingSessionModel session;

  const SessionDetailSheet({super.key, required this.session});

  static Future<void> show(BuildContext context, ParkingSessionModel session) =>
      PbmsSheetFrame.show<void>(
          context, (_) => SessionDetailSheet(session: session));

  @override
  State<SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<SessionDetailSheet> {
  AsyncCubit<FeePreviewModel>? _fee;
  late ExitPassModel? _exitPass = widget.session.exitPass;

  ParkingSessionModel get s => widget.session;

  @override
  void initState() {
    super.initState();
    if (s.isActive) {
      final repo = context.read<PbmsRepository>();
      _fee = AsyncCubit(() => repo.getFeePreview(s.sessionId));
    }
  }

  @override
  void dispose() {
    _fee?.close();
    super.dispose();
  }

  Future<void> _openCheckout() async {
    final paid = await GatePaymentSheet.show(context, s.sessionId);
    if (paid == true && mounted) {
      showPbmsSnack(context, 'Đã thanh toán. Barie sẽ mở khi xe tới cổng ra.');
    }
  }

  Future<void> _payToExit() async {
    final pass = await ExitPaymentSheet.show(
      context,
      session: s,
      fee: _fee?.state.data,
      onPayAtGate: _openCheckout,
    );
    if (pass != null && mounted) {
      setState(() => _exitPass = pass);
      showPbmsSnack(context, 'Đã thanh toán. Dùng mã ra cổng để lấy xe.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = s.ticket;
    final exitPass = _exitPass;
    return PbmsSheetFrame(
      title: s.licensePlateIn,
      subtitle: s.vehicleTypeName == null
          ? PbmsFacility.name
          : '${s.vehicleTypeName}, ${PbmsFacility.name}',
      children: [
        Row(
          children: [
            PbmsStatusPill(StatusInfo.session(s.status)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(s.isActive ? 'Đã đỗ' : 'Thời lượng',
                    style: PbmsText.caption),
                Text(DateFormatter.clock(s.parkedDuration),
                    style: PbmsText.display(40)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _box([
          PbmsDetailRow(
              icon: Icons.login_rounded,
              label: 'Giờ vào',
              value: DateFormatter.formatDateTime(s.entryTime)),
          if (s.entryGateName != null)
            PbmsDetailRow(
                icon: Icons.sensor_door_outlined,
                label: 'Cổng vào',
                value: s.entryGateName!),
          if (s.exitTime != null)
            PbmsDetailRow(
                icon: Icons.logout_rounded,
                label: 'Giờ ra',
                value: DateFormatter.formatDateTime(s.exitTime)),
          if (s.exitGateName != null)
            PbmsDetailRow(
                icon: Icons.sensor_door_outlined,
                label: 'Cổng ra',
                value: s.exitGateName!),
          PbmsDetailRow(
              icon: Icons.local_parking_rounded,
              label: 'Vị trí đỗ',
              value: s.slotCode ?? 'Chưa phân ô'),
          if (s.registeredLicensePlate != null)
            PbmsDetailRow(
                icon: Icons.badge_outlined,
                label: 'Biển đã đăng ký',
                value: s.registeredLicensePlate!),
        ]),
        if (s.plateMismatch) ...[
          const SizedBox(height: 10),
          _PlateMismatchNotice(
            read: s.licensePlateIn,
            registered: s.registeredLicensePlate!,
            onReport: () => ReportIncidentSheet.show(context, sessionId: s.sessionId),
          ),
        ],
        if (resolveMediaUrl(s.entryImageUrl) != null ||
            resolveMediaUrl(s.exitImageUrl) != null) ...[
          const SizedBox(height: 18),
          const Text('Ảnh tại cổng', style: PbmsText.section),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _GatePhoto(label: 'Lúc vào', url: resolveMediaUrl(s.entryImageUrl))),
              const SizedBox(width: 9),
              Expanded(child: _GatePhoto(label: 'Lúc ra', url: resolveMediaUrl(s.exitImageUrl))),
            ],
          ),
        ],
        if (s.isActive) ...[
          const SizedBox(height: 18),
          if (exitPass != null)
            ExitPassCard(pass: exitPass, plate: s.licensePlateIn, isMotorbike: s.isMotorbike)
          else ...[
            const Text('Phí tạm tính', style: PbmsText.section),
            const SizedBox(height: 8),
            PbmsAsync<FeePreviewModel>(
              cubit: _fee!,
              loadingHeight: 150,
              errorTitle: 'Chưa tính được phí',
              builder: (fee) => _FeeBreakdown(fee: fee),
            ),
            const SizedBox(height: 16),
            PbmsPrimaryButton(
              label: 'Thanh toán để lấy xe',
              icon: Icons.payments_outlined,
              onPressed: _payToExit,
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: ticket == null
                    ? null
                    : () => PbmsQrDialog.show(
                          context,
                          title: 'Vé gửi xe',
                          payload: ticket.qrPayload,
                          plate: s.licensePlateIn,
                          isMotorbike: s.isMotorbike,
                          rows: [
                            (Icons.local_parking_rounded, 'Vị trí đỗ',
                                s.slotCode ?? 'Chưa phân ô'),
                            (Icons.schedule_rounded, 'Vào bãi',
                                DateFormatter.formatDateTime(s.entryTime)),
                          ],
                        ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 19),
                label: const Text('Vé gửi xe (thanh toán tại cổng)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PbmsTokens.teal,
                  backgroundColor: PbmsTokens.tealTint,
                  side: const BorderSide(color: PbmsTokens.tealLine),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 18),
          const Text('Thanh toán', style: PbmsText.section),
          const SizedBox(height: 8),
          _box([
            PbmsDetailRow(
              label: 'Số tiền',
              value: s.paymentAmount == null
                  ? 'Chưa có'
                  : CurrencyFormatter.format(s.paymentAmount!),
            ),
            if (s.paymentMethod != null)
              PbmsDetailRow(label: 'Phương thức', value: s.paymentMethod!),
            if (s.paymentStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Trạng thái', style: PbmsText.caption)),
                    PbmsStatusPill(StatusInfo.payment(s.paymentStatus!)),
                  ],
                ),
              ),
          ]),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () =>
              ReportIncidentSheet.show(context, sessionId: s.sessionId),
          icon: const Icon(Icons.report_gmailerrorred_rounded, size: 20),
          label: const Text('Báo sự cố cho lượt gửi này'),
          style: TextButton.styleFrom(
              foregroundColor: PbmsTokens.muted,
              minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _box(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      decoration: BoxDecoration(
        color: PbmsTokens.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PbmsTokens.border),
      ),
      child: Column(children: rows),
    );
  }
}

/// Biển camera đọc lúc vào khác biển xe đã đăng ký: nhắc khách kiểm tra.
class _PlateMismatchNotice extends StatelessWidget {
  final String read;
  final String registered;
  final VoidCallback onReport;

  const _PlateMismatchNotice({required this.read, required this.registered, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return PbmsCard(
      color: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFED7AA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Biển số đọc được khác biển đăng ký', style: PbmsText.bodyStrong)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Camera đọc "$read", xe đăng ký là "$registered". Nếu camera đọc sai, hãy báo để bãi chỉnh lại trước khi ra.',
            style: PbmsText.caption,
          ),
          TextButton(
            onPressed: onReport,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              minimumSize: const Size(48, 44),
              padding: EdgeInsets.zero,
            ),
            child: const Text('Báo sai biển số'),
          ),
        ],
      ),
    );
  }
}

/// Ảnh camera ở cổng; chạm để xem lớn.
class _GatePhoto extends StatelessWidget {
  final String label;
  final String? url;

  const _GatePhoto({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final src = url;
    final placeholder = Container(
      height: 104,
      decoration: BoxDecoration(
        color: PbmsTokens.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PbmsTokens.border),
      ),
      alignment: Alignment.center,
      child: Text(src == null ? 'Chưa có ảnh' : 'Không tải được ảnh', style: PbmsText.caption),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PbmsText.caption),
        const SizedBox(height: 4),
        if (src == null)
          placeholder
        else
          Semantics(
            button: true,
            label: 'Ảnh xe $label, chạm để phóng to',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    child: Image.network(src, fit: BoxFit.contain, errorBuilder: (_, __, ___) => placeholder),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  src,
                  height: 104,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final FeePreviewModel fee;

  const _FeeBreakdown({required this.fee});

  @override
  Widget build(BuildContext context) {
    if (fee.isCoveredBySubscription) {
      return const PbmsCard(
        color: PbmsTokens.tealTint,
        borderColor: PbmsTokens.tealLine,
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: PbmsTokens.teal),
            SizedBox(width: 10),
            Expanded(
              child: Text('Lượt gửi này nằm trong vé tháng, không phát sinh phí.',
                  style: PbmsText.body),
            ),
          ],
        ),
      );
    }
    final extraHours = (fee.billedHours - fee.baseHours).clamp(0, 999);
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PbmsDetailRow(
              label: 'Lượt đầu (${fee.baseHours} giờ)',
              value: CurrencyFormatter.format(fee.basePrice)),
          if (extraHours > 0)
            PbmsDetailRow(
                label: '$extraHours giờ tiếp theo',
                value: CurrencyFormatter.format(extraHours * fee.extraHourPrice)),
          if (fee.nightSurchargeCount > 0)
            PbmsDetailRow(
                label: 'Phụ thu qua đêm x${fee.nightSurchargeCount}',
                value: CurrencyFormatter.format(
                    fee.nightSurchargeCount * fee.nightSurcharge)),
          if (fee.depositAmount > 0)
            PbmsDetailRow(
                label: 'Đã đặt cọc',
                value: '-${CurrencyFormatter.format(fee.depositAmount)}',
                valueColor: PbmsTokens.ok),
          const Divider(height: 14, color: PbmsTokens.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                  child: Text('Cần trả nếu ra bây giờ',
                      style: PbmsText.bodyStrong)),
              Text(CurrencyFormatter.format(fee.amount),
                  style: PbmsText.display(32)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Tính theo ${fee.billedHours} giờ, làm tròn từ ${fee.totalHours.toStringAsFixed(1)} giờ đỗ.',
              style: PbmsText.caption),
        ],
      ),
    );
  }
}

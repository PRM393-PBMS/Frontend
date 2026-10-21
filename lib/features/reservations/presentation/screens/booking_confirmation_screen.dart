import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/state/async_cubit.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/map/data/pbms_facility.dart';
import 'package:prm393_frontend/features/reservations/presentation/widgets/reservation_actions.dart';
import 'package:prm393_frontend/features/vehicles/presentation/widgets/vehicle_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Xác nhận đặt chỗ ô tô: chọn giờ vào, đặt cọc qua PayOS, nhận vé QR.
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  static const _pageBg = Color(0xFFF7FAFC);

  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _carPricing = AsyncCubit<PricingPolicyModel?>(() async =>
      (await _repo.getPricingPolicies())
          .where((p) => isCarType(p.vehicleTypeName))
          .firstOrNull);

  DateTime? _time;
  VehicleModel? _vehicle;
  bool _submitting = false;
  String? _formError;

  /// Đặt chỗ đã xác nhận (sau khi cọc thành công).
  ReservationModel? _confirmed;

  @override
  void dispose() {
    _carPricing.close();
    super.dispose();
  }

  Future<void> _submit() async {
    final vehicle = _vehicle;
    if (vehicle == null) {
      setState(() => _formError = 'Chọn ô tô sẽ vào bãi.');
      return;
    }
    final time = _time;
    if (time == null) {
      setState(() => _formError = 'Chọn giờ dự kiến vào bãi.');
      return;
    }
    if (!ReservationWindow.isValid(time)) {
      setState(() =>
          _formError = 'Giờ vào phải trong vòng 5 giờ tới. Chọn lại giờ.');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final link = await _repo.createReservation(time, vehicle.id);
      if (!mounted) return;
      final paid = await ReservationActions.payNew(context, link, () {});
      if (!mounted) return;
      final id = link.reservationId;
      if (paid && id != null) {
        final r = await _repo.getReservation(id);
        if (mounted) setState(() => _confirmed = r);
      } else {
        showPbmsSnack(context,
            'Đặt chỗ đang chờ đặt cọc. Bạn có thể thanh toán trong mục Lịch sử.');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _formError = errorText(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showPbmsSnack(context, 'Đã sao chép mã đặt chỗ.');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final confirmed = _confirmed;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        title: const Text('Vé đỗ xe điện tử',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: PbmsTokens.ink)),
        leading: IconButton(
          tooltip: 'Đóng',
          onPressed: () => context.pop(confirmed != null),
          icon: const Icon(Icons.close_rounded, color: PbmsTokens.ink),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 40 + bottomInset),
            children: [
              _ConfirmationHeader(done: confirmed != null),
              const SizedBox(height: 20),
              _buildTicketCard(confirmed),
              if (confirmed == null) ...[
                const SizedBox(height: 14),
                _buildVehicleCard(),
                const SizedBox(height: 14),
                _buildTimeCard(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(confirmed, bottomInset),
    );
  }

  Widget _buildTicketCard(ReservationModel? confirmed) {
    final ticket = confirmed?.ticket;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PbmsTokens.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                if (ticket != null)
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: PbmsTokens.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: ticket.qrPayload,
                      version: QrVersions.auto,
                      size: 196,
                      backgroundColor: Colors.white,
                      semanticsLabel: 'Mã QR vào cổng',
                      eyeStyle: const QrEyeStyle(color: Colors.black),
                      dataModuleStyle:
                          const QrDataModuleStyle(color: Colors.black),
                    ),
                  )
                else
                  Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      color: PbmsTokens.surfaceLow,
                      border: Border.all(color: PbmsTokens.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 44, color: PbmsTokens.muted),
                        const SizedBox(height: 8),
                        Text(
                          confirmed == null
                              ? 'Mã QR vào cổng có sau khi đặt cọc'
                              : 'Đang tạo mã QR, xem lại trong Lịch sử',
                          textAlign: TextAlign.center,
                          style: PbmsText.caption,
                        ),
                      ],
                    ),
                  ),
                if (confirmed != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _copyCode(confirmed.reservationId),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                        'Mã đặt chỗ ${confirmed.reservationId.substring(0, confirmed.reservationId.length.clamp(0, 8)).toUpperCase()}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PbmsTokens.teal,
                      backgroundColor: PbmsTokens.tealTint,
                      side: const BorderSide(color: PbmsTokens.tealLine),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: PbmsTokens.border),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: PbmsAsync<PricingPolicyModel?>(
              cubit: _carPricing,
              loadingHeight: 90,
              errorTitle: 'Không tải được bảng giá',
              builder: (pricing) => Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: _BookingInfoField(
                          label: 'Bãi đỗ',
                          value: PbmsFacility.name,
                          detail: PbmsFacility.area,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BookingInfoField(
                          label: 'Xe',
                          value: confirmed?.licensePlate ?? _vehicle?.licensePlate ?? 'Chưa chọn',
                          detail: 'Phân ô khi vào bãi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BookingInfoField(
                          label: 'Giờ vào dự kiến',
                          value: confirmed != null
                              ? DateFormatter.formatDayTime(
                                  confirmed.expectedEntryTime)
                              : (_time == null
                                  ? 'Chưa chọn'
                                  : DateFormatter.formatDayTime(_time!)),
                          detail:
                              'Được vào trễ tối đa ${ReservationModel.lateGrace.inMinutes} phút',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BookingInfoField(
                          label: 'Tiền cọc',
                          value: confirmed?.depositAmount != null
                              ? CurrencyFormatter.format(
                                  confirmed!.depositAmount!)
                              : pricing == null
                                  ? 'Chưa có bảng giá'
                                  : CurrencyFormatter.format(pricing.basePrice),
                          detail: 'Trừ vào phí khi ra bãi',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Chọn xe của bạn', style: PbmsText.section),
          const SizedBox(height: 4),
          const Text('Bãi chỉ nhận đặt chỗ trước cho ô tô.', style: PbmsText.caption),
          const SizedBox(height: 12),
          VehiclePicker(
            selectedId: _vehicle?.id,
            filter: (v) => v.isCar,
            emptyMessage: 'Tài khoản chưa có ô tô nào. Thêm xe để đặt chỗ.',
            onChanged: (v) => setState(() {
              _vehicle = v;
              _formError = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return PbmsCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Giờ dự kiến vào bãi', style: PbmsText.section),
          const SizedBox(height: 4),
          const Text('Giữ chỗ trước tối đa 5 giờ.', style: PbmsText.caption),
          const SizedBox(height: 12),
          EntryTimePicker(
            value: _time,
            onChanged: (v) => setState(() {
              _time = v;
              _formError = null;
            }),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: PbmsTokens.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_formError!,
                      style:
                          PbmsText.caption.copyWith(color: PbmsTokens.danger)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(ReservationModel? confirmed, double bottomInset) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PbmsTokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (confirmed == null)
                PbmsPrimaryButton(
                  label: 'Xác nhận và đặt cọc',
                  icon: Icons.payments_outlined,
                  busy: _submitting,
                  onPressed: _submit,
                )
              else
                PbmsPrimaryButton(
                  label: 'Xong',
                  icon: Icons.check_rounded,
                  onPressed: () => context.pop(true),
                ),
              const SizedBox(height: 9),
              if (confirmed == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(false),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Quay lại bản đồ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PbmsTokens.muted,
                      side: const BorderSide(color: PbmsTokens.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  final bool done;

  const _ConfirmationHeader({required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: PbmsTokens.tealTint,
            border: Border.all(color: PbmsTokens.tealLine),
            shape: BoxShape.circle,
          ),
          child: Icon(
              done ? Icons.check_circle_rounded : Icons.fact_check_rounded,
              size: 29,
              color: PbmsTokens.teal),
        ),
        const SizedBox(height: 9),
        Text(done ? 'Đã giữ chỗ cho bạn' : 'Xác nhận đặt chỗ',
            textAlign: TextAlign.center, style: PbmsText.headline),
        const SizedBox(height: 3),
        Text(
          done
              ? 'Đưa mã QR vào đầu đọc tại cổng khi tới bãi'
              : 'Kiểm tra thông tin trước khi đặt cọc',
          textAlign: TextAlign.center,
          style: PbmsText.caption,
        ),
      ],
    );
  }
}

class _BookingInfoField extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _BookingInfoField(
      {required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PbmsText.label),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PbmsText.bodyStrong),
        const SizedBox(height: 2),
        Text(detail,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: PbmsText.caption),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/utils/currency_formatter.dart';
import 'package:prm393_frontend/features/home/presentation/models/vehicle_card_model.dart';
import 'package:prm393_frontend/features/map/data/models/mock_parking_lot.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final MockParkingLot parkingLot;
  final VehicleCardModel vehicle;

  const BookingConfirmationScreen({
    super.key,
    required this.parkingLot,
    required this.vehicle,
  });

  static const _teal = Color(0xFF087B8C);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  String get _previewCode =>
      'PRE-${parkingLot.id.toUpperCase()}-${vehicle.id.replaceFirst('veh_', '')}';

  void _showNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _previewCode));
    if (context.mounted) _showNotice(context, 'Đã sao chép mã xem trước.');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC).withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Vé đỗ xe điện tử',
          style:
              TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink),
        ),
        leading: IconButton(
          tooltip: 'Đóng',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ mã xem trước',
            onPressed: () => _copyCode(context),
            icon: const Icon(Icons.ios_share_rounded, color: _ink),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 194 + bottomInset),
            children: [
              const _ConfirmationHeader(),
              const SizedBox(height: 20),
              _buildTicketCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, bottomInset),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 22, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: QrImageView(
                    data: 'BOOKING-PREVIEW:${parkingLot.id}:${vehicle.id}',
                    version: QrVersions.auto,
                    size: 184,
                    eyeStyle: const QrEyeStyle(color: _ink),
                    dataModuleStyle: const QrDataModuleStyle(color: _ink),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _copyCode(context),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: Text('Mã xem trước: $_previewCode'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal,
                    backgroundColor: const Color(0xFFEFFBFC),
                    side: const BorderSide(color: Color(0xFF97DFEB)),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Chưa có hiệu lực · Mã thật sẽ có sau khi đặt chỗ thành công',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: _border),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BookingInfoField(
                        label: 'Bãi đỗ',
                        value: parkingLot.name,
                        detail: 'TP. Hồ Chí Minh',
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: _BookingInfoField(
                        label: 'Vị trí đỗ',
                        value: 'Chưa phân ô',
                        detail: 'Xác nhận sau khi đặt',
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
                        label: 'Biển số xe',
                        value: vehicle.licensePlate,
                        detail: vehicle.vehicleName,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BookingInfoField(
                        label: 'Giá theo giờ',
                        value:
                            CurrencyFormatter.format(parkingLot.pricePerHour),
                        detail: 'Chưa chọn khung giờ',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 14, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _showNotice(
                    context,
                    'Chưa gửi đặt chỗ: dịch vụ đặt chỗ chưa được kết nối.',
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  label: const Text('Xác nhận đặt chỗ',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text('Quay lại chọn bãi hoặc xe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: _border),
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
  const _ConfirmationHeader();

  static const _teal = Color(0xFF087B8C);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEFFBFC),
            border: Border.all(color: const Color(0xFF97DFEB)),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fact_check_rounded, size: 29, color: _teal),
        ),
        const SizedBox(height: 9),
        const Text(
          'Xác nhận đặt chỗ',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 3),
        const Text(
          'Kiểm tra thông tin trước khi gửi yêu cầu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 10, height: 1.3, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

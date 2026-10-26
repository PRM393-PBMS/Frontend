import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';

/// Kết quả đối chiếu của máy chủ, nói gọn cho nhân viên đứng ở cổng.
/// Điện thoại chỉ báo; quyết định cho vào / ra vẫn làm trên web.
class ScanVerdict {
  final String label;
  final IconData icon;
  final Color color;

  const ScanVerdict(this.label, this.icon, this.color);

  static ScanVerdict of(GateScanModel scan) {
    switch (scan.suggestedType.toLowerCase()) {
      case 'reservation':
        if (scan.reservationOnTime ?? false) {
          return const ScanVerdict('Có đặt chỗ · đúng giờ', Icons.event_available_rounded, PbmsTokens.ok);
        }
        final at = scan.reservationTime;
        return ScanVerdict(
          at == null ? 'Có đặt chỗ · lệch giờ hẹn' : 'Có đặt chỗ lúc ${DateFormat('HH:mm').format(at)} · lệch giờ',
          Icons.event_note_rounded,
          PbmsTokens.warn,
        );
      case 'resident':
        return const ScanVerdict('Khách vé tháng', Icons.card_membership_rounded, PbmsTokens.ok);
      case 'guest':
        return const ScanVerdict('Khách vãng lai', Icons.directions_car_outlined, PbmsTokens.teal);
      case 'inside':
        return const ScanVerdict('Xe đang trong bãi', Icons.warning_amber_rounded, PbmsTokens.danger);
      case 'checkout':
        return const ScanVerdict('Đang gửi trong bãi · chờ checkout', Icons.logout_rounded, PbmsTokens.teal);
      default:
        return ScanVerdict(
          scan.licensePlate == null ? 'Web sẽ nhập tay biển số' : 'Không có phiên gửi xe',
          Icons.help_outline_rounded,
          PbmsTokens.warn,
        );
    }
  }
}

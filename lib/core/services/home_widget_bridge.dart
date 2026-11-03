import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/pbms_models.dart';
import '../utils/date_formatter.dart';

/// Gửi trạng thái vé cho widget màn hình chính Android (ParkingWidgetProvider.kt).
/// Widget chỉ đọc dữ liệu app gửi; đồng hồ thời gian gửi do hệ thống tự chạy.
class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _channel = MethodChannel('pbms/home_widget');

  /// Dữ liệu cho widget: đang gửi xe > đặt chỗ sắp tới > không có gì. Tách riêng để kiểm thử.
  static Map<String, Object?> payload({ParkingSessionModel? session, ReservationModel? reservation}) {
    if (session != null && session.isActive) {
      return {
        'state': 'parking',
        'plate': session.licensePlateIn,
        'slot': session.slotCode,
        'entryAt': session.entryTime.millisecondsSinceEpoch,
        'exitCode': session.exitPass?.code,
      };
    }
    if (reservation != null) {
      return {
        'state': 'reservation',
        'time': '${DateFormatter.formatTime(reservation.expectedEntryTime)}, ${DateFormatter.formatDay(reservation.expectedEntryTime)}',
        'place': reservation.parkingName ?? 'Bãi đỗ PBMS',
        'parkingId': reservation.parkingId,
      };
    }
    return const {'state': 'idle'};
  }

  static Future<void> sync({ParkingSessionModel? session, ReservationModel? reservation}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('update', payload(session: session, reservation: reservation));
    } catch (_) {
      // Widget là phụ: lỗi không ảnh hưởng app.
    }
  }

  /// Đăng xuất: widget về trạng thái không có xe.
  static Future<void> clear() => sync();
}

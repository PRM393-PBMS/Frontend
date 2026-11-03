import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prm393_frontend/core/services/home_widget_bridge.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';

ParkingSessionModel session({Map<String, dynamic>? exitPass, String status = 'Active'}) => ParkingSessionModel.fromJson({
      'sessionId': 's1',
      'licensePlateIn': '51A12345',
      'entryTime': DateTime(2026, 11, 3, 8, 30).toIso8601String(),
      'actualSlotCode': 'A05',
      'status': status,
      'exitPass': exitPass,
    });

ReservationModel reservation() => ReservationModel.fromJson({
      'reservationId': 'r1',
      'expectedEntryTime': DateTime(2026, 11, 4, 9, 15).toIso8601String(),
      'status': 'Confirmed',
      'parkingId': 'lot-1',
      'parkingName': 'Bãi Quận 1',
    });

void main() {
  setUpAll(() => initializeDateFormatting('vi_VN'));

  test('đang gửi xe: biển số, ô, giờ vào (đồng hồ widget tự chạy), chưa có mã ra cổng', () {
    final p = HomeWidgetBridge.payload(session: session(), reservation: reservation());
    expect(p['state'], 'parking');
    expect(p['plate'], '51A12345');
    expect(p['slot'], 'A05');
    expect(p['entryAt'], DateTime(2026, 11, 3, 8, 30).millisecondsSinceEpoch);
    expect(p['exitCode'], isNull);
  });

  test('đã trả trước: kèm mã ra cổng', () {
    final p = HomeWidgetBridge.payload(session: session(exitPass: {'code': 'K7Q2P9', 'qrPayload': 'PBMS-EXIT:x'}));
    expect(p['exitCode'], 'K7Q2P9');
  });

  test('không có xe trong bãi nhưng có đặt chỗ: giờ hẹn, bãi, mã bãi để mở đường vào', () {
    final p = HomeWidgetBridge.payload(session: session(status: 'Completed'), reservation: reservation());
    expect(p['state'], 'reservation');
    expect(p['time'], startsWith('09:15'));
    expect(p['place'], 'Bãi Quận 1');
    expect(p['parkingId'], 'lot-1');
  });

  test('không có gì: widget về lối tắt mở app', () {
    expect(HomeWidgetBridge.payload(), {'state': 'idle'});
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/services/parking_ongoing_notification.dart';
import 'package:prm393_frontend/core/services/shell_actions.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/home/presentation/screens/home_dashboard_screen.dart';

ParkingSessionModel session({String? slot = 'A05', Map<String, dynamic>? exitPass, DateTime? entry, String status = 'Active'}) =>
    ParkingSessionModel.fromJson({
      'sessionId': 's1',
      'licensePlateIn': '51A12345',
      'vehicleTypeName': 'Ô tô',
      'entryTime': (entry ?? DateTime.now().subtract(const Duration(minutes: 3))).toIso8601String(),
      'entryGateName': 'Cổng 1',
      'actualSlotCode': slot,
      'status': status,
      'exitPass': exitPass,
    });

void main() {
  group('Bấm thông báo thì làm gì', () {
    test('xe vào bãi: mở sơ đồ tới ô, kèm cổng và bãi', () {
      final a = actionForNotification('parking', {
        'action': 'lot-map',
        'slotCode': 'A05',
        'entryGateName': 'Cổng 1',
        'parkingId': 'lot-1',
      });
      expect(a, isA<OpenLotMap>());
      expect((a as OpenLotMap).slotCode, 'A05');
      expect(a.parkingId, 'lot-1');
    });

    test('ví không đủ tự gia hạn: mở nạp ví, điền số tiền còn thiếu (làm tròn lên)', () {
      final a = actionForNotification('wallet', {'action': 'topup', 'amount': 45000.4});
      expect((a as OpenTopUp).amount, 45001);
      expect((actionForNotification('wallet', {'action': 'topup', 'amount': 0}) as OpenTopUp).amount, isNull);
    });

    test('vé sắp hết hạn hoặc đã hết hạn (bản cũ): mở gia hạn đúng vé', () {
      expect((actionForNotification('subscription', {'subscriptionId': 'v1', 'action': 'renew'}) as OpenRenew).subscriptionId, 'v1');
      expect(actionForNotification('subscription', {'subscriptionId': 'v1', 'status': 'Expired'}), isA<OpenRenew>());
    });

    test('thông báo thường (đã nạp ví, đặt chỗ...) chỉ đánh dấu đã đọc', () {
      expect(actionForNotification('wallet', {'paymentId': 'p1'}), isNull);
      expect(actionForNotification('subscription', {'subscriptionId': 'v1', 'status': 'Active'}), isNull);
    });

    test('dữ liệu gắn vào thông báo trên khay đọc lại được; hỏng thì bỏ qua', () {
      final payload = encodeActionPayload('parking', {'action': 'exit-pass'});
      expect(decodeActionPayload(payload), isA<OpenExitPass>());
      expect(decodeActionPayload('{hong'), isNull);
      expect(decodeActionPayload(null), isNull);
    });

    test('thông báo từ máy chủ đọc kèm metadata', () {
      final n = NotificationModel.fromJson({
        'id': 'n1',
        'title': 'Xe đã vào bãi, ô A05',
        'message': 'm',
        'type': 'parking',
        'isRead': false,
        'metadata': {'action': 'lot-map', 'slotCode': 'A05'},
      });
      expect(actionFor(n), isA<OpenLotMap>());
      expect(NotificationModel.fromJson({'id': 'n2', 'title': 't', 'message': 'm'}).metadata, isEmpty);
    });
  });

  group('Thông báo cố định khi đang gửi xe', () {
    test('chưa trả trước: mời trả trước', () {
      final c = ParkingOngoingNotification.contentFor(session());
      expect(c.title, 'Đang gửi xe 51A12345 · Ô A05');
      expect(c.action, 'Trả trước');
    });

    test('đã trả trước: hiện mã ra cổng', () {
      final c = ParkingOngoingNotification.contentFor(
          session(exitPass: {'code': 'K7Q2P9', 'qrPayload': 'PBMS-EXIT:x'}));
      expect(c.body, contains('K7Q2P9'));
      expect(c.action, 'Mã ra cổng');
    });
  });

  group('Tự mở sơ đồ khi vừa vào bãi', () {
    test('vừa vào, có ô, chưa mở lần nào thì mở', () {
      expect(shouldAutoOpenLotMap(session(), {}), isTrue);
    });

    test('đã mở rồi, vào lâu rồi, chưa phân ô, hoặc đã ra thì không mở', () {
      expect(shouldAutoOpenLotMap(session(), {'s1'}), isFalse);
      expect(shouldAutoOpenLotMap(session(entry: DateTime.now().subtract(const Duration(minutes: 40))), {}), isFalse);
      expect(shouldAutoOpenLotMap(session(slot: null), {}), isFalse);
      expect(shouldAutoOpenLotMap(session(status: 'Completed'), {}), isFalse);
      expect(shouldAutoOpenLotMap(null, {}), isFalse);
    });
  });
}

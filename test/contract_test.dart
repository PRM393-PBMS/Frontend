import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/features/subscriptions/presentation/widgets/pass_sheets.dart';
import 'package:prm393_frontend/features/reservations/presentation/widgets/reservation_actions.dart';

void main() {
  group('Hợp đồng dữ liệu backend PBMS', () {
    test('Thông báo đọc envelope {items, unreadCount} và trường message', () {
      final page = NotificationPage.fromJson({
        'items': [
          {
            'id': 'notif_1',
            'title': 'Chào mừng',
            'message': 'Tài khoản đã kích hoạt',
            'type': 'system',
            'isRead': false,
            'createdAt': '2026-10-15T07:00:00.000Z',
          },
          {
            'id': 'notif_2',
            'title': 'Vé tháng',
            'message': 'Sắp hết hạn',
            'type': 'subscription',
            'isRead': true,
            'createdAt': '2026-10-14T07:00:00.000Z',
          },
        ],
        'unreadCount': 1,
        'total': 2,
      });
      expect(page.items, hasLength(2));
      expect(page.unreadCount, 1);
      expect(page.items.first.message, 'Tài khoản đã kích hoạt');
    });

    test('Checkout payment đọc khoá PascalCase Payment/OnlinePayment', () {
      final model = CheckoutPaymentModel.fromJson({
        'Payment': {
          'paymentId': 'p1',
          'amount': 11000,
          'paymentMethod': 'PayOS',
          'paymentStatus': 'Pending',
        },
        'OnlinePayment': {
          'paymentUrl': 'https://pay.payos.vn/web/abc',
          'orderCode': 'PBMS-1',
        },
      });
      expect(model.payment?.amount, 11000);
      expect(model.online?.paymentUrl, 'https://pay.payos.vn/web/abc');

      final empty = CheckoutPaymentModel.fromJson({'Payment': null, 'OnlinePayment': null});
      expect(empty.hasRequest, isFalse);
    });

    test('Phiên gửi xe đọc ticket dạng object', () {
      final s = ParkingSessionModel.fromJson({
        'sessionId': 's1',
        'licensePlateIn': '51K12345',
        'entryTime': '2026-10-15T01:15:00.000Z',
        'status': 'Active',
        'actualSlotCode': 'B1-A12',
        'ticket': {'qrPayload': 's1', 'qrCodeDataUrl': 'data:image/png;base64,AAA'},
      });
      expect(s.isActive, isTrue);
      expect(s.ticket?.qrPayload, 's1');
      expect(s.slotCode, 'B1-A12');
    });

    test('Đặt chỗ mới trả về depositAmount làm số tiền thanh toán', () {
      final link = PaymentLinkModel.fromJson({
        'reservationId': 'r1',
        'depositAmount': 30000,
        'paymentUrl': 'https://pay.payos.vn/web/x',
        'orderCode': '123',
      });
      expect(link.amount, 30000);
      expect(link.hasUrl, isTrue);
    });

    test('Vé tháng tính số ngày còn lại', () {
      final sub = MonthlySubscriptionModel.fromJson({
        'subscriptionId': 'sub1',
        'licensePlate': '51K12345',
        'vehicleType': 'Ô tô',
        'packageName': 'Gói tháng ô tô',
        'startDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 20, hours: 2)).toIso8601String(),
        'price': 1500000,
        'status': 'Active',
      });
      expect(sub.isActive, isTrue);
      expect(sub.daysLeft, 21);
    });
  });

  group('Biển số', () {
    test('Chuẩn hoá và kiểm tra biển số', () {
      expect(normalizePlate('51K-123.45'), '51K12345');
      expect(validatePlate('51K-123.45'), isNull);
      expect(validatePlate('12'), isNotNull);
      expect(validatePlate(''), isNotNull);
    });
  });

  group('Khung giờ đặt chỗ', () {
    test('Chỉ chấp nhận trong vòng 5 giờ tới', () {
      final now = DateTime.now();
      expect(ReservationWindow.isValid(now.add(const Duration(hours: 1))), isTrue);
      expect(ReservationWindow.isValid(now.add(const Duration(hours: 6))), isFalse);
      expect(ReservationWindow.isValid(now.subtract(const Duration(minutes: 5))), isFalse);
    });
  });
}

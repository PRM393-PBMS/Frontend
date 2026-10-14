import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import 'package:prm393_frontend/features/catalog/data/catalog_repository.dart';
import 'package:prm393_frontend/features/notifications/data/notification_repository.dart';
import 'package:prm393_frontend/features/reservations/data/reservation_repository.dart';
import 'package:prm393_frontend/features/sessions/data/session_repository.dart';
import 'package:prm393_frontend/features/subscriptions/data/subscription_repository.dart';
import 'package:prm393_frontend/features/wallet/data/wallet_repository.dart';

/// Adapter giả trả về phản hồi theo đúng dạng backend PBMS (envelope + HTTP status = statusCode).
class FakeAdapter implements HttpClientAdapter {
  final Map<String, (int, Object?)> routes;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.path}';
    final route = routes[key];
    if (route == null) {
      return ResponseBody.fromString(
        jsonEncode({
          'statusCode': 404,
          'message': 'no route $key',
          'isSuccess': false
        }),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.$2),
      route.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> ok(Object? result, [String message = 'OK']) => {
      'statusCode': 200,
      'message': message,
      'isSuccess': true,
      'result': result
    };

Map<String, Object?> fail(int code, String message) => {
      'statusCode': code,
      'message': message,
      'isSuccess': false,
      'result': null
    };

ApiClient client(FakeAdapter adapter) {
  final dio = Dio(
      BaseOptions(baseUrl: 'http://test', contentType: Headers.jsonContentType))
    ..httpClientAdapter = adapter;
  return ApiClient(storageService: SecureStorageService(), customDio: dio);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  walletTests();

  group('ApiClient envelope', () {
    test('404 trên endpoint danh sách được hiểu là danh sách rỗng', () async {
      final api = client(FakeAdapter({
        'GET /api/SubscriptionPackage': (
          404,
          fail(404, 'Không tìm thấy gói thuê bao nào')
        ),
      }));
      expect(await CatalogRepository(api).packages(), isEmpty);
    });

    test(
        'isSuccess=false được chuyển thành exception đúng loại kèm thông điệp backend',
        () async {
      final api = client(FakeAdapter({
        'POST /api/reservations': (
          400,
          fail(400, 'Chỉ được phép đặt trước tối đa 5 tiếng')
        ),
      }));
      expect(
        () => ReservationRepository(api)
            .create(DateTime.now().add(const Duration(hours: 9))),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message',
            'Chỉ được phép đặt trước tối đa 5 tiếng')),
      );
    });

    test('409 xung đột được ánh xạ ConflictException', () async {
      final api = client(FakeAdapter({
        'POST /api/ParkingOperation/check-in': (
          409,
          fail(409, 'Xe này đang có phiên gửi xe chưa checkout')
        ),
      }));
      expect(
        () => SessionRepository(api).checkIn(
          customerType: CustomerType.guest,
          gateId: 'g',
          licensePlate: '51H12345',
          vehicleTypeId: 'v',
        ),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  group('Request body khớp whitelist backend', () {
    test(
        'check-in gửi gateId/licensePlate/customerType (không phải entryGateId)',
        () async {
      final adapter = FakeAdapter({
        'POST /api/ParkingOperation/check-in': (
          201,
          {
            'statusCode': 201,
            'message': 'Check-in xe vãng lai thành công',
            'isSuccess': true,
            'result': _sessionJson,
          }
        ),
      });
      final s = await SessionRepository(client(adapter)).checkIn(
        customerType: CustomerType.guest,
        gateId: 'gate-1',
        licensePlate: '51H12345',
        vehicleTypeId: 'vt-1',
      );
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body, {
        'customerType': 'Guest',
        'gateId': 'gate-1',
        'licensePlate': '51H12345',
        'vehicleTypeId': 'vt-1',
      });
      expect(s.slotCode, 'A-01');
      expect(s.ticket?.qrPayload, 'sess-1');
    });

    test('đăng ký vé tháng chuẩn hoá biển số và không gửi phoneNumber',
        () async {
      final adapter = FakeAdapter({
        'POST /api/MonthlySubscription/register': (
          201,
          {
            'statusCode': 201,
            'message': 'Tạo đăng ký gói thành công',
            'isSuccess': true,
            'result': {
              'subscriptionId': 'sub-1',
              'paymentId': 'pay-1',
              'orderCode': '1726543',
              'amount': 1200000,
              'paymentLinkId': 'pl',
              'paymentUrl': 'https://pay.payos.vn/web/abc',
            },
          }
        ),
      });
      final r = await SubscriptionRepository(client(adapter)).register(
          packageId: 'pkg-1',
          licensePlate: '51h-123.45',
          method: PassPaymentMethod.payos);
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body, {
        'packageId': 'pkg-1',
        'licensePlate': '51H12345',
        'paymentMethod': 'PayOS',
      });
      expect(r.payment!.amount, 1200000);
      expect(r.payment!.isUsable, isTrue);
      expect(r.paidByWallet, isFalse);
    });
  });

  group('Parse phản hồi backend', () {
    test('tạo đặt chỗ đọc depositAmount làm số tiền thanh toán', () async {
      final api = client(FakeAdapter({
        'POST /api/reservations': (
          200,
          ok({
            'reservationId': 'res-1',
            'paymentId': 'pay-1',
            'depositAmount': 30000,
            'paymentLinkId': 'pl',
            'paymentUrl': 'https://pay.payos.vn/web/x',
            'orderCode': '998877',
            'ticket': {
              'qrPayload': 'res-1',
              'qrCodeDataUrl': 'data:image/png;base64,'
            },
          })
        ),
      }));
      final r = await ReservationRepository(api)
          .create(DateTime.now().add(const Duration(hours: 1)));
      expect(r.reservationId, 'res-1');
      expect(r.payment.amount, 30000);
      expect(r.payment.orderCode, '998877');
    });

    test('checkout tiền mặt chờ xác nhận: khoá PascalCase Payment/Fee',
        () async {
      final api = client(FakeAdapter({
        'POST /api/ParkingOperation/check-out': (
          200,
          ok({
            'Payment': {
              'paymentId': 'p1',
              'sessionId': 'sess-1',
              'amount': 45000,
              'paymentMethod': 'Cash',
              'paymentType': 'CheckoutFee',
              'paymentStatus': 'Pending',
            },
            'Fee': {
              'sessionId': 'sess-1',
              'licensePlate': '51H12345',
              'totalHours': 3.25,
              'billedHours': 4,
              'grossAmount': 45000,
              'depositAmount': 0,
              'amount': 45000,
              'basePrice': 30000,
              'baseHours': 2,
              'extraHourPrice': 7500,
              'nightSurcharge': 0,
              'nightSurchargeCount': 0,
              'isCoveredBySubscription': false,
            },
          }, 'Chờ xác nhận tiền mặt để hoàn tất checkout')
        ),
      }));
      final r = await SessionRepository(api)
          .checkOut(gateId: 'g', sessionId: 'sess-1', paymentMethod: 'Cash');
      expect(r.payment?.isPending, isTrue);
      expect(r.fee?.amount, 45000);
      expect(r.fee?.extraHours, 2);
      expect(r.isCompleted, isFalse);
    });

    test('checkout vé tháng trả trực tiếp phiên đã hoàn tất', () async {
      final api = client(FakeAdapter({
        'POST /api/ParkingOperation/check-out': (
          200,
          ok({..._sessionJson, 'status': 'Completed'})
        ),
      }));
      final r = await SessionRepository(api).checkOut(
          gateId: 'g', licensePlate: '51H12345', paymentMethod: 'Cash');
      expect(r.session?.isActive, isFalse);
      expect(r.isCompleted, isTrue);
    });

    test('availability gom chỗ trống theo loại xe', () async {
      final api = client(FakeAdapter({
        'GET /api/ParkingOperation/availability': (
          200,
          ok([
            {
              'floorId': 'f1',
              'floorName': 'B1',
              'vehicleTypeId': 'm',
              'vehicleTypeName': 'Xe máy',
              'totalSlots': 120,
              'availableSlots': 33,
              'occupiedSlots': 80,
              'assignedSlots': 7
            },
            {
              'floorId': 'f2',
              'floorName': 'B2',
              'vehicleTypeId': 'c',
              'vehicleTypeName': 'Ô tô',
              'totalSlots': 40,
              'availableSlots': 12,
              'occupiedSlots': 28,
              'assignedSlots': 0
            },
          ])
        ),
        'GET /api/Floor': (404, fail(404, 'Không tìm thấy tầng nào')),
        'GET /api/PricingPolicy': (
          200,
          ok([
            {
              'policyId': 'old',
              'vehicleTypeId': 'c',
              'vehicleTypeName': 'Ô tô',
              'basePrice': 20000,
              'baseHours': 2,
              'extraHourPrice': 5000,
              'nightSurcharge': 0,
              'effectiveDate': '2025-01-01T00:00:00.000Z',
              'status': 'Active'
            },
            {
              'policyId': 'new',
              'vehicleTypeId': 'c',
              'vehicleTypeName': 'Ô tô',
              'basePrice': 30000,
              'baseHours': 2,
              'extraHourPrice': 7500,
              'nightSurcharge': 10000,
              'effectiveDate': '2026-01-01T00:00:00.000Z',
              'status': 'Active'
            },
            {
              'policyId': 'future',
              'vehicleTypeId': 'c',
              'vehicleTypeName': 'Ô tô',
              'basePrice': 99000,
              'baseHours': 2,
              'extraHourPrice': 7500,
              'nightSurcharge': 0,
              'effectiveDate': '2099-01-01T00:00:00.000Z',
              'status': 'Active'
            },
          ])
        ),
      }));
      final o = await CatalogRepository(api).overview();
      expect(o.totalAvailable, 45);
      expect(o.byVehicleType['Ô tô']?.available, 12);
      expect(o.activePricing.single.id, 'new');
    });

    test('thông báo: 404 nghĩa là backend chưa có tính năng', () async {
      final repo = NotificationRepository(client(FakeAdapter({})));
      final feed = await repo.mine();
      expect(feed.available, isFalse);
    });

    test('thông báo: đọc items và đếm chưa đọc', () async {
      final repo = NotificationRepository(client(FakeAdapter({
        'GET /api/Notification/my': (
          200,
          ok({
            'items': [
              {
                'id': 'n1',
                'title': 'A',
                'message': 'a',
                'type': 'system',
                'isRead': false,
                'createdAt': '2026-10-01T00:00:00.000Z'
              },
              {
                'id': 'n2',
                'title': 'B',
                'message': 'b',
                'type': 'parking',
                'isRead': true,
                'createdAt': '2026-10-02T00:00:00.000Z'
              },
            ],
            'unreadCount': 1,
            'total': 2,
          })
        ),
      })));
      final feed = await repo.mine();
      expect(feed.available, isTrue);
      expect(feed.unreadCount, 1);
      expect(feed.items.first.id, 'n2');
    });
  });
}

void walletTests() {
  group('Ví PBMS', () {
    test('thanh toán vé tháng bằng ví: không có paymentUrl, gói kích hoạt ngay',
        () async {
      final adapter = FakeAdapter({
        'POST /api/MonthlySubscription/register': (
          201,
          {
            'statusCode': 201,
            'message': 'Thanh toán gói bằng ví thành công',
            'isSuccess': true,
            'result': {
              'subscriptionId': 'sub-2',
              'paymentId': 'pay-2',
              'paymentMethod': 'Wallet',
              'amount': 150000,
              'walletId': 'w-1',
              'walletBalance': 50000,
              'status': 'Active',
            },
          }
        ),
      });
      final r = await SubscriptionRepository(client(adapter)).register(
          packageId: 'pkg-1',
          licensePlate: '59A12345',
          method: PassPaymentMethod.wallet);
      expect((adapter.requests.single.data as Map)['paymentMethod'], 'Wallet');
      expect(r.paidByWallet, isTrue);
      expect(r.payment, isNull);
      expect(r.walletBalance, 50000);
    });

    test('số dư không đủ: hiển thị nguyên văn thông điệp backend', () async {
      final api = client(FakeAdapter({
        'POST /api/MonthlySubscription/payment/sub-1': (
          400,
          {
            'statusCode': 400,
            'message': 'Số dư ví không đủ để thanh toán gói này',
            'isSuccess': false,
            'result': {'walletBalance': 1000, 'amount': 150000},
          }
        ),
      }));
      expect(
        () =>
            SubscriptionRepository(api).pay('sub-1', PassPaymentMethod.wallet),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message',
            'Số dư ví không đủ để thanh toán gói này')),
      );
    });

    test('mở ví rồi lấy số dư và lịch sử; nạp tiền gửi {amount}', () async {
      final adapter = FakeAdapter({
        'POST /api/wallet': (
          200,
          ok({'walletId': 'w-1', 'userId': 'u', 'walletBalance': 0})
        ),
        'GET /api/wallet/w-1': (
          200,
          ok({
            'walletId': 'w-1',
            'userId': 'u',
            'walletBalance': 250000,
            'transactions': [
              {
                'walletTransactionId': 't1',
                'direction': 'Debit',
                'type': 'SubscriptionFee',
                'amount': -150000,
                'absoluteAmount': 150000,
                'balanceAfter': 250000,
                'createdAt': '2026-10-15T01:00:00.000Z',
                'packageName': 'Gói tháng xe máy',
                'licensePlate': '59A12345',
              },
              {
                'walletTransactionId': 't0',
                'direction': 'Credit',
                'type': 'TopUp',
                'amount': 400000,
                'absoluteAmount': 400000,
                'balanceAfter': 400000,
                'createdAt': '2026-10-14T01:00:00.000Z',
              },
            ],
          })
        ),
        'POST /api/wallet/w-1/top-up': (
          201,
          {
            'statusCode': 201,
            'message': 'Tạo liên kết nạp ví thành công',
            'isSuccess': true,
            'result': {
              'walletId': 'w-1',
              'paymentId': 'p9',
              'amount': 100000,
              'walletBalance': 250000,
              'paymentUrl': 'https://pay.payos.vn/web/x',
              'orderCode': '777',
            },
          }
        ),
      });
      final repo = WalletRepository(client(adapter));
      final w = await repo.mine();
      expect(w.balance, 250000);
      expect(w.transactions.first.isCredit, isFalse);
      expect(w.transactions.first.packageName, 'Gói tháng xe máy');
      expect(w.transactions.last.isCredit, isTrue);

      final link = await repo.topUp(w.id, 100000);
      expect(adapter.requests.last.data, {'amount': 100000});
      expect(link.amount, 100000);
      expect(link.orderCode, '777');
    });
  });
}

const _sessionJson = {
  'sessionId': 'sess-1',
  'reservationId': null,
  'driverUserId': null,
  'driverFullName': null,
  'licensePlateIn': '51H12345',
  'licensePlateOut': null,
  'vehicleTypeId': 'vt-1',
  'vehicleTypeName': 'Ô tô',
  'entryTime': '2026-10-15T01:00:00.000Z',
  'exitTime': null,
  'entryGateId': 'gate-1',
  'entryGateName': 'Cổng A',
  'exitGateId': null,
  'exitGateName': null,
  'assignedSlotId': 'slot-1',
  'assignedSlotCode': 'A-01',
  'actualSlotId': 'slot-1',
  'actualSlotCode': 'A-01',
  'status': 'Active',
  'paymentAmount': null,
  'paymentStatus': null,
  'paymentMethod': null,
  'paymentTime': null,
  'ticket': {'qrPayload': 'sess-1', 'qrCodeDataUrl': 'data:image/png;base64,'},
};

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// ApiClient giả: ghi lại request, trả về [result].
class _FakeApi implements ApiClient {
  final calls = <(String, String, dynamic)>[];
  final dynamic result;

  _FakeApi(this.result);

  ApiResponse<T> _ok<T>() => ApiResponse<T>(statusCode: 200, isSuccess: true, result: result as T?);

  @override
  Future<ApiResponse<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      T Function(dynamic json)? fromJsonT}) async {
    calls.add(('POST', path, data));
    return _ok<T>();
  }

  @override
  Future<ApiResponse<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      T Function(dynamic json)? fromJsonT}) async {
    calls.add(('GET', path, queryParameters));
    return _ok<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReservationModel _reservation(Map<String, dynamic> over) => ReservationModel.fromJson({
      'reservationId': 'r1',
      'status': 'Confirmed',
      'expectedEntryTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      ...over,
    });

void main() {
  group('đặt chỗ: quy tắc trên app', () {
    test('đơn chờ cọc quá 15 phút giữ chỗ thì không còn trả cọc được', () {
      final fresh = _reservation({
        'status': 'Pending',
        'holdExpiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      });
      expect(fresh.isPending, isTrue);
      expect(fresh.payBefore, isNotNull);

      // Máy chủ cũ không trả holdExpiresAt: tính từ lúc tạo.
      final stale = _reservation({
        'status': 'Pending',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 16)).toIso8601String(),
      });
      expect(stale.isPending, isFalse);
      expect(stale.canModify, isFalse);
    });

    test('huỷ trước giờ hẹn từ 30 phút mới được hoàn cọc', () {
      expect(_reservation({}).refundIfCancelNow, isTrue);
      final soon = _reservation({
        'expectedEntryTime': DateTime.now().add(const Duration(minutes: 20)).toIso8601String(),
      });
      expect(soon.refundIfCancelNow, isFalse);
      expect(soon.isUpcoming, isTrue);
    });

    test('đổi giờ: theo cờ của máy chủ, máy chủ cũ thì tự tính (đã cọc, trước 15 phút)', () {
      expect(_reservation({'canChangeTime': false}).canChangeTime, isFalse);
      expect(_reservation({}).canChangeTime, isTrue);
      expect(_reservation({'status': 'Modified'}).canChangeTime, isFalse);
      final tooLate = _reservation({
        'expectedEntryTime': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      });
      expect(tooLate.canChangeTime, isFalse);
    });

    test('đọc bãi đã đặt', () {
      final r = _reservation({'parkingId': 'p1', 'parkingName': 'Bãi Quận 1'});
      expect(r.parkingName, 'Bãi Quận 1');
    });
  });

  group('đặt chỗ: gọi máy chủ', () {
    test('tạo đặt chỗ gửi kèm bãi đã chọn', () async {
      final api = _FakeApi({'paymentUrl': 'https://pay.os/x', 'reservationId': 'r1'});
      final time = DateTime.utc(2026, 11, 2, 3);
      await PbmsRepository(apiClient: api).createReservation(time, 'v1', parkingId: 'p1');
      final (method, path, body) = api.calls.single;
      expect((method, path), ('POST', '/api/reservations'));
      expect(body, {'vehicleId': 'v1', 'parkingId': 'p1', 'expectedEntryTime': '2026-11-02T03:00:00.000Z'});
    });

    test('suất còn lại của bãi quanh giờ đã chọn', () async {
      final api = _FakeApi({'quota': 8, 'remaining': 3, 'depositAmount': 30000, 'timeError': null});
      final a = await PbmsRepository(apiClient: api)
          .getReservationAvailability('p1', DateTime.utc(2026, 11, 2, 3));
      final (method, path, query) = api.calls.single;
      expect((method, path), ('GET', '/api/reservations/availability'));
      expect(query, {'parkingId': 'p1', 'time': '2026-11-02T03:00:00.000Z'});
      expect(a.open, isTrue);
      expect(a.remaining, 3);
      expect(a.depositAmount, 30000);
    });
  });
}

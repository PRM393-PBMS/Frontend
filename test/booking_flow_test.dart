import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/home/presentation/widgets/lot_photo.dart';

/// ApiClient giả: PUT trả về lời nhắn của máy chủ.
class _FakeApi implements ApiClient {
  final calls = <(String, String)>[];

  @override
  Future<ApiResponse<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      T Function(dynamic json)? fromJsonT}) async {
    calls.add(('PUT', path));
    return ApiResponse<T>(
      statusCode: 200,
      isSuccess: true,
      message: 'Đã hủy đặt chỗ và hoàn 30.000 đ tiền cọc vào ví PBMS',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('huỷ đặt chỗ trả về lời nhắn của máy chủ (số tiền cọc đã hoàn)', () async {
    final api = _FakeApi();
    final message = await PbmsRepository(apiClient: api).cancelReservation('r1');
    expect(api.calls.single, ('PUT', '/api/reservations/r1/cancel'));
    expect(message, contains('hoàn 30.000 đ'));
  });

  test('thanh toán đã hoàn tiền có nhãn riêng', () {
    expect(StatusInfo.payment('Refunded').label, 'Đã hoàn tiền');
  });

  test('bãi đọc ảnh và giờ mở cửa từ máy chủ', () {
    final lot = ParkingLotModel.fromJson({
      'parkingId': 'p1',
      'name': 'Bãi Tao Đàn',
      'location': 'Q3',
      'imageUrl': '/uploads/parkings/tao-dan.jpg',
      'openingHours': '24/7',
      'availability': [],
    });
    expect(lot.imageUrl, '/uploads/parkings/tao-dan.jpg');
    expect(lot.openingHours, '24/7');
  });

  test('ảnh dự phòng cố định theo mã bãi', () {
    expect(LotPhoto.fallbackFor('p1'), LotPhoto.fallbackFor('p1'));
    expect(LotPhoto.fallbackFor('p1'), startsWith('assets/images/promo/'));
  });
}

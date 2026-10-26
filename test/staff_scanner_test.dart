import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_verdict.dart';

Map<String, dynamic> _scanJson({
  String type = 'Guest',
  String? plate = '51H12345',
  Map<String, dynamic>? reservation,
  String status = 'New',
}) =>
    {
      'scanId': 's1',
      'gateName': 'Cổng vào A',
      'imageUrl': '/uploads/gate-scans/a.jpg',
      'licensePlate': plate,
      'capturedAt': '2026-10-27T01:15:02.000Z',
      'suggestedType': type,
      'match': reservation == null ? null : {'reservation': reservation},
      'status': status,
    };

/// ApiClient giả: ghi lại lời gọi POST và trả về một lượt quét.
class _FakeApi implements ApiClient {
  String? path;
  Object? data;

  @override
  Future<ApiResponse<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      T Function(dynamic json)? fromJsonT}) async {
    this.path = path;
    this.data = data;
    return ApiResponse<T>(statusCode: 201, isSuccess: true, result: _scanJson() as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('gửi lượt quét: ảnh, cổng và giờ chụp (UTC) lên /api/GateScan', () async {
    final api = _FakeApi();
    final scan = await PbmsRepository(apiClient: api).sendGateScan(
      gateId: 'g1',
      bytes: Uint8List.fromList([1, 2, 3]),
      capturedAt: DateTime.utc(2026, 10, 27, 1, 15, 2),
    );
    expect(api.path, '/api/GateScan');
    final form = api.data as FormData;
    final fields = Map.fromEntries(form.fields);
    expect(fields['gateId'], 'g1');
    expect(fields['capturedAt'], '2026-10-27T01:15:02.000Z');
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.contentType.toString(), 'image/jpeg');
    expect(scan.licensePlate, '51H12345');
  });

  test('đọc lượt quét: đặt chỗ đúng giờ và trạng thái web', () {
    final scan = GateScanModel.fromJson(_scanJson(
      type: 'Reservation',
      reservation: {'onTime': true, 'expectedEntryTime': '2026-10-27T01:30:00.000Z'},
      status: 'Handled',
    ));
    expect(scan.reservationOnTime, isTrue);
    expect(scan.reservationTime, isNotNull);
    expect(scan.isHandled, isTrue);
  });

  test('nhãn kết quả cho nhân viên ở cổng', () {
    ScanVerdict v(Map<String, dynamic> j) => ScanVerdict.of(GateScanModel.fromJson(j));

    final onTime = v(_scanJson(type: 'Reservation', reservation: {'onTime': true}));
    expect(onTime.label, 'Có đặt chỗ · đúng giờ');
    expect(onTime.color, PbmsTokens.ok);

    final late = v(_scanJson(
        type: 'Reservation', reservation: {'onTime': false, 'expectedEntryTime': '2026-10-27T03:00:00.000Z'}));
    expect(late.label, startsWith('Có đặt chỗ lúc '));
    expect(late.color, PbmsTokens.warn);

    expect(v(_scanJson(type: 'Inside')).color, PbmsTokens.danger);
    expect(v(_scanJson(type: 'Resident')).label, 'Khách vé tháng');
    expect(v(_scanJson(type: 'Guest')).label, 'Khách vãng lai');
    expect(v(_scanJson(type: 'Unknown', plate: null)).label, contains('nhập tay'));
  });

  test('cổng ra / vào', () {
    expect(GateModel.fromJson({'gateId': 'g', 'gateName': 'Ra', 'gateType': 'Exit', 'floorName': 'B1'}).isExit,
        isTrue);
    expect(GateModel.fromJson({'gateId': 'g', 'gateName': 'Vào', 'gateType': 'Entry'}).isExit, isFalse);
  });
}

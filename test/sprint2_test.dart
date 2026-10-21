import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/profile/presentation/widgets/change_email_sheet.dart';

/// ApiClient giả: ghi lại lời gọi, trả `result` theo đường dẫn.
class _FakeApi implements ApiClient {
  final calls = <(String, String, Object?)>[];
  final Map<String, Object?> results;
  final Set<String> notFound;

  _FakeApi(this.results, {this.notFound = const {}});

  Future<ApiResponse<T>> _reply<T>(String method, String path, Object? body) async {
    calls.add((method, path, body));
    if (notFound.contains(path)) throw const NotFoundException(message: 'Không tìm thấy');
    return ApiResponse<T>(statusCode: 200, isSuccess: true, result: results[path] as T?);
  }

  @override
  Future<ApiResponse<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          T Function(dynamic json)? fromJsonT}) =>
      _reply<T>('GET', path, queryParameters);

  @override
  Future<ApiResponse<T>> post<T>(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          T Function(dynamic json)? fromJsonT}) =>
      _reply<T>('POST', path, data);

  @override
  Future<ApiResponse<T>> put<T>(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          T Function(dynamic json)? fromJsonT}) =>
      _reply<T>('PUT', path, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('đổi thông tin đăng nhập', () {
    test('đổi mật khẩu chỉ gọi API có kiểm tra mật khẩu cũ, không có đường dự phòng PUT', () async {
      final api = _FakeApi({}, notFound: {'/api/profile/change-password'});
      final repo = PbmsRepository(apiClient: api);
      await expectLater(
        repo.changePassword(currentPassword: 'cu', newPassword: 'moi123'),
        throwsA(isA<NotFoundException>()),
      );
      expect(api.calls.map((c) => c.$2), ['/api/profile/change-password']);
    });

    test('cập nhật hồ sơ không gửi mật khẩu', () async {
      final api = _FakeApi({'/api/profile': {'userId': 'u', 'email': 'a@b.c'}});
      await PbmsRepository(apiClient: api).updateProfile(fullName: 'A', phoneNumber: '0901234567');
      expect(api.calls.single.$3, {'fullName': 'A', 'phoneNumber': '0901234567'});
    });

    test('đổi email: gửi email mới + mật khẩu, rồi xác nhận OTP', () async {
      final api = _FakeApi({'/api/profile/change-email/verify': {'email': 'moi@gmail.com'}});
      final repo = PbmsRepository(apiClient: api);
      await repo.requestEmailChange(newEmail: 'moi@gmail.com', password: 'x');
      expect(await repo.verifyEmailChange('123456'), 'moi@gmail.com');
      expect(api.calls[0].$3, {'newEmail': 'moi@gmail.com', 'password': 'x'});
      expect(api.calls[1].$3, {'otp': '123456'});
    });

    testWidgets('sheet đổi email chặn email trùng email hiện tại', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ChangeEmailSheet(currentEmail: 'cu@gmail.com'))),
      ));
      await tester.enterText(find.byType(TextFormField).at(0), 'CU@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'x');
      await tester.tap(find.text('Gửi mã xác nhận'));
      await tester.pump();
      expect(find.text('Email mới phải khác email hiện tại'), findsOneWidget);
    });
  });

  group('lịch sử thanh toán', () {
    test('gọi /api/payments/my có phân trang và đọc nhãn, biển số', () async {
      final api = _FakeApi({
        '/api/payments/my': {
          'items': [
            {
              'paymentId': 'p1',
              'amount': 300000,
              'paymentMethod': 'Wallet',
              'paymentType': 'SubscriptionFee',
              'paymentStatus': 'Success',
              'paymentTypeLabel': 'Vé tháng',
              'licensePlate': '59A12345',
            },
          ],
          'page': 2,
          'total': 21,
          'hasMore': false,
        },
      });
      final page = await PbmsRepository(apiClient: api).getMyPayments(page: 2, status: 'Success');
      expect(api.calls.single.$3, {'page': 2, 'pageSize': 20, 'status': 'Success'});
      expect(page.page, 2);
      expect(page.hasMore, isFalse);
      expect(page.items.single.paymentTypeLabel, 'Vé tháng');
      expect(page.items.single.licensePlate, '59A12345');
    });
  });

  group('sự cố', () {
    test('sắp mới nhất trước theo createdAt; chỉ huỷ được khi chưa xử lý xong', () async {
      final api = _FakeApi({
        '/api/IncidentReport/my-reports': [
          {'incidentId': 'cu', 'status': 'Resolved', 'createdAt': '2026-10-01T08:00:00Z'},
          {'incidentId': 'moi', 'status': 'Open', 'createdAt': '2026-10-20T08:00:00Z'},
        ],
      });
      final items = await PbmsRepository(apiClient: api).getMyIncidents();
      expect(items.map((i) => i.incidentId), ['moi', 'cu']);
      expect(items.first.canCancel, isTrue);
      expect(items.last.canCancel, isFalse);
    });

    test('huỷ báo cáo gọi PUT /:id/cancel', () async {
      final api = _FakeApi({
        '/api/IncidentReport/i1/cancel': {'incidentId': 'i1', 'status': 'Cancelled'},
      });
      final item = await PbmsRepository(apiClient: api).cancelIncident('i1');
      expect(api.calls.single.$1, 'PUT');
      expect(item.status, 'Cancelled');
      expect(StatusInfo.incident(item.status).label, 'Đã huỷ');
    });
  });

  group('lượt gửi xe', () {
    ParkingSessionModel session(String readPlate, String? registered) => ParkingSessionModel.fromJson({
          'sessionId': 's1',
          'licensePlateIn': readPlate,
          'registeredLicensePlate': registered,
          'entryImageUrl': '/uploads/gate/in.jpg',
          'exitImageUrl': null,
        });

    test('đọc ảnh cổng và biển đăng ký', () {
      final s = session('59A-123.45', '59A12345');
      expect(s.entryImageUrl, '/uploads/gate/in.jpg');
      expect(s.exitImageUrl, isNull);
      expect(s.registeredLicensePlate, '59A12345');
    });

    test('cảnh báo khi biển đọc được khác biển đăng ký (bỏ qua dấu, hoa thường)', () {
      expect(session('59A-123.45', '59a12345').plateMismatch, isFalse);
      expect(session('59A-123.46', '59A12345').plateMismatch, isTrue);
      expect(session('59A12345', null).plateMismatch, isFalse);
    });
  });

  group('ví và hợp đồng', () {
    test('lịch sử ví theo bộ lọc dùng đúng endpoint', () async {
      final api = _FakeApi({
        '/api/wallet': {'walletId': 'w1'},
        '/api/wallet/w1/spends': [
          {'walletTransactionId': 't1', 'direction': 'Debit', 'amount': -20000, 'absoluteAmount': 20000},
        ],
      });
      final items = await PbmsRepository(apiClient: api).getWalletHistory(WalletHistoryFilter.spends);
      expect(api.calls.last.$2, '/api/wallet/w1/spends');
      expect(items.single.isCredit, isFalse);
      expect(items.single.amount, 20000);
    });

    test('hợp đồng của tôi đọc createdAt và nhãn trạng thái', () async {
      final api = _FakeApi({
        '/api/contracts/my': [
          {'contractId': 'c1', 'subscriptionId': 's1', 'contractNumber': 'HD-001', 'status': 'PendingSignature', 'createdAt': '2026-10-20T08:00:00Z'},
        ],
      });
      final items = await PbmsRepository(apiClient: api).getMyContracts();
      expect(items.single.createdAt!.isAtSameMomentAs(DateTime.parse('2026-10-20T08:00:00Z')), isTrue);
      expect(StatusInfo.contract(items.single.status).label, 'Chờ ký');
    });
  });
}

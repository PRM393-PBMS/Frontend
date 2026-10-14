import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prm393_frontend/app.dart';
import 'package:prm393_frontend/core/l10n/locale_controller.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import 'package:prm393_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:prm393_frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/catalog/data/catalog_repository.dart';
import 'package:prm393_frontend/features/incidents/data/incident_repository.dart';
import 'package:prm393_frontend/features/notifications/data/notification_repository.dart';
import 'package:prm393_frontend/features/profile/data/profile_repository.dart';
import 'package:prm393_frontend/features/reservations/data/reservation_repository.dart';
import 'package:prm393_frontend/features/sessions/data/session_repository.dart';
import 'package:prm393_frontend/features/subscriptions/data/subscription_repository.dart';
import 'package:prm393_frontend/features/wallet/data/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> ok(Object? result) =>
    {'statusCode': 200, 'message': 'OK', 'isSuccess': true, 'result': result};

class Backend implements HttpClientAdapter {
  final String role;

  /// Các path trả về lỗi 500 không bọc envelope, giống NestJS khi ném exception.
  final Set<String> failing;
  Backend(this.role, {this.failing = const {}});

  static const _session = {
    'sessionId': '11111111-1111-1111-1111-111111111111',
    'licensePlateIn': '51H12345',
    'vehicleTypeName': 'Ô tô',
    'entryTime': '2026-10-15T01:00:00.000Z',
    'entryGateName': 'Cổng A',
    'actualSlotCode': 'B2-07',
    'status': 'Active',
    'ticket': {'qrPayload': '11111111-1111-1111-1111-111111111111'},
  };

  Object? route(String method, String path) {
    switch ('$method $path') {
      case 'POST /api/Auth/login':
        return ok({
          'user': {
            'userId': 'u1',
            'userName': 'minhanh',
            'email': 'minh.anh@gmail.com',
            'fullName': 'Trần Minh Anh',
            'phoneNumber': '0912345678',
            'roleName': role,
          },
          'accessToken': 'a',
          'refreshToken': 'r',
        });
      case 'GET /api/ParkingSession/my':
      case 'GET /api/ParkingSession':
        return ok([_session]);
      case 'GET /api/reservations/my-reservations':
        return ok([
          {
            'reservationId': 'r1',
            'vehicleTypeName': 'Ô tô',
            'expectedEntryTime': DateTime.now()
                .add(const Duration(hours: 2))
                .toUtc()
                .toIso8601String(),
            'status': 'Confirmed',
            'createdAt': '2026-10-15T00:00:00.000Z',
            'ticket': {'qrPayload': 'r1'},
          }
        ]);
      case 'GET /api/ParkingOperation/availability':
        return ok([
          {
            'floorId': 'f1',
            'floorName': 'Tầng B1',
            'vehicleTypeId': 'm',
            'vehicleTypeName': 'Xe máy',
            'totalSlots': 120,
            'availableSlots': 33
          },
          {
            'floorId': 'f2',
            'floorName': 'Tầng B2',
            'vehicleTypeId': 'c',
            'vehicleTypeName': 'Ô tô',
            'totalSlots': 40,
            'availableSlots': 12
          },
        ]);
      case 'GET /api/Floor':
        return ok([
          {
            'floorId': 'f1',
            'floorName': 'Tầng B1',
            'isResident': false,
            'totalCapacity': 120
          },
          {
            'floorId': 'f2',
            'floorName': 'Tầng B2',
            'isResident': false,
            'totalCapacity': 40
          },
        ]);
      case 'GET /api/PricingPolicy':
        return ok([
          {
            'policyId': 'p',
            'vehicleTypeId': 'c',
            'vehicleTypeName': 'Ô tô',
            'basePrice': 30000,
            'baseHours': 2,
            'extraHourPrice': 7500,
            'nightSurcharge': 10000,
            'effectiveDate': '2026-01-01T00:00:00.000Z',
            'status': 'Active'
          },
        ]);
      case 'GET /api/MonthlySubscription/my':
        return ok([
          {
            'subscriptionId': 's1',
            'licensePlate': '59A99887',
            'vehicleType': 'Xe máy',
            'packageName': 'Xe máy 1 tháng',
            'startDate': '2026-10-01T00:00:00.000Z',
            'endDate': '2026-11-01T00:00:00.000Z',
            'price': 120000,
            'status': 'Active'
          },
        ]);
      case 'GET /api/VehicleChangeRequest/my-requests':
      case 'GET /api/IncidentReport/my-reports':
        return ok([]);
      case 'GET /api/IncidentReport':
        return ok([
          {
            'incidentId': 'i1',
            'reportedByUserFullName': 'Lê Quốc Bảo',
            'issueType': 'Sai phí gửi xe',
            'description': 'Bị tính thêm 1 giờ',
            'status': 'Open'
          },
        ]);
      case 'GET /api/Gate':
        return ok([
          {
            'gateId': 'g1',
            'gateName': 'Cổng A',
            'gateType': 'Entry',
            'floorId': 'f1',
            'floorName': 'Tầng B1'
          },
          {
            'gateId': 'g2',
            'gateName': 'Cổng B',
            'gateType': 'Exit',
            'floorId': 'f1',
            'floorName': 'Tầng B1'
          },
        ]);
      case 'GET /api/VehicleType':
        return ok([
          {'vehicleTypeId': 'c', 'typeName': 'Ô tô'},
          {'vehicleTypeId': 'm', 'typeName': 'Xe máy'},
        ]);
      case 'POST /api/wallet':
        return ok({'walletId': 'w-1', 'userId': 'u1', 'walletBalance': 250000});
      case 'GET /api/wallet/w-1':
        return ok({
          'walletId': 'w-1',
          'userId': 'u1',
          'walletBalance': 250000,
          'transactions': [
            {
              'walletTransactionId': 't1',
              'direction': 'Debit',
              'type': 'SubscriptionFee',
              'amount': -1500000,
              'absoluteAmount': 1500000,
              'balanceAfter': 250000,
              'createdAt': '2026-10-15T01:00:00.000Z',
              'packageName': 'Gói tháng ô tô có vị trí cố định',
              'licensePlate': '51H12345',
            },
          ],
        });
      case 'GET /api/Notification/my':
        return ok({'items': [], 'unreadCount': 0, 'total': 0});
    }
    if (method == 'GET' &&
        path.startsWith('/api/ParkingSession/my/') &&
        path.endsWith('fee-preview')) {
      return ok({
        'sessionId': 's',
        'licensePlate': '51H12345',
        'totalHours': 1.5,
        'billedHours': 2,
        'amount': 30000,
        'basePrice': 30000,
        'baseHours': 2,
        'extraHourPrice': 7500
      });
    }
    if (method == 'GET' && path.endsWith('checkout-payment')) {
      return ok({'Payment': null, 'OnlinePayment': null});
    }
    return null;
  }

  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    if (failing.contains(o.path)) {
      return ResponseBody.fromString(
        jsonEncode({'statusCode': 500, 'message': 'Internal server error'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );
    }
    final body = route(o.method, o.path);
    final status = body == null ? 404 : 200;
    return ResponseBody.fromString(
      jsonEncode(body ??
          {'statusCode': 404, 'message': 'not found', 'isSuccess': false}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpApp(WidgetTester tester, String role,
    {Set<String> failing = const {}}) async {
  final storage = SecureStorageService();
  final dio = Dio(
      BaseOptions(baseUrl: 'http://test', contentType: Headers.jsonContentType))
    ..httpClientAdapter = Backend(role, failing: failing);
  final api = ApiClient(storageService: storage, customDio: dio);
  final authRepo = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient: api),
    storageService: storage,
  );
  final bloc = AuthBloc(authRepository: authRepo)..add(AuthCheckRequested());
  await tester.pumpWidget(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: api),
      RepositoryProvider(create: (_) => CatalogRepository(api)),
      RepositoryProvider(create: (_) => ReservationRepository(api)),
      RepositoryProvider(create: (_) => SessionRepository(api)),
      RepositoryProvider(create: (_) => SubscriptionRepository(api)),
      RepositoryProvider(create: (_) => IncidentRepository(api)),
      RepositoryProvider(create: (_) => NotificationRepository(api)),
      RepositoryProvider(create: (_) => ProfileRepository(api)),
      RepositoryProvider(create: (_) => WalletRepository(api)),
    ],
    child: BlocProvider.value(
        value: bloc, child: const ParkingApp(showOnboarding: false)),
  ));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  expect(find.text('Đăng nhập'), findsWidgets);
  await tester.enterText(
      find.byType(TextFormField).at(0), 'minh.anh@gmail.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'matkhau123');
  await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets(
        'Khách hàng: đăng nhập và duyệt các tab (${size.width.toInt()}px)',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpApp(tester, 'User');
      await login(tester);

      expect(find.text('Trần Minh Anh'), findsOneWidget);
      expect(find.textContaining('Đã gửi'), findsWidgets);

      await tester.tap(find.text('Lịch sử').last);
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử gửi xe'), findsOneWidget);

      await tester.tap(find.text('51H12345').first);
      await tester.pumpAndSettle();
      expect(find.text('Lượt gửi xe'), findsOneWidget);
      expect(find.text('Phí tạm tính'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vé tháng').last);
      await tester.pumpAndSettle();
      expect(find.text('59A99887'), findsOneWidget);

      await tester.tap(find.text('Tài khoản').last);
      await tester.pumpAndSettle();
      expect(find.text('Mở khóa bằng sinh trắc học'), findsOneWidget);

      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đặt chỗ ô tô'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt chỗ ô tô'));
      await tester.pumpAndSettle();
      expect(find.text('Giờ vào bãi'), findsOneWidget);
      expect(find.text('12 chỗ'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Chỗ trống theo tầng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỗ trống theo tầng'));
      await tester.pumpAndSettle();
      expect(find.text('Tầng B2'), findsOneWidget);
      expect(find.text('Bảng giá gửi xe'), findsOneWidget);
    });
  }

  testWidgets('Đổi ngôn ngữ sang English và 日本語 cập nhật toàn bộ giao diện',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => LocaleController.instance.setLocale(const Locale('vi')));

    await pumpApp(tester, 'User');
    await login(tester);

    await tester.tap(find.text('Tài khoản').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsWidgets);
    expect(find.text('Biometric unlock'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.ensureVisible(find.text('日本語'));
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    expect(find.text('アカウント'), findsWidgets);
    expect(find.text('ホーム'), findsOneWidget);

    await tester.tap(find.text('履歴'));
    await tester.pumpAndSettle();
    expect(find.text('駐車履歴'), findsOneWidget);
  });

  for (final code in ['vi', 'en', 'ja']) {
    testWidgets('Bố cục không tràn ở mọi màn hình chính ($code, 360px)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(
          () => LocaleController.instance.setLocale(const Locale('vi')));
      await LocaleController.instance.setLocale(Locale(code));

      for (final role in ['User', 'Staff']) {
        await pumpApp(tester, role);
        await tester.enterText(
            find.byType(TextFormField).at(0), 'minh.anh@gmail.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'matkhau123');
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
        final tabs = role == 'User'
            ? [
                Icons.receipt_long_outlined,
                Icons.directions_car_outlined,
                Icons.person_outline_rounded
              ]
            : [
                Icons.logout_rounded,
                Icons.local_parking_outlined,
                Icons.report_outlined,
                Icons.person_outline_rounded
              ];
        for (final icon in tabs) {
          await tester.tap(find.byIcon(icon).last);
          await tester.pumpAndSettle();
        }
        if (role == 'User') {
          // Tài khoản → Ví PBMS
          await tester
              .tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
          await tester.pumpAndSettle();
          expect(find.text('Gói tháng ô tô có vị trí cố định'), findsNothing);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.home_outlined).last);
          await tester.pumpAndSettle();
          for (final icon in [
            Icons.event_available_rounded,
            Icons.local_parking_rounded
          ]) {
            await tester.ensureVisible(find.byIcon(icon).last);
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(icon).last);
            await tester.pumpAndSettle();
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox());
        FlutterSecureStorage.setMockInitialValues({});
      }
    });
  }

  testWidgets('Trang chủ vẫn hiển thị khi /ParkingSession/my lỗi 500',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, 'User', failing: {'/api/ParkingSession/my'});
    await login(tester);

    // Lỗi phiên gửi xe chỉ hiện nội tuyến; đặt chỗ và chỗ trống vẫn hiển thị.
    expect(find.text('Internal server error'), findsOneWidget);
    expect(find.text('Đã xác nhận'), findsOneWidget);
    expect(find.text('Xe máy: 33 trống'), findsOneWidget);
    expect(find.text('Không tải được dữ liệu'), findsNothing);

    // Tab Vé tháng vẫn hiện vé dù không có lịch sử gửi xe.
    await tester.tap(find.text('Vé tháng').last);
    await tester.pumpAndSettle();
    expect(find.text('59A99887'), findsOneWidget);
  });

  testWidgets('Nhân viên: vào khu vận hành cổng', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, 'Staff');
    await login(tester);

    expect(find.text('Xe vào bãi'), findsOneWidget);
    expect(find.text('Cổng A, Tầng B1'), findsOneWidget);
    expect(find.text('Ô tô'), findsWidgets);

    await tester.tap(find.text('Ra bãi'));
    await tester.pumpAndSettle();
    expect(find.text('Tính phí và cho xe ra'), findsOneWidget);

    await tester.tap(find.text('Phiên gửi'));
    await tester.pumpAndSettle();
    expect(find.text('1 phiên'), findsOneWidget);

    await tester.tap(find.text('Sự cố').last);
    await tester.pumpAndSettle();
    expect(find.text('Sai phí gửi xe'), findsOneWidget);
  });
}

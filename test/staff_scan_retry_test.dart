import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';
import 'package:prm393_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:prm393_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:prm393_frontend/features/auth/presentation/blocs/auth_event.dart';
import 'package:prm393_frontend/features/staff/data/pending_scan_store.dart';
import 'package:prm393_frontend/features/staff/data/staff_models.dart';
import 'package:prm393_frontend/features/staff/presentation/staff_scanner_screen.dart';

class _Auth implements AuthRepository {
  @override
  Future<UserEntity?> getCurrentUser() async => const UserEntity(
        id: 'staff-a',
        userName: 'staff',
        email: 'staff@example.com',
        roleName: 'staff',
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements PbmsRepository {
  int sends = 0;
  String? gate;
  DateTime? time;
  Object? failure;
  Completer<GateScanModel>? response;

  @override
  Future<GateScanModel> sendGateScan(
      {required String gateId,
      required Uint8List bytes,
      required DateTime capturedAt}) async {
    sends++;
    gate = gateId;
    time = capturedAt;
    if (failure != null) throw failure!;
    if (response != null) return response!.future;
    return GateScanModel.fromJson({
      'scanId': 'scan-1',
      'gateName': 'Cổng vào',
      'licensePlate': '51H12345',
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'suggestedType': 'Guest',
      'status': 'New',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthBloc auth;
  late _Repo repo;
  late PendingScanStore store;
  late PendingScan capture;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'staff.gate.v1': jsonEncode({
        'gateId': 'current-gate',
        'gateName': 'Cổng hiện tại',
        'gateType': 'Entry'
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    store = PendingScanStore(prefs, 'staff-a');
    capture = PendingScan(
        id: 7,
        gateId: 'original-gate',
        capturedAt: DateTime.utc(2026, 11, 1, 8),
        bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='));
    await store.put(capture);
    repo = _Repo();
    auth = AuthBloc(authRepository: _Auth());
    auth.add(AuthCheckRequested());
    await auth.stream.firstWhere((state) => state.isAuthenticated);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      (_) async => [],
    );
  });
  tearDown(() async => auth.close());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(RepositoryProvider<PbmsRepository>.value(
      value: repo,
      child: BlocProvider<AuthBloc>.value(
        value: auth,
        child: const MaterialApp(home: StaffScannerScreen()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('restores pending images without automatically uploading',
      (tester) async {
    await open(tester);
    expect(find.text('Chạm để gửi lại'), findsOneWidget);
    expect(repo.sends, 0);
    expect(store.load(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'retry uses the original gate and time; success removes the saved photo',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('Chạm để gửi lại'));
    await tester.pumpAndSettle();
    expect(repo.sends, 1);
    expect(repo.gate, capture.gateId);
    expect(repo.time!.isAtSameMomentAs(capture.capturedAt), isTrue);
    expect(store.load(), isEmpty);
    expect(find.text('51H12345'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network error shows a reason and retains photo for reopening',
      (tester) async {
    repo.failure = const NetworkException();
    await open(tester);
    await tester.tap(find.text('Chạm để gửi lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kiểm tra mạng'), findsOneWidget);
    expect(store.load().single.id, capture.id);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await open(tester);
    expect(find.text('Chạm để gửi lại'), findsOneWidget);
    expect(repo.sends, 1);
  });

  testWidgets('discard requires confirmation and deletes only the chosen image',
      (tester) async {
    await open(tester);
    await tester.longPress(find.text('Chạm để gửi lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giữ ảnh'));
    await tester.pumpAndSettle();
    expect(store.load(), hasLength(1));
    await tester.longPress(find.text('Chạm để gửi lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa ảnh'));
    await tester.pumpAndSettle();
    expect(store.load(), isEmpty);
    expect(repo.sends, 0);
  });

  testWidgets('leaving during upload does not call setState after disposal',
      (tester) async {
    repo.response = Completer<GateScanModel>();
    await open(tester);
    await tester.tap(find.text('Chạm để gửi lại'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repo.response!.complete(GateScanModel.fromJson(
        {'scanId': 's', 'capturedAt': capture.capturedAt.toIso8601String()}));
    await tester.pumpAndSettle();
    expect(store.load(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}

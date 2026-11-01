import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/features/staff/data/pending_scan_store.dart';
import 'package:prm393_frontend/features/staff/presentation/scan_error.dart';

PendingScan scan(int id, {int size = 3}) => PendingScan(
      id: id,
      gateId: 'gate-$id',
      capturedAt: DateTime.utc(2026, 11, 1, 8),
      bytes: Uint8List(size)..[0] = 42,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late PendingScanStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PendingScanStore(prefs, 'staff-a');
  });

  test('restores photo, gate and original capture time after reopening',
      () async {
    final original = scan(1);
    await store.put(original);
    final snapshot = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
    SharedPreferences.setMockInitialValues(snapshot);
    final reopenedPrefs = await SharedPreferences.getInstance();
    final restored = PendingScanStore(reopenedPrefs, 'staff-a').load().single;
    expect(restored.bytes, original.bytes);
    expect(restored.gateId, original.gateId);
    expect(restored.capturedAt.isAtSameMomentAs(original.capturedAt), isTrue);
    expect(restored.id, original.id);
  });

  test('staff accounts cannot see or delete each other\'s pending images',
      () async {
    await store.put(scan(1));
    final other = PendingScanStore(prefs, 'staff-b');
    expect(other.load(), isEmpty);
    await other.put(scan(1));
    await other.remove(1);
    expect(store.load().single.gateId, 'gate-1');
  });

  test('concurrent captures and removal do not overwrite each other', () async {
    await store.put(scan(0));
    await Future.wait(
        [store.put(scan(1)), store.remove(0), store.put(scan(2))]);
    expect(store.load().map((item) => item.id), [1, 2]);
  });

  test('retries replace the same queue item instead of duplicating it',
      () async {
    await store.put(scan(1));
    await store.put(scan(1));
    expect(store.load(), hasLength(1));
    await store.remove(1);
    expect(PendingScanStore(prefs, 'staff-a').load(), isEmpty);
  });

  test('a ninth pending image is rejected without losing the first eight',
      () async {
    for (var i = 0; i < PendingScanStore.maxCount; i++) {
      await store.put(scan(i));
    }
    await expectLater(store.put(scan(9)), throwsStateError);
    expect(store.load().map((item) => item.id), List.generate(8, (i) => i));
    await store.remove(0);
    await store.put(scan(9));
    expect(store.load().last.id, 9);
  });

  test('enforces total byte limit and recovers after rejection', () async {
    await store.put(scan(1, size: PendingScanStore.maxBytes));
    await expectLater(store.put(scan(2)), throwsStateError);
    expect(store.load().single.id, 1);
    await store.remove(1);
    await store.put(scan(2));
    expect(store.load().single.id, 2);
  });

  test('corrupt storage is reported and not silently deleted', () async {
    await prefs.setString('staff.pending-scans.v1.staff-a', 'invalid json');
    expect(store.load, throwsFormatException);
    await expectLater(store.put(scan(1)), throwsFormatException);
    expect(prefs.getString('staff.pending-scans.v1.staff-a'), 'invalid json');
  });

  test('distinguishes network, session, permission, size and server errors',
      () {
    expect(scanErrorText(const NetworkException()), contains('Kiểm tra mạng'));
    expect(scanErrorText(const UnauthorizedException()),
        contains('Đăng nhập lại'));
    expect(
        scanErrorText(const ForbiddenException()), contains('không có quyền'));
    expect(
        scanErrorText(const ServerException(statusCode: 413)), contains('8MB'));
    expect(scanErrorText(const ServerException(statusCode: 503)),
        contains('Máy chủ đang lỗi'));
    expect(
        scanErrorText(const ValidationException(message: 'Cổng không hợp lệ')),
        'Cổng không hợp lệ');
  });
}

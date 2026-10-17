import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_frontend/core/services/app_lock_controller.dart';
import 'package:prm393_frontend/core/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBiometric extends BiometricService {
  BiometricResult next = BiometricResult.success;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<BiometricResult> authenticate({String reason = ''}) async => next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBiometric biometric;
  late AppLockController lock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    biometric = _FakeBiometric();
    lock = AppLockController(
      biometric: biometric,
      timeout: const Duration(milliseconds: 50),
    );
    await lock.init();
    lock.onSignedInChanged(true);
  });

  tearDown(() => lock.dispose());

  test('Rời app ngắn hơn thời gian chờ thì không khoá', () {
    lock.didChangeAppLifecycleState(AppLifecycleState.hidden);
    lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(lock.isLocked, isFalse);
  });

  test('Rời app quá thời gian chờ thì khoá, xác thực thành công thì mở', () async {
    lock.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(lock.isLocked, isTrue);

    biometric.next = BiometricResult.canceled;
    await lock.unlock();
    expect(lock.isLocked, isTrue);

    biometric.next = BiometricResult.success;
    await lock.unlock();
    expect(lock.isLocked, isFalse);
  });

  test('Hộp thoại hệ thống (inactive) không tính là rời app', () async {
    lock.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(lock.isLocked, isFalse);
  });

  test('Khôi phục phiên khi mở app thì khoá ngay; đăng xuất thì gỡ khoá', () {
    final fresh = AppLockController(biometric: biometric);
    fresh.onSignedInChanged(true, restoredSession: true);
    expect(fresh.isLocked, isFalse, reason: 'chưa init nên chưa biết máy hỗ trợ');

    lock.onSignedInChanged(false);
    lock.onSignedInChanged(true, restoredSession: true);
    expect(lock.isLocked, isTrue);
    lock.onSignedInChanged(false);
    expect(lock.isLocked, isFalse);
    fresh.dispose();
  });

  test('Tắt khoá thì rời app lâu cũng không khoá', () async {
    expect(await lock.setEnabled(false), isTrue);
    lock.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(lock.isLocked, isFalse);
  });
}

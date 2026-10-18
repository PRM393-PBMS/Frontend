import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'web_auth.dart';

/// Kết quả một lần xác thực.
enum BiometricResult { success, canceled, unavailable, lockedOut, failed }

/// Xác thực bằng API sinh trắc học chính thức của nền tảng:
/// - Android / iOS: gói `local_auth` (BiometricPrompt, LocalAuthentication / Face ID / Touch ID).
/// - Web: Web Authentication API (WebAuthn) của trình duyệt (Windows Hello, Touch ID, vân tay...).
class BiometricService {
  BiometricService();
  static final BiometricService instance = BiometricService();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Thiết bị có thể xác thực (sinh trắc học hoặc mã khoá màn hình).
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return WebAuth.isAvailable();
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Loại sinh trắc học đã đăng ký trên máy (vân tay, khuôn mặt...).
  Future<List<BiometricType>> enrolledBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Hiện hộp thoại xác thực của hệ thống. Cho phép dùng mã khoá màn hình
  /// làm phương án dự phòng khi sinh trắc học không khả dụng.
  Future<BiometricResult> authenticate({
    String reason = 'Xác thực để mở khoá ứng dụng PBMS',
  }) async {
    if (!await canAuthenticate()) return BiometricResult.unavailable;
    if (kIsWeb) {
      return switch (await WebAuth.authenticate('PBMS')) {
        'success' => BiometricResult.success,
        'canceled' => BiometricResult.canceled,
        'unavailable' => BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      debugPrint('Biometric exception: ${e.code} ${e.description}');
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress =>
          BiometricResult.canceled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } catch (e) {
      debugPrint('Biometric general exception: $e');
      return BiometricResult.failed;
    }
  }

  /// Quên khoá WebAuthn đã tạo trên trình duyệt (khi người dùng tắt khoá).
  void resetWebCredential() {
    if (kIsWeb) WebAuth.reset();
  }
}

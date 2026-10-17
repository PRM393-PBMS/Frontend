import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Kết quả một lần xác thực.
enum BiometricResult { success, canceled, unavailable, lockedOut, failed }

/// Xác thực bằng API sinh trắc học của hệ điều hành qua gói `local_auth`
/// (Android BiometricPrompt, iOS LocalAuthentication / Face ID / Touch ID).
class BiometricService {
  BiometricService();
  static final BiometricService instance = BiometricService();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Thiết bị có thể xác thực (sinh trắc học hoặc mã khoá màn hình).
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
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
}

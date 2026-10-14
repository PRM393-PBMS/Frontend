import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Xác thực sinh trắc học bằng API gốc của hệ điều hành:
/// Android BiometricPrompt (khóa phần cứng Keystore; trên Samsung chạy trên vùng
/// bảo mật Knox) và iOS LocalAuthentication (Touch ID / Face ID).
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const _kEnabled = 'pbms_biometric_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  /// Thiết bị có cảm biến và đã đăng ký ít nhất một vân tay / khuôn mặt.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      debugPrint('Biometric availability error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> enrolledTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Hiện hộp thoại hệ thống. Chỉ chấp nhận sinh trắc học (không dùng PIN thay thế).
  Future<bool> authenticate({required String reason}) async {
    if (!await isAvailable()) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Biometric authenticate error: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, value);
    } catch (_) {}
  }
}

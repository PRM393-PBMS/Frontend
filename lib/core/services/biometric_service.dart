import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra điện thoại có hỗ trợ cảm biến vân tay thật không
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Gọi cảm biến vân tay THẬT của điện thoại (Android BiometricPrompt)
  Future<bool> authenticateWithDevice({
    String reason = 'Quét vân tay để mở khoá thẻ xe và kích hoạt thanh toán NFC',
  }) async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await canAuthenticate();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric platform exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Biometric general exception: $e');
      return false;
    }
  }
}

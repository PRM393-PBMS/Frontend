import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'biometric_service.dart';

/// Khoá ứng dụng bằng sinh trắc học khi người dùng rời app quá [timeout].
///
/// Thời điểm rời app được ghi khi vòng đời chuyển sang `hidden`/`paused`
/// (bấm Home, chuyển app, tắt màn hình). Trạng thái `inactive` bị bỏ qua vì
/// chính hộp thoại sinh trắc học của hệ thống cũng gây ra trạng thái này.
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController({
    BiometricService? biometric,
    this.timeout = const Duration(minutes: 1),
  }) : _biometric = biometric ?? BiometricService.instance;

  /// Instance dùng chung cho toàn app (khởi tạo trong `main`).
  static final AppLockController instance = AppLockController();

  static const _prefKey = 'biometric_lock_enabled';

  final BiometricService _biometric;
  final Duration timeout;

  bool _supported = false;
  bool _enabled = true;
  bool _locked = false;
  bool _signedIn = false;
  bool _authenticating = false;
  DateTime? _leftAt;

  /// Thiết bị hỗ trợ xác thực của hệ điều hành.
  bool get isSupported => _supported;

  /// Người dùng bật khoá sinh trắc học (mặc định bật).
  bool get isEnabled => _enabled && _supported;

  bool get isLocked => _locked;
  bool get isAuthenticating => _authenticating;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _supported = await _biometric.canAuthenticate();
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
  }

  /// Gọi khi trạng thái đăng nhập thay đổi. Mở app lại khi còn phiên đăng
  /// nhập cũng tính là "đã rời app", nên khoá ngay.
  void onSignedInChanged(bool signedIn, {bool restoredSession = false}) {
    if (_signedIn == signedIn) return;
    _signedIn = signedIn;
    if (!signedIn) {
      _locked = false;
      _leftAt = null;
    } else if (restoredSession && isEnabled) {
      _locked = true;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Không ghi đè thời điểm rời app khi đang hiện hộp thoại xác thực.
        if (!_authenticating) _leftAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        if (leftAt != null &&
            _signedIn &&
            isEnabled &&
            !_locked &&
            DateTime.now().difference(leftAt) >= timeout) {
          _locked = true;
          notifyListeners();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Hiện hộp thoại sinh trắc học; mở khoá nếu thành công.
  Future<BiometricResult> unlock() async {
    if (_authenticating) return BiometricResult.canceled;
    _authenticating = true;
    notifyListeners();
    final result = await _biometric.authenticate(
      reason: 'Xác thực để tiếp tục dùng PBMS',
    );
    _authenticating = false;
    if (result == BiometricResult.success ||
        result == BiometricResult.unavailable) {
      // Máy đã gỡ hết phương thức khoá: không giam người dùng ngoài app.
      _locked = false;
      if (result == BiometricResult.unavailable) _supported = false;
    }
    notifyListeners();
    return result;
  }

  /// Bật/tắt khoá. Cả hai chiều đều cần xác thực để tránh người khác tắt hộ.
  Future<bool> setEnabled(bool value) async {
    if (!_supported) return false;
    final result = await _biometric.authenticate(
      reason: value
          ? 'Xác thực để bật khoá sinh trắc học'
          : 'Xác thực để tắt khoá sinh trắc học',
    );
    if (result != BiometricResult.success) return false;
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

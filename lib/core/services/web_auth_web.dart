import 'dart:js_interop';

@JS('pbmsWebAuthn')
external _PbmsWebAuthn? get _bridge;

extension type _PbmsWebAuthn._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> isAvailable();
  external JSPromise<JSString> authenticate(JSString displayName);
  external void reset();
}

/// WebAuthn qua `window.pbmsWebAuthn` (web/webauthn.js).
class WebAuth {
  WebAuth._();

  static Future<bool> isAvailable() async {
    final b = _bridge;
    if (b == null) return false;
    try {
      return (await b.isAvailable().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  /// 'success' | 'canceled' | 'unavailable' | 'failed'
  static Future<String> authenticate(String displayName) async {
    final b = _bridge;
    if (b == null) return 'unavailable';
    try {
      return (await b.authenticate(displayName.toJS).toDart).toDart;
    } catch (_) {
      return 'failed';
    }
  }

  static void reset() => _bridge?.reset();
}

// Xác thực sinh trắc học trên web qua WebAuthn (web/webauthn.js).
// Trên Android/iOS/desktop dùng bản rỗng; BiometricService dùng local_auth.
export 'web_auth_stub.dart' if (dart.library.js_interop) 'web_auth_web.dart';

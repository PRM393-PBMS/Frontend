import '../config/app_config.dart';

/// Đường dẫn ảnh từ máy chủ (avatar, ảnh sự cố) thành URL tải được.
///
/// - Đường dẫn tương đối ("/uploads/..") ghép với địa chỉ máy chủ.
/// - Máy chủ sau proxy (Render) đôi khi trả "http://" cho chính nó: Android chặn
///   http thường, nên đổi sang https khi cùng host với máy chủ đang dùng https.
String? resolveMediaUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final base = Uri.parse(AppConfig.baseUrl);
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (!uri.hasScheme) return base.resolve(value).toString();
  if (uri.scheme == 'http' && base.scheme == 'https' && uri.host == base.host) {
    return uri.replace(scheme: 'https', port: base.hasPort ? base.port : null).toString();
  }
  return uri.toString();
}

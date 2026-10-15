/// Đọc an toàn từ JSON của backend PBMS (chấp nhận camelCase lẫn PascalCase).
class JsonRead {
  JsonRead._();

  static dynamic _pick(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    final pascal = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    return json[pascal];
  }

  static String str(Map<String, dynamic> json, String key, [String fallback = '']) {
    final v = _pick(json, key);
    return v == null ? fallback : v.toString();
  }

  static String? strOrNull(Map<String, dynamic> json, String key) {
    final v = _pick(json, key);
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static double num_(Map<String, dynamic> json, String key, [double fallback = 0]) {
    final v = _pick(json, key);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static double? numOrNull(Map<String, dynamic> json, String key) {
    final v = _pick(json, key);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int int_(Map<String, dynamic> json, String key, [int fallback = 0]) =>
      numOrNull(json, key)?.round() ?? fallback;

  static bool bool_(Map<String, dynamic> json, String key, [bool fallback = false]) {
    final v = _pick(json, key);
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? date(Map<String, dynamic> json, String key) {
    final v = _pick(json, key);
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static Map<String, dynamic>? map(Map<String, dynamic> json, String key) {
    final v = _pick(json, key);
    return v is Map<String, dynamic> ? v : null;
  }

  static List<Map<String, dynamic>> list(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}

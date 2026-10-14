/// Đọc JSON an toàn: backend PBMS trả số tiền dạng number, ngày dạng ISO string,
/// và một số khóa PascalCase (`Payment`, `Fee`, `Session`).
extension JsonRead on Map<String, dynamic> {
  dynamic _pick(String key) {
    if (containsKey(key)) return this[key];
    final pascal = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    return this[pascal];
  }

  String str(String key, [String fallback = '']) {
    final v = _pick(key);
    if (v == null) return fallback;
    return v.toString();
  }

  String? strOrNull(String key) {
    final v = _pick(key);
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  double number(String key, [double fallback = 0]) {
    final v = _pick(key);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  double? numberOrNull(String key) {
    final v = _pick(key);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int integer(String key, [int fallback = 0]) {
    final v = _pick(key);
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = _pick(key);
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  DateTime? date(String key) {
    final v = _pick(key);
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  Map<String, dynamic>? obj(String key) {
    final v = _pick(key);
    return v is Map<String, dynamic> ? v : null;
  }
}

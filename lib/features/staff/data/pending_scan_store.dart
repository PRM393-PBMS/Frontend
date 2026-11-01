import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class PendingScan {
  final int id;
  final String gateId;
  final DateTime capturedAt;
  final Uint8List bytes;

  const PendingScan(
      {required this.id,
      required this.gateId,
      required this.capturedAt,
      required this.bytes});

  Map<String, dynamic> toJson() => {
        'id': id,
        'gateId': gateId,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'bytes': base64Encode(bytes),
      };

  factory PendingScan.fromJson(Map<String, dynamic> json) => PendingScan(
        id: json['id'] as int,
        gateId: json['gateId'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
        bytes: base64Decode(json['bytes'] as String),
      );
}

/// Hàng đợi riêng từng tài khoản; giới hạn dung lượng để ảnh không làm đầy preferences.
class PendingScanStore {
  static const maxCount = 8;
  static const maxBytes = 8 * 1024 * 1024;
  final SharedPreferences _prefs;
  final String _key;
  Future<void> _writes = Future.value();

  PendingScanStore(this._prefs, String userId)
      : _key = 'staff.pending-scans.v1.$userId';

  List<PendingScan> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((row) =>
            PendingScan.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> put(PendingScan scan) => _update((items) {
        items.removeWhere((item) => item.id == scan.id);
        if (items.length >= maxCount ||
            items.fold<int>(scan.bytes.length,
                    (size, item) => size + item.bytes.length) >
                maxBytes) {
          throw StateError(
              'Hàng đợi ảnh đã đầy. Gửi lại hoặc xóa ảnh cũ trước khi chụp thêm.');
        }
        items.add(scan);
      });

  Future<void> remove(int id) =>
      _update((items) => items.removeWhere((item) => item.id == id));

  Future<void> _update(void Function(List<PendingScan>) change) {
    final operation = _writes.then((_) async {
      final items = load();
      change(items);
      try {
        if (!await _prefs.setString(
            _key, jsonEncode(items.map((item) => item.toJson()).toList()))) {
          throw StateError('Không lưu được ảnh trên thiết bị.');
        }
      } catch (_) {
        // Preferences đổi cache trước khi ghi; đọc lại để lần thử sau không dùng bản ghi lỗi.
        try {
          await _prefs.reload();
        } catch (_) {}
        rethrow;
      }
    });
    // Một lần ghi lỗi không được chặn các lần thử lại sau.
    _writes =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}

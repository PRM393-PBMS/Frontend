import 'package:flutter/foundation.dart';

/// Máy chủ có liên lạc được không, suy ra từ chính các lần gọi API (không cần gói kiểm tra mạng):
/// lỗi kết nối thì ngoại tuyến, có phản hồi bất kỳ (kể cả lỗi 4xx/5xx) thì đã có mạng.
class ConnectivityStatus {
  ConnectivityStatus._();

  static final ValueNotifier<bool> offline = ValueNotifier(false);
}

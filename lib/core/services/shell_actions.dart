import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models/pbms_models.dart';

/// Việc app làm ngay khi khách bấm một thông báo (khay điện thoại, danh sách trong app, thông báo đang gửi xe).
sealed class ShellAction {
  const ShellAction();
}

/// Mở sơ đồ bãi, dẫn tới ô của lượt vừa vào.
class OpenLotMap extends ShellAction {
  final String? slotCode;
  final String? entryGateName;
  final String? parkingId;
  const OpenLotMap({this.slotCode, this.entryGateName, this.parkingId});
}

/// Mở màn nạp ví, điền sẵn số tiền (null: để khách tự nhập).
class OpenTopUp extends ShellAction {
  final int? amount;
  const OpenTopUp([this.amount]);
}

/// Mở màn gia hạn vé tháng.
class OpenRenew extends ShellAction {
  final String subscriptionId;
  const OpenRenew(this.subscriptionId);
}

/// Mở mã ra cổng / trả trước của lượt đang gửi.
class OpenExitPass extends ShellAction {
  const OpenExitPass();
}

/// Hành động theo thông báo; null khi chỉ cần đánh dấu đã đọc.
ShellAction? actionForNotification(String type, Map<String, dynamic> metadata) {
  String? str(String key) {
    final v = metadata[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  final action = str('action');
  final subscriptionId = str('subscriptionId');
  if (action == 'lot-map' || (type == 'parking' && str('slotCode') != null)) {
    return OpenLotMap(slotCode: str('slotCode'), entryGateName: str('entryGateName'), parkingId: str('parkingId'));
  }
  if (action == 'topup') {
    final amount = metadata['amount'];
    return OpenTopUp(amount is num && amount > 0 ? amount.ceil() : null);
  }
  // Nhắc sắp hết hạn, hoặc thông báo vé đã hết hạn (bản cũ chỉ có status) đều mở gia hạn.
  if (subscriptionId != null && (action == 'renew' || str('status') == 'Expired')) {
    return OpenRenew(subscriptionId);
  }
  if (action == 'exit-pass') return const OpenExitPass();
  return null;
}

ShellAction? actionFor(NotificationModel n) => actionForNotification(n.type, n.metadata);

/// Dữ liệu gắn vào thông báo trên khay điện thoại để biết bấm vào thì làm gì.
String encodeActionPayload(String type, Map<String, dynamic> metadata) =>
    jsonEncode({'type': type, 'metadata': metadata});

ShellAction? decodeActionPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final j = jsonDecode(payload);
    if (j is! Map) return null;
    final meta = j['metadata'];
    return actionForNotification('${j['type'] ?? ''}', meta is Map ? Map<String, dynamic>.from(meta) : const {});
  } catch (_) {
    return null;
  }
}

/// Hàng đợi một phần tử: nơi nhận (khay, thông báo trong app) đặt việc, khung chính thực hiện khi sẵn sàng.
class ShellActions {
  ShellActions._();

  static final ValueNotifier<ShellAction?> pending = ValueNotifier(null);

  static void request(ShellAction? action) {
    if (action != null) pending.value = action;
  }
}

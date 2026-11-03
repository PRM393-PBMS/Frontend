import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/pbms_models.dart';
import 'push_notification_service.dart';
import 'shell_actions.dart';

/// Thông báo cố định khi đang gửi xe (Android): đồng hồ thời gian đã gửi chạy trên khay và màn khoá,
/// có nút mở mã ra cổng. Tới cổng không phải mở app tìm vé.
/// iOS không có thông báo cố định nên bỏ qua.
class ParkingOngoingNotification {
  ParkingOngoingNotification._();

  static const _id = 7001;
  static const _channel = AndroidNotificationChannel(
    'pbms_parking',
    'Xe đang gửi',
    description: 'Thời gian gửi xe và mã ra cổng khi xe đang trong bãi',
    importance: Importance.low,
    showBadge: false,
  );

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Nội dung theo trạng thái lượt gửi; tách riêng để kiểm thử.
  static ({String title, String body, String action}) contentFor(ParkingSessionModel s) {
    final slot = s.slotCode == null ? '' : ' · Ô ${s.slotCode}';
    final pass = s.exitPass;
    return (
      title: 'Đang gửi xe ${s.licensePlateIn}$slot',
      body: pass != null
          ? 'Đã trả trước. Mã ra cổng ${pass.code}, camera đọc biển số là mở cổng.'
          : 'Trả trước trên app để ra cổng không phải dừng thanh toán.',
      action: pass != null ? 'Mã ra cổng' : 'Trả trước',
    );
  }

  /// Gọi mỗi lần tải lại lượt gửi: có xe trong bãi thì hiện/cập nhật, không có thì gỡ.
  static Future<void> sync(ParkingSessionModel? session) async {
    if (!_supported) return;
    try {
      final plugin = PushNotificationService.instance.plugin;
      if (session == null || !session.isActive) {
        // Gỡ cả khi app vừa mở lại (không nhớ đã hiện hay chưa).
        await plugin.cancel(_id);
        return;
      }
      // Không tự hỏi quyền: khách chưa cho phép thông báo thì thôi.
      if (!(await Permission.notification.isGranted)) return;
      await PushNotificationService.instance.init();
      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      final c = contentFor(session);
      await plugin.show(
        _id,
        c.title,
        c.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            // Đồng hồ do hệ điều hành chạy từ giờ vào bãi: đúng cả khi app đã tắt.
            when: session.entryTime.millisecondsSinceEpoch,
            usesChronometer: true,
            // Xem được trên màn khoá; mã ra cổng chỉ dùng được với đúng biển số xe.
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.status,
            color: const Color(0xFF087B8C),
            // Phòng khi app không mở lại để gỡ (xe đã ra): tự biến mất sau 1 ngày.
            timeoutAfter: const Duration(hours: 24).inMilliseconds,
            actions: [AndroidNotificationAction('exit-pass', c.action, showsUserInterface: true)],
          ),
        ),
        payload: encodeActionPayload('parking', const {'action': 'exit-pass'}),
      );
    } catch (_) {
      // Thông báo phụ: lỗi không ảnh hưởng màn hình chính.
    }
  }
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';

/// Trạng thái thông báo đẩy trên điện thoại.
enum PushState {
  /// Thiết bị / nền tảng không hỗ trợ (web, desktop).
  unsupported,

  /// Khách đang tắt trong app.
  off,

  /// Khách đã bật nhưng quyền thông báo của hệ điều hành đang bị tắt.
  blocked,

  /// Đang bật và hệ điều hành cho phép.
  on,
}

/// Kết quả khi khách bật thông báo.
enum PushEnableResult { enabled, denied, openSettings }

/// Thông báo đẩy trên điện thoại.
///
/// Xin quyền thật của hệ điều hành (Android 13+ POST_NOTIFICATIONS, iOS alert/badge/sound).
/// Khi bật, app kiểm tra thông báo mới của tài khoản mỗi phút và mỗi lần mở lại app,
/// rồi hiện lên khay thông báo của điện thoại.
class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _kEnabled = 'push_enabled';
  static const _kSeen = 'push_seen_ids';
  static const _pollEvery = Duration(minutes: 1);
  static const _channel = AndroidNotificationChannel(
    'pbms_updates',
    'Cập nhật gửi xe',
    description: 'Đặt chỗ, thanh toán, vé tháng và lượt gửi xe',
    importance: Importance.high,
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  final ValueNotifier<PushState> state = ValueNotifier(PushState.off);

  PbmsRepository? _repo;
  Timer? _timer;
  bool _ready = false;
  bool _polling = false;

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_pbms'),
      // Không tự hỏi quyền lúc khởi động: chỉ hỏi khi khách bật công tắc.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Gắn với tài khoản đang đăng nhập (khung chính của app).
  Future<void> attach(PbmsRepository repo) async {
    if (!_supported) {
      state.value = PushState.unsupported;
      return;
    }
    _repo = repo;
    await _init();
    await refresh();
    _poll();
  }

  /// Đăng xuất: ngừng kiểm tra, xoá thông báo đang hiện.
  Future<void> detach() async {
    _repo = null;
    _timer?.cancel();
    _timer = null;
    if (_ready) await _plugin.cancelAll();
  }

  Future<bool> _osGranted() async {
    if (Platform.isAndroid) return (await Permission.notification.status).isGranted;
    final perms = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    return perms?.isEnabled ?? false;
  }

  /// Đọc lại trạng thái (vd. khách vừa đổi quyền trong Cài đặt rồi quay lại app).
  Future<void> refresh() async {
    if (!_supported) {
      state.value = PushState.unsupported;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final wanted = prefs.getBool(_kEnabled) ?? false;
    final granted = await _osGranted();
    state.value = !wanted
        ? PushState.off
        : (granted ? PushState.on : PushState.blocked);
    _timer?.cancel();
    _timer = state.value == PushState.on && _repo != null
        ? Timer.periodic(_pollEvery, (_) => _poll())
        : null;
  }

  /// Bật: xin quyền hệ điều hành. Quyền đã bị chặn hẳn thì trả về [PushEnableResult.openSettings].
  Future<PushEnableResult> enable() async {
    if (!_supported) return PushEnableResult.denied;
    await _init();
    bool granted;
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) return PushEnableResult.openSettings;
      granted = status.isGranted;
    } else {
      // iOS chỉ hiện hộp thoại một lần; từ chối rồi thì phải vào Cài đặt.
      granted = await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
      if (!granted) return PushEnableResult.openSettings;
    }
    if (!granted) return PushEnableResult.denied;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    // Thông báo đã có từ trước không bắn lại, chỉ báo cái mới từ giờ.
    await _poll(announce: false);
    await refresh();
    return PushEnableResult.enabled;
  }

  /// Tắt trong app (quyền của hệ điều hành giữ nguyên, app chỉ ngừng gửi).
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, false);
    if (_ready) await _plugin.cancelAll();
    await refresh();
  }

  Future<void> openSettings() => openAppSettings();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _repo == null) return;
    refresh().then((_) => _poll());
  }

  /// Lấy thông báo của tài khoản, hiện những cái chưa đọc mà máy chưa báo.
  Future<void> _poll({bool announce = true}) async {
    final repo = _repo;
    if (repo == null || _polling) return;
    if (announce && state.value != PushState.on) return;
    _polling = true;
    try {
      final page = await repo.getNotifications();
      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getStringList(_kSeen) ?? const <String>[]).toSet();
      final fresh = page.items.where((n) => !n.isRead && !seen.contains(n.id)).toList();
      if (announce) await _show(fresh);
      final ids = [...fresh.map((n) => n.id), ...seen];
      await prefs.setStringList(_kSeen, ids.take(300).toList());
    } catch (_) {
      // Mạng / máy chủ lỗi: lần sau thử lại, không làm phiền khách.
    } finally {
      _polling = false;
    }
  }

  Future<void> _show(List<NotificationModel> items) async {
    if (items.isEmpty) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF087B8C),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    // Nhiều thông báo cùng lúc: gộp thành một để khay không bị ngập.
    if (items.length > 3) {
      await _plugin.show(
        0,
        'PBMS: ${items.length} thông báo mới',
        items.first.title,
        details,
      );
      return;
    }
    for (final n in items) {
      await _plugin.show(n.id.hashCode & 0x7fffffff, n.title, n.message, details);
    }
  }
}

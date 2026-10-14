import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j.str('id'),
        title: j.str('title'),
        message: j.str('message'),
        type: j.str('type', 'system'),
        isRead: j.boolean('isRead'),
        createdAt: j.date('createdAt'),
      );

  AppNotification markedRead() => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: true,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, isRead];
}

class NotificationFeed extends Equatable {
  final List<AppNotification> items;

  /// false khi backend chưa triển khai /api/Notification (404); khi đó UI ẩn chuông.
  final bool available;

  const NotificationFeed({required this.items, required this.available});

  int get unreadCount => items.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [items, available];
}

class NotificationRepository {
  final ApiClient _api;

  NotificationRepository(this._api);

  Future<NotificationFeed> mine() async {
    try {
      final res = await _api.get<dynamic>(ApiEndpoints.myNotifications);
      final j = res.result;
      final raw = j is Map<String, dynamic> ? j['items'] : j;
      final items = ApiClient.parseList(raw, AppNotification.fromJson)
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      return NotificationFeed(items: items, available: true);
    } on NotFoundException {
      return const NotificationFeed(items: [], available: false);
    }
  }

  Future<void> markRead(String id) =>
      _api.put<dynamic>(ApiEndpoints.readNotification(id));

  Future<void> markAllRead() =>
      _api.put<dynamic>(ApiEndpoints.readAllNotifications);

  Future<void> delete(String id) =>
      _api.delete<dynamic>(ApiEndpoints.notificationById(id));
}

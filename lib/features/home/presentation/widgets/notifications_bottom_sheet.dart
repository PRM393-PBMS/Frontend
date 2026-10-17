import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/error_text.dart';
import 'package:prm393_frontend/core/utils/date_formatter.dart';
import 'package:prm393_frontend/core/widgets/pbms_ui.dart';
import 'package:prm393_frontend/data/models/pbms_models.dart';
import 'package:prm393_frontend/data/pbms_repository.dart';

/// Danh sách thông báo của khách hàng (GET /api/Notification/my).
class NotificationsBottomSheet extends StatefulWidget {
  final VoidCallback onNotificationsUpdated;

  const NotificationsBottomSheet({
    super.key,
    required this.onNotificationsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onNotificationsUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationsBottomSheet(
        onNotificationsUpdated: onNotificationsUpdated,
      ),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  List<NotificationModel> _notifications = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLatest();
  }

  Future<void> _fetchLatest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _repo.getNotifications();
      if (!mounted) return;
      setState(() => _notifications = page.items);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.lightImpact();
    try {
      await _repo.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      widget.onNotificationsUpdated();
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _markItemAsRead(NotificationModel item) async {
    if (item.isRead) return;
    HapticFeedback.selectionClick();
    try {
      await _repo.markNotificationRead(item.id);
      if (!mounted) return;
      setState(() {
        _notifications = [
          for (final n in _notifications)
            n.id == item.id ? n.copyWith(isRead: true) : n,
        ];
      });
      widget.onNotificationsUpdated();
    } catch (e) {
      if (mounted) showPbmsSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _delete(NotificationModel item) async {
    final previous = _notifications;
    setState(() =>
        _notifications = _notifications.where((n) => n.id != item.id).toList());
    try {
      await _repo.deleteNotification(item.id);
      widget.onNotificationsUpdated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifications = previous);
      showPbmsSnack(context, errorText(e), error: true);
    }
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pay')) return Icons.payments_outlined;
    if (t.contains('reserv')) return Icons.calendar_month_outlined;
    if (t.contains('subscri')) return Icons.card_membership_outlined;
    if (t.contains('incident') || t.contains('warn') || t.contains('alert')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pay')) return PbmsTokens.ok;
    if (t.contains('incident') || t.contains('warn') || t.contains('alert')) {
      return PbmsTokens.warn;
    }
    return PbmsTokens.teal;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 16 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PbmsTokens.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông báo', style: PbmsText.title),
                    const SizedBox(height: 2),
                    Text(
                      unreadCount > 0
                          ? '$unreadCount thông báo chưa đọc'
                          : 'Bạn đã đọc hết thông báo',
                      style: PbmsText.caption.copyWith(
                        color:
                            unreadCount > 0 ? PbmsTokens.teal : PbmsTokens.muted,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    foregroundColor: PbmsTokens.teal,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Đọc tất cả'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: PbmsTokens.border),
          const SizedBox(height: 12),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return ListView(
        shrinkWrap: true,
        children: const [
          PbmsLoadingBox(height: 72),
          SizedBox(height: 8),
          PbmsLoadingBox(height: 72),
          SizedBox(height: 8),
          PbmsLoadingBox(height: 72),
        ],
      );
    }
    if (_error != null && _notifications.isEmpty) {
      return PbmsErrorView(
        title: 'Không tải được thông báo',
        message: _error!,
        onRetry: _fetchLatest,
      );
    }
    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: PbmsEmptyView(
          icon: Icons.notifications_off_outlined,
          title: 'Chưa có thông báo',
          message:
              'Xác nhận đặt chỗ, thanh toán và vé tháng sẽ được báo ở đây.',
        ),
      );
    }
    return RefreshIndicator(
      color: PbmsTokens.teal,
      onRefresh: _fetchLatest,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _delete(item),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: PbmsTokens.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: PbmsTokens.danger),
            ),
            child: _NotificationTile(
              item: item,
              icon: _iconForType(item.type),
              color: _colorForType(item.type),
              onTap: () => _markItemAsRead(item),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isRead ? Colors.white : PbmsTokens.tealTint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead ? PbmsTokens.divider : PbmsTokens.tealLine,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: PbmsText.bodyStrong.copyWith(
                        fontWeight:
                            item.isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(item.message, style: PbmsText.caption),
                    const SizedBox(height: 6),
                    Text(DateFormatter.relative(item.createdAt),
                        style: PbmsText.caption),
                  ],
                ),
              ),
              if (!item.isRead)
                Semantics(
                  label: 'Chưa đọc',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, left: 6),
                    decoration: const BoxDecoration(
                      color: PbmsTokens.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

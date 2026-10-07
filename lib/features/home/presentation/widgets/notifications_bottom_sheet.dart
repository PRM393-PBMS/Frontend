import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prm393_frontend/core/theme/app_colors.dart';
import 'package:prm393_frontend/core/theme/app_typography.dart';
import 'package:prm393_frontend/core/utils/responsive_utils.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/parking_repository.dart';

class NotificationsBottomSheet extends StatefulWidget {
  final List<NotificationModel> initialNotifications;
  final ParkingRepository repository;
  final VoidCallback onNotificationsUpdated;

  const NotificationsBottomSheet({
    super.key,
    required this.initialNotifications,
    required this.repository,
    required this.onNotificationsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required List<NotificationModel> notifications,
    required ParkingRepository repository,
    required VoidCallback onNotificationsUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationsBottomSheet(
        initialNotifications: notifications,
        repository: repository,
        onNotificationsUpdated: onNotificationsUpdated,
      ),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  late List<NotificationModel> _notifications;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.initialNotifications);
    _fetchLatest();
  }

  Future<void> _fetchLatest() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.repository.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.lightImpact();
    await widget.repository.markAllNotificationsRead();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    widget.onNotificationsUpdated();
  }

  Future<void> _markItemAsRead(NotificationModel item) async {
    if (item.isRead) return;
    HapticFeedback.selectionClick();
    await widget.repository.markNotificationRead(item.id);
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });
    widget.onNotificationsUpdated();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _iconForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('pay') || t.contains('thanh toan')) return Icons.payments_outlined;
    if (t.contains('reserve') || t.contains('dat cho')) return Icons.calendar_month_outlined;
    if (t.contains('warn') || t.contains('alert') || t.contains('su co')) return Icons.warning_amber_rounded;
    return Icons.notifications_none_rounded;
  }

  Color _colorForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('pay') || t.contains('thanh toan')) return AppColors.available;
    if (t.contains('reserve') || t.contains('dat cho')) return AppColors.primary;
    if (t.contains('warn') || t.contains('alert') || t.contains('su co')) return AppColors.maintenance;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: EdgeInsets.fromLTRB(
        context.space(20),
        context.space(16),
        context.space(20),
        context.space(24) + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.space(24))),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: context.space(40),
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: context.space(16)),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông báo PBMS',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        unreadCount > 0 ? '$unreadCount tin nhắn chưa đọc' : 'Đã đọc toàn bộ',
                        style: AppTypography.bodySmall.copyWith(
                          color: unreadCount > 0 ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text('Đọc tất cả', style: TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Notification List
          Expanded(
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bạn chưa có thông báo nào',
                              style: TextStyle(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final icon = _iconForType(item.type);
                          final color = _colorForType(item.type);

                          return InkWell(
                            onTap: () => _markItemAsRead(item),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? Colors.transparent
                                    : (isDark
                                        ? AppColors.cardDark
                                        : AppColors.primary.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.isRead
                                      ? (isDark ? AppColors.borderSubtleDark : const Color(0xFFF1F5F9))
                                      : (isDark ? AppColors.borderDark : const Color(0xFFBAE6FD)),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: AppTypography.bodyMedium.copyWith(
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.content,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTime(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

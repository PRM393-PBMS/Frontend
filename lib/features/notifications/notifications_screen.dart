import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/error_text.dart';
import '../../core/state/async_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/panels.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/pbms_models.dart';
import '../../data/pbms_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final PbmsRepository _repo = context.read<PbmsRepository>();
  late final _page = AsyncCubit(_repo.getNotifications);

  @override
  void dispose() {
    _page.close();
    super.dispose();
  }

  NotificationPage _withItems(List<NotificationModel> items) => NotificationPage(
        items: items,
        unreadCount: items.where((n) => !n.isRead).length,
      );

  Future<void> _markAll() async {
    try {
      await _repo.markAllNotificationsRead();
      _page.patch((pg) => _withItems([for (final n in pg.items) n.copyWith(isRead: true)]));
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    }
  }

  Future<void> _open(NotificationModel n) async {
    if (n.isRead) return;
    _page.patch((pg) => _withItems([for (final x in pg.items) x.id == n.id ? x.copyWith(isRead: true) : x]));
    try {
      await _repo.markNotificationRead(n.id);
    } catch (_) {
      _page.load();
    }
  }

  Future<void> _delete(NotificationModel n) async {
    _page.patch((pg) => _withItems(pg.items.where((x) => x.id != n.id).toList()));
    try {
      await _repo.deleteNotification(n.id);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
      _page.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AsyncCubit<NotificationPage>, AsyncState<NotificationPage>>(
      bloc: _page,
      builder: (context, st) {
        final unread = st.data?.unreadCount ?? 0;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông báo'),
            actions: [
              if (unread > 0)
                TextButton(onPressed: _markAll, child: const Text('Đọc tất cả')),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _page.load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                AsyncView(
                  state: st,
                  onRetry: _page.load,
                  isEmpty: (d) => d.items.isEmpty,
                  empty: const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Không có thông báo',
                    message: 'Nhắc giờ đặt chỗ, gia hạn vé và cập nhật sự cố sẽ hiện ở đây.',
                  ),
                  builder: (pg) => Column(
                    children: [
                      for (final n in pg.items) ...[
                        Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(n),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: context.palette.dangerSoft,
                              borderRadius: AppSpacing.roundedLg,
                            ),
                            child: Icon(Icons.delete_outline_rounded, color: context.palette.danger),
                          ),
                          child: _NotificationTile(item: n, onTap: () => _open(n)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  IconData get _icon => switch (item.type.toLowerCase()) {
        'parking' => Icons.local_parking_rounded,
        'subscription' => Icons.badge_outlined,
        'reservation' => Icons.event_available_outlined,
        'incident' => Icons.report_gmailerrorred_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return AppPanel(
      onTap: onTap,
      color: item.isRead ? p.surface : p.accentSoft,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 22, color: item.isRead ? p.textMuted : p.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: t.titleSmall?.copyWith(fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(item.message, style: t.bodyMedium?.copyWith(color: p.textSecondary)),
                const SizedBox(height: 6),
                Text(DateFormatter.relative(item.createdAt), style: t.labelSmall),
              ],
            ),
          ),
          if (!item.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

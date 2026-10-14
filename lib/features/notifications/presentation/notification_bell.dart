import '../../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/state/data_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_text.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/state_views.dart';
import '../data/notification_repository.dart';

/// Chuông thông báo có số chưa đọc. Ẩn hoàn toàn nếu backend chưa có /api/Notification.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final DataCubit<NotificationFeed> _cubit =
      DataCubit(context.read<NotificationRepository>().mine)..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<DataCubit<NotificationFeed>,
        LoadState<NotificationFeed>>(
      bloc: _cubit,
      builder: (context, state) {
        final feed = state.data;
        if (feed != null && !feed.available) return const SizedBox.shrink();
        final unread = feed?.unreadCount ?? 0;
        return IconButton(
          tooltip: context.l10n.notifTooltip,
          onPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _NotificationSheet(cubit: _cubit),
            );
            _cubit.refresh();
          },
          icon: Badge(
            isLabelVisible: unread > 0,
            backgroundColor: p.danger,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: Icon(Icons.notifications_none_rounded, color: p.textPrimary),
          ),
        );
      },
    );
  }
}

class _NotificationSheet extends StatefulWidget {
  final DataCubit<NotificationFeed> cubit;

  const _NotificationSheet({required this.cubit});

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  final Set<String> _hidden = {};
  final Set<String> _read = {};
  bool _busy = false;

  NotificationRepository get _repo => context.read<NotificationRepository>();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showAppSnack(context, errorText(e, context.l10n), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) =>
          BlocBuilder<DataCubit<NotificationFeed>, LoadState<NotificationFeed>>(
        bloc: widget.cubit,
        builder: (context, state) {
          final items = (state.data?.items ?? const <AppNotification>[])
              .where((n) => !_hidden.contains(n.id))
              .map((n) => _read.contains(n.id) ? n.markedRead() : n)
              .toList();
          final hasUnread = items.any((n) => !n.isRead);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, 0, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.l10n.notifTitle,
                          style: AppTypography.title
                              .copyWith(color: p.textPrimary)),
                    ),
                    if (hasUnread)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                await _run(() async {
                                  await _repo.markAllRead();
                                  setState(() =>
                                      _read.addAll(items.map((n) => n.id)));
                                });
                                if (mounted) setState(() => _busy = false);
                              },
                        child: Text(context.l10n.notifMarkAll),
                      ),
                  ],
                ),
              ),
              Divider(color: p.border),
              Expanded(
                child: state.data == null && state.isFailure
                    ? ErrorState(
                        message: errorText(state.error, context.l10n),
                        onRetry: widget.cubit.load)
                    : state.data == null
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.page),
                            child: SkeletonListShim(),
                          )
                        : items.isEmpty
                            ? EmptyState(
                                icon: Icons.notifications_off_outlined,
                                title: context.l10n.notifEmptyTitle,
                                message: context.l10n.notifEmptyMessage,
                              )
                            : ListView.separated(
                                controller: scroll,
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xxl),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                    color: p.border, indent: AppSpacing.page),
                                itemBuilder: (context, i) {
                                  final n = items[i];
                                  return Dismissible(
                                    key: ValueKey(n.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: p.dangerSoft,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                          right: AppSpacing.page),
                                      child: Icon(Icons.delete_outline_rounded,
                                          color: p.danger),
                                    ),
                                    onDismissed: (_) {
                                      setState(() => _hidden.add(n.id));
                                      _run(() => _repo.delete(n.id));
                                    },
                                    child: InkWell(
                                      onTap: n.isRead
                                          ? null
                                          : () {
                                              setState(() => _read.add(n.id));
                                              _run(() => _repo.markRead(n.id));
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.page,
                                            vertical: AppSpacing.md),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: n.isRead
                                                      ? Colors.transparent
                                                      : p.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(n.title,
                                                      style: AppTypography.label
                                                          .copyWith(
                                                        color: p.textPrimary,
                                                        fontWeight: n.isRead
                                                            ? FontWeight.w500
                                                            : FontWeight.w600,
                                                      )),
                                                  const SizedBox(height: 4),
                                                  Text(n.message,
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                              color: p
                                                                  .textSecondary)),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                      DateFormatter.timeAgo(
                                                          context.l10n,
                                                          n.createdAt),
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                              color:
                                                                  p.textMuted)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Skeleton gọn cho sheet (không cuộn).
class SkeletonListShim extends StatelessWidget {
  const SkeletonListShim({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          _Row(),
          SizedBox(height: AppSpacing.lg),
          _Row(),
          SizedBox(height: AppSpacing.lg),
          _Row(),
        ],
      );
}

class _Row extends StatelessWidget {
  const _Row();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 64,
      decoration: BoxDecoration(
          color: p.surfaceMuted, borderRadius: AppSpacing.control),
    );
  }
}

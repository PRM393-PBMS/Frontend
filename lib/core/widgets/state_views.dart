import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Trạng thái lỗi khi chưa có dữ liệu nào để hiển thị.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Không tải được dữ liệu',
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line),
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: p.danger, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: t.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: t.bodyMedium?.copyWith(color: p.textSecondary)),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dải cảnh báo mảnh khi làm mới thất bại nhưng vẫn còn dữ liệu cũ.
class StaleBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StaleBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: p.warnSoft,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_rounded, size: 18, color: p.warn),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Đang hiển thị dữ liệu cũ. $message',
              style: t.bodySmall?.copyWith(color: p.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// Trạng thái rỗng có hướng dẫn hành động tiếp theo.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        border: Border.all(color: p.line),
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: p.textSecondary, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: t.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: t.bodyMedium?.copyWith(color: p.textSecondary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

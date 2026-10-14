import '../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/data_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/error_text.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// Giới hạn bề rộng nội dung trên màn hình rộng (tablet / web).
class ContentWidth extends StatelessWidget {
  final Widget child;

  const ContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Tiêu đề nhóm nội dung, có hành động phụ bên phải.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppTypography.titleSmall.copyWith(color: p.textPrimary)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Một dòng nhãn / giá trị trong phần chi tiết.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final TextStyle? valueStyle;

  const KeyValueRow(this.label, this.value,
      {super.key, this.emphasize = false, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style:
                    AppTypography.bodySmall.copyWith(color: p.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ??
                  (emphasize
                      ? AppTypography.titleSmall.copyWith(color: p.textPrimary)
                      : AppTypography.label.copyWith(color: p.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng hai đầu (vd. biển số bên trái, huy hiệu bên phải) tự co lại trên màn hẹp.
class EdgeRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;

  const EdgeRow({super.key, required this.leading, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: leading),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: trailing),
        ),
      ],
    );
  }
}

/// Biển số hiển thị bằng font mono trong khung viền.
class PlateTag extends StatelessWidget {
  final String plate;
  final bool large;

  const PlateTag(this.plate, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppSpacing.badge,
        border:
            Border.all(color: p.textPrimary.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Text(
        plate,
        style: AppTypography.mono.copyWith(
          color: p.textPrimary,
          fontSize: large ? 18 : 13,
        ),
      ),
    );
  }
}

/// Hiển thị [LoadState]: skeleton lần đầu, lỗi có thử lại, rỗng, hoặc dữ liệu.
/// Kèm kéo-để-làm-mới.
class LoadStateView<T> extends StatelessWidget {
  final DataCubit<T> cubit;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final EdgeInsetsGeometry padding;
  final List<Widget> header;

  const LoadStateView({
    super.key,
    required this.cubit,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.sm, AppSpacing.page, 120),
    this.header = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCubit<T>, LoadState<T>>(
      bloc: cubit,
      builder: (context, state) {
        Widget body;
        final data = state.data;
        if (data == null &&
            (state.isLoading || state.status == LoadStatus.initial)) {
          body = loading ?? const SkeletonList();
        } else if (data == null && state.isFailure) {
          body = ErrorState(
              message: errorText(state.error, context.l10n),
              onRetry: cubit.load);
        } else if (data != null && isEmpty != null && isEmpty!(data)) {
          body = empty ?? const SizedBox.shrink();
        } else if (data != null) {
          body = builder(context, data);
        } else {
          body = const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...header,
                    if (state.isFailure && data != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child:
                            InlineMessage(errorText(state.error, context.l10n)),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                          key: ValueKey(state.status == LoadStatus.success),
                          child: body),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Snackbar ngắn cho phản hồi tạm thời.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: error ? p.danger : p.success,
              size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    ));
}

/// Hộp thoại xác nhận hành động. Trả về true nếu người dùng đồng ý.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final p = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.commonBack,
              style: TextStyle(color: p.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: TextStyle(color: destructive ? p.danger : p.accent)),
        ),
      ],
    ),
  );
  return result ?? false;
}

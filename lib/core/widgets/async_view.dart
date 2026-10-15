import 'package:flutter/material.dart';

import '../state/async_cubit.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// Hiển thị đúng một trong: skeleton, lỗi, rỗng, dữ liệu.
class AsyncView<T> extends StatelessWidget {
  final AsyncState<T> state;
  final Widget Function(T data) builder;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;
  final String errorTitle;

  const AsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.loading,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.errorTitle = 'Không tải được dữ liệu',
  });

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    Widget child;
    String branch;
    if (data == null) {
      branch = state.status == AsyncStatus.error ? 'error' : 'loading';
      child = state.status == AsyncStatus.error
          ? ErrorState(
              title: errorTitle,
              message: state.error ?? '',
              onRetry: onRetry,
            )
          : (loading ?? const SkeletonList());
    } else if (isEmpty != null && isEmpty!(data) && empty != null) {
      branch = 'empty';
      child = empty!;
    } else {
      branch = 'data';
      child = builder(data);
    }

    final showStale = data != null && state.status == AsyncStatus.error;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey(branch),
        child: showStale
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaleBanner(message: state.error ?? '', onRetry: onRetry),
                  child,
                ],
              )
            : child,
      ),
    );
  }
}

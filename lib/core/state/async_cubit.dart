import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/error_text.dart';

enum AsyncStatus { loading, ready, error }

class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final String? error;

  const AsyncState._(this.status, this.data, this.error);

  const AsyncState.loading([T? previous]) : this._(AsyncStatus.loading, previous, null);
  const AsyncState.ready(T value) : this._(AsyncStatus.ready, value, null);
  const AsyncState.error(String message, [T? previous])
      : this._(AsyncStatus.error, previous, message);

  bool get hasData => data != null;
  bool get isLoading => status == AsyncStatus.loading;
  bool get isRefreshing => isLoading && hasData;
}

/// Cubit nạp dữ liệu từ một hàm gọi API, giữ dữ liệu cũ khi làm mới.
class AsyncCubit<T> extends Cubit<AsyncState<T>> {
  final Future<T> Function() _loader;
  int _ticket = 0;

  AsyncCubit(this._loader, {bool autoload = true}) : super(const AsyncState.loading()) {
    if (autoload) load();
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    emit(AsyncState.loading(state.data));
    try {
      final value = await _loader();
      if (isClosed || ticket != _ticket) return;
      emit(AsyncState.ready(value));
    } catch (e) {
      if (isClosed || ticket != _ticket) return;
      emit(AsyncState.error(errorText(e), state.data));
    }
  }

  /// Cập nhật cục bộ sau một thao tác thành công (vd. đánh dấu đã đọc).
  void patch(T Function(T current) update) {
    final current = state.data;
    if (current == null || isClosed) return;
    emit(AsyncState.ready(update(current)));
  }
}

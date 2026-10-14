import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LoadStatus { initial, loading, success, failure }

/// Trạng thái tải dữ liệu chung: giữ dữ liệu cũ khi làm mới để không nháy skeleton.
class LoadState<T> extends Equatable {
  final LoadStatus status;
  final T? data;

  /// Lỗi gốc; hiển thị qua errorText(error, l10n) để dịch theo ngôn ngữ.
  final Object? error;

  const LoadState({this.status = LoadStatus.initial, this.data, this.error});

  bool get isLoading => status == LoadStatus.loading;
  bool get hasData => data != null;
  bool get isFailure => status == LoadStatus.failure;

  @override
  List<Object?> get props => [status, data, error];
}

/// Cubit tải một tài nguyên bằng [loader]; `load()` lần đầu, `refresh()` khi kéo làm mới.
class DataCubit<T> extends Cubit<LoadState<T>> {
  final Future<T> Function() loader;

  DataCubit(this.loader) : super(LoadState<T>());

  Future<void> load() async {
    emit(LoadState<T>(status: LoadStatus.loading, data: state.data));
    try {
      final data = await loader();
      if (isClosed) return;
      emit(LoadState<T>(status: LoadStatus.success, data: data));
    } catch (e) {
      if (isClosed) return;
      emit(
          LoadState<T>(status: LoadStatus.failure, data: state.data, error: e));
    }
  }

  Future<void> refresh() => load();
}

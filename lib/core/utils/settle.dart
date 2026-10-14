/// Kết quả của một Future đã "chốt": hoặc có giá trị, hoặc có lỗi.
class Settled<T> {
  final T? value;
  final Object? error;

  const Settled._(this.value, this.error);

  bool get isOk => error == null;

  /// Trả về giá trị hoặc ném lại lỗi gốc.
  T get require {
    final e = error;
    if (e != null) throw e;
    return value as T;
  }
}

/// Gắn bộ xử lý lỗi ngay lập tức để có thể chạy song song nhiều request
/// mà không sinh "Unhandled Exception" khi một request lỗi trước lúc được await.
Future<Settled<T>> settle<T>(Future<T> future) => future.then(
      (v) => Settled<T>._(v, null),
      onError: (Object e) => Settled<T>._(null, e),
    );

import 'package:flutter/widgets.dart';

/// Chỉ số tab của khung chính.
class AppTab {
  AppTab._();
  static const home = 0;
  static const reserve = 1;
  static const sessions = 2;
  static const pass = 3;
  static const account = 4;
}

/// Cho phép màn hình con chuyển tab và báo dữ liệu đã thay đổi
/// (vd. vừa đặt chỗ xong → Tổng quan tải lại).
class ShellScope extends InheritedWidget {
  final ValueChanged<int> goTab;
  final ValueNotifier<int> revision;

  const ShellScope({
    super.key,
    required this.goTab,
    required this.revision,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  /// Báo các tab khác tải lại dữ liệu.
  static void dataChanged(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ShellScope>();
    if (scope != null) scope.revision.value++;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      goTab != oldWidget.goTab || revision != oldWidget.revision;
}

/// Mixin: tải lại khi [ShellScope.revision] tăng.
mixin ReloadOnDataChange<T extends StatefulWidget> on State<T> {
  ValueNotifier<int>? _revision;

  void reloadAll();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ShellScope.maybeOf(context)?.revision;
    if (next != _revision) {
      _revision?.removeListener(reloadAll);
      _revision = next?..addListener(reloadAll);
    }
  }

  @override
  void dispose() {
    _revision?.removeListener(reloadAll);
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'core/services/app_lock_controller.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/blocs/auth_state.dart';
import 'features/auth/presentation/screens/app_lock_screen.dart';

class ParkingApp extends StatefulWidget {
  final bool showOnboarding;
  
  const ParkingApp({super.key, required this.showOnboarding});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> {
  late final GoRouter _router;
  late final AppLockController _lock = AppLockController.instance;

  /// Chưa từng thấy trạng thái đăng xuất trong lần chạy này → phiên được khôi phục.
  bool _sawSignedOut = false;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _router = AppRouter.createRouter(authBloc, widget.showOnboarding);
    _syncLock(authBloc.state);
  }

  void _syncLock(AuthState state) {
    switch (state.status) {
      case AuthStatus.authenticated:
        _lock.onSignedInChanged(true, restoredSession: !_sawSignedOut);
      case AuthStatus.unauthenticated:
      case AuthStatus.failure:
        _sawSignedOut = true;
        _lock.onSignedInChanged(false);
      case AuthStatus.initial:
      case AuthStatus.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          title: AppConfig.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
          builder: (context, child) => BlocListener<AuthBloc, AuthState>(
            listenWhen: (a, b) => a.status != b.status,
            listener: (_, state) => _syncLock(state),
            child: ListenableBuilder(
              listenable: _lock,
              builder: (context, _) => Stack(
                children: [
                  // Ẩn nội dung khỏi trình đọc màn hình khi đang khoá.
                  ExcludeSemantics(
                    excluding: _lock.isLocked,
                    child: child ?? const SizedBox.shrink(),
                  ),
                  if (_lock.isLocked)
                    Positioned.fill(child: AppLockScreen(controller: _lock)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

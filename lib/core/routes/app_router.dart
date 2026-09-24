import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'route_names.dart';

/// Lắng nghe Stream của BLoC để làm mới Route của GoRouter khi đổi AuthState
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteNames.splashPath,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final currentPath = state.uri.path;

        final isSplash = currentPath == RouteNames.splashPath;
        final isLoggingIn = currentPath == RouteNames.loginPath;

        // Nếu BLoC đang ở trạng thái ban đầu (đang kiểm tra token)
        if (authState.status == AuthStatus.initial) {
          return RouteNames.splashPath;
        }

        // Nếu chưa đăng nhập
        if (authState.status == AuthStatus.unauthenticated ||
            authState.status == AuthStatus.failure) {
          return isLoggingIn ? null : RouteNames.loginPath;
        }

        // Nếu đã đăng nhập thành công
        if (authState.status == AuthStatus.authenticated) {
          if (isLoggingIn || isSplash) {
            return RouteNames.homePath;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.splashPath,
          name: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.loginPath,
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.homePath,
          name: RouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );
  }
}

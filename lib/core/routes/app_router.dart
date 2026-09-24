import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/auth/presentation/blocs/auth_state.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'route_names.dart';

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
        final isAuthFlow = currentPath == RouteNames.loginPath ||
            currentPath == RouteNames.registerPath ||
            currentPath == RouteNames.verifyOtpPath ||
            currentPath == RouteNames.forgotPasswordPath;

        if (authState.status == AuthStatus.initial) {
          return RouteNames.splashPath;
        }

        if (authState.status == AuthStatus.unauthenticated ||
            authState.status == AuthStatus.failure) {
          return isAuthFlow ? null : RouteNames.loginPath;
        }

        if (authState.status == AuthStatus.authenticated) {
          if (isAuthFlow || isSplash) {
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
          path: RouteNames.registerPath,
          name: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteNames.verifyOtpPath,
          name: RouteNames.verifyOtp,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return VerifyOtpScreen(
              email: extra['email'] as String? ?? '',
              isResetPassword: extra['isResetPassword'] as bool? ?? false,
              newPassword: extra['newPassword'] as String?,
              confirmPassword: extra['confirmPassword'] as String?,
            );
          },
        ),
        GoRoute(
          path: RouteNames.forgotPasswordPath,
          name: RouteNames.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
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

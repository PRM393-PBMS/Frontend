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
import '../../features/availability/presentation/availability_screen.dart';
import '../../features/home/presentation/customer_home_screen.dart';
import '../../features/incidents/presentation/create_incident_screen.dart';
import '../../features/incidents/presentation/incident_detail_screen.dart';
import '../../features/incidents/presentation/incidents_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/reservations/presentation/create_reservation_screen.dart';
import '../../features/reservations/presentation/reservation_detail_screen.dart';
import '../../features/reservations/presentation/reservations_screen.dart';
import '../../features/sessions/data/session_repository.dart';
import '../../features/sessions/presentation/session_detail_screen.dart';
import '../../features/sessions/presentation/session_history_screen.dart';
import '../../features/shell/customer_shell.dart';
import '../../features/shell/misc_screens.dart';
import '../../features/shell/staff_shell.dart';
import '../../features/staff/presentation/check_in_screen.dart';
import '../../features/staff/presentation/check_out_screen.dart';
import '../../features/staff/presentation/staff_incidents_screen.dart';
import '../../features/staff/presentation/staff_session_detail_screen.dart';
import '../../features/staff/presentation/staff_sessions_screen.dart';
import '../../features/subscriptions/presentation/pass_detail_screen.dart';
import '../../features/subscriptions/presentation/passes_screen.dart';
import '../../features/subscriptions/presentation/plate_requests_screen.dart';
import '../../features/subscriptions/presentation/register_pass_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import 'route_names.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  static const _authFlow = {
    RouteNames.login,
    RouteNames.register,
    RouteNames.verifyOtp,
    RouteNames.forgotPassword,
    RouteNames.onboarding,
  };

  static GoRouter createRouter(AuthBloc authBloc, bool showOnboarding) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: RouteNames.splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      errorBuilder: (context, state) => const NotFoundScreen(),
      redirect: (context, state) {
        final auth = authBloc.state;
        final path = state.uri.path;
        final isSplash = path == RouteNames.splash;
        final inAuthFlow = _authFlow.contains(path);

        if (auth.status == AuthStatus.initial) {
          return isSplash ? null : RouteNames.splash;
        }
        // Đang gửi form (đăng nhập, OTP...) thì giữ nguyên màn hình hiện tại.
        if (auth.status == AuthStatus.loading) return null;

        final user = auth.user;
        if (!auth.isAuthenticated || user == null) {
          if (isSplash) {
            return showOnboarding ? RouteNames.onboarding : RouteNames.login;
          }
          return inAuthFlow ? null : RouteNames.login;
        }

        if (!user.isSupported) {
          return path == RouteNames.unsupportedRole
              ? null
              : RouteNames.unsupportedRole;
        }

        final staffArea = path.startsWith('/staff');
        if (user.isStaff) {
          if (isSplash || inAuthFlow || !staffArea) {
            return RouteNames.staffCheckIn;
          }
          return null;
        }

        if (isSplash ||
            inAuthFlow ||
            staffArea ||
            path == RouteNames.unsupportedRole) {
          return RouteNames.home;
        }
        return null;
      },
      routes: [
        GoRoute(
            path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(
            path: RouteNames.onboarding,
            builder: (_, __) => const OnboardingScreen()),
        GoRoute(
            path: RouteNames.login, builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: RouteNames.register,
            builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: RouteNames.verifyOtp,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            return VerifyOtpScreen(
              email: extra['email'] as String? ?? '',
              isResetPassword: extra['isResetPassword'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
            path: RouteNames.forgotPassword,
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
            path: RouteNames.unsupportedRole,
            builder: (_, __) => const UnsupportedRoleScreen()),

        // ---------------- Khách hàng ----------------
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => CustomerShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: RouteNames.home,
                  builder: (_, __) => const CustomerHomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (_, __) => const SessionHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => SessionDetailScreen(
                      sessionId: state.pathParameters['id']!,
                      initial: state.extra is ParkingSession
                          ? state.extra as ParkingSession
                          : null,
                    ),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.passes,
                builder: (_, __) => const PassesScreen(),
                routes: [
                  GoRoute(
                    path: 'register',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => RegisterPassScreen(
                        initialPlate: state.uri.queryParameters['plate']),
                  ),
                  GoRoute(
                    path: 'plate-requests',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const PlateRequestsScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        PassDetailScreen(passId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.account,
                builder: (_, __) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'password',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'wallet',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const WalletScreen(),
                  ),
                ],
              ),
            ]),
          ],
        ),
        GoRoute(
          path: RouteNames.availability,
          builder: (_, __) => const AvailabilityScreen(),
        ),
        GoRoute(
          path: RouteNames.reservations,
          builder: (_, __) => const ReservationsScreen(),
          routes: [
            GoRoute(
                path: 'new',
                builder: (_, __) => const CreateReservationScreen()),
            GoRoute(
              path: ':id',
              builder: (_, state) => ReservationDetailScreen(
                  reservationId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: RouteNames.incidents,
          builder: (_, __) => const IncidentsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, state) => CreateIncidentScreen(
                  sessionId: state.uri.queryParameters['sessionId']),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  IncidentDetailScreen(incidentId: state.pathParameters['id']!),
            ),
          ],
        ),

        // ---------------- Nhân viên ----------------
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => StaffShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: RouteNames.staffCheckIn,
                  builder: (_, __) => const CheckInScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: RouteNames.staffCheckOut,
                  builder: (_, __) => const CheckOutScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.staffSessions,
                builder: (_, __) => const StaffSessionsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => StaffSessionDetailScreen(
                        sessionId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.staffIncidents,
                builder: (_, __) => const StaffIncidentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => IncidentDetailScreen(
                      incidentId: state.pathParameters['id']!,
                      staffMode: true,
                    ),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: RouteNames.staffAccount,
                builder: (_, __) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'password',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ]),
          ],
        ),
        GoRoute(
          path: RouteNames.staffAvailability,
          builder: (_, __) => const AvailabilityScreen(),
        ),
      ],
    );
  }
}

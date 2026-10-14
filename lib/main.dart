import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/l10n/locale_controller.dart';
import 'core/network/api_client.dart';
import 'core/storage/preferences_helper.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/blocs/auth_event.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/incidents/data/incident_repository.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/reservations/data/reservation_repository.dart';
import 'features/sessions/data/session_repository.dart';
import 'features/subscriptions/data/subscription_repository.dart';
import 'features/wallet/data/wallet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('vi'),
    initializeDateFormatting('en'),
    initializeDateFormatting('ja'),
  ]);
  await ThemeController.instance.restore();
  await LocaleController.instance.restore();
  final showOnboarding = await PreferencesHelper.shouldShowOnboarding();

  final storageService = SecureStorageService();
  late final AuthBloc authBloc;

  final apiClient = ApiClient(
    storageService: storageService,
    // Refresh token thất bại: phát sự kiện đăng xuất để router đưa về màn đăng nhập.
    onSessionExpired: () => authBloc.add(AuthLogoutRequested()),
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient: apiClient),
    storageService: storageService,
  );

  authBloc = AuthBloc(authRepository: authRepository)
    ..add(AuthCheckRequested());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageService>.value(value: storageService),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider(create: (_) => CatalogRepository(apiClient)),
        RepositoryProvider(create: (_) => ReservationRepository(apiClient)),
        RepositoryProvider(create: (_) => SessionRepository(apiClient)),
        RepositoryProvider(create: (_) => SubscriptionRepository(apiClient)),
        RepositoryProvider(create: (_) => IncidentRepository(apiClient)),
        RepositoryProvider(create: (_) => NotificationRepository(apiClient)),
        RepositoryProvider(create: (_) => ProfileRepository(apiClient)),
        RepositoryProvider(create: (_) => WalletRepository(apiClient)),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: ParkingApp(showOnboarding: showOnboarding),
      ),
    ),
  );
}

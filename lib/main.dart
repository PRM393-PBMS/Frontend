import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/preferences_helper.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/theme_controller.dart';
import 'data/pbms_repository.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/blocs/auth_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('vi'),
    ThemeController.instance.load(),
  ]);
  final showOnboarding = await PreferencesHelper.shouldShowOnboarding();

  final storageService = SecureStorageService();
  late final AuthBloc authBloc;

  final apiClient = ApiClient(
    storageService: storageService,
    // Refresh token thất bại → đăng xuất để quay về màn đăng nhập.
    onSessionExpired: () => authBloc.add(AuthLogoutRequested()),
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient: apiClient),
    storageService: storageService,
  );
  final pbmsRepository = PbmsRepository(apiClient: apiClient);

  authBloc = AuthBloc(authRepository: authRepository)..add(AuthCheckRequested());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageService>.value(value: storageService),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PbmsRepository>.value(value: pbmsRepository),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: ParkingApp(showOnboarding: showOnboarding),
      ),
    ),
  );
}

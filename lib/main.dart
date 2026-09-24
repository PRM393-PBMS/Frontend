import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/blocs/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Local Services & Network Core
  final storageService = SecureStorageService();

  late final AuthBloc authBloc;

  final apiClient = ApiClient(
    storageService: storageService,
    onSessionExpired: () {
      // Khi refresh token thất bại, tự động phát event đăng xuất
      authBloc.add(AuthLogoutRequested());
    },
  );

  // 2. Data Sources & Repositories
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    storageService: storageService,
  );

  // 3. Khởi tạo Global BLoC
  authBloc = AuthBloc(authRepository: authRepository)..add(AuthCheckRequested());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageService>.value(value: storageService),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const ParkingApp(),
      ),
    ),
  );
}

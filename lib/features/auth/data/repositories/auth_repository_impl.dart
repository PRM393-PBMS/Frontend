import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/error/failure.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_dto.dart';
import '../models/login_request_dto.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        LoginRequestDto(email: email, password: password),
      );

      final data = response.result;
      if (data == null) {
        throw const ServerException(message: 'Không nhận được dữ liệu phiên đăng nhập.');
      }

      await _storageService.saveAccessToken(data.accessToken);
      await _storageService.saveRefreshToken(data.refreshToken);
      await _storageService.saveUserData(jsonEncode(data.user.toJson()));

      return data.user;
    } on AppException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final isAuth = await isAuthenticated();
      if (!isAuth) return null;

      final cachedJson = await _storageService.getUserData();
      UserModel? cachedUser;
      if (cachedJson != null) {
        cachedUser = UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      }

      try {
        final profileResponse = await _remoteDataSource.getProfile();
        if (profileResponse.result != null) {
          final freshUser = profileResponse.result!;
          await _storageService.saveUserData(jsonEncode(freshUser.toJson()));
          return freshUser;
        }
      } catch (_) {
        return cachedUser;
      }

      return cachedUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken);
      }
    } catch (_) {
      // Bỏ qua lỗi logout phía server
    } finally {
      await _storageService.clearAuthData();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final isExpired = JwtDecoder.isExpired(token);
      if (!isExpired) return true;

      final refreshToken = await _storageService.getRefreshToken();
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendRegisterOtp({
    required String userName,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _remoteDataSource.sendRegisterOtp(
        RegisterRequestDto(
          userName: userName,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
    } on AppException catch (e) {
      throw ValidationFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _remoteDataSource.verifyRegisterOtp(
        VerifyRegisterOtpDto(email: email, otp: otp),
      );
    } on AppException catch (e) {
      throw ValidationFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> requestResetPassword({required String email}) async {
    try {
      await _remoteDataSource.requestResetPassword(
        RequestResetPasswordDto(email: email),
      );
    } on AppException catch (e) {
      throw ValidationFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> verifyResetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _remoteDataSource.verifyResetPassword(
        VerifyResetPasswordDto(
          email: email,
          otp: otp,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
    } on AppException catch (e) {
      throw ValidationFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}

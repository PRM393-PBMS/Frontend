import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:prm393_frontend/core/error/app_exception.dart';
import 'package:prm393_frontend/core/error/failure.dart';
import 'package:prm393_frontend/core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
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

      // Lưu trữ an toàn Token và Thông tin cá nhân vào Keychain/EncryptedSharedPreferences
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

      // Đọc trước từ local cache để hiển thị tức thì
      final cachedJson = await _storageService.getUserData();
      UserModel? cachedUser;
      if (cachedJson != null) {
        cachedUser = UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      }

      // Gọi API /api/profile để cập nhật dữ liệu mới nhất
      try {
        final profileResponse = await _remoteDataSource.getProfile();
        if (profileResponse.result != null) {
          final freshUser = profileResponse.result!;
          await _storageService.saveUserData(jsonEncode(freshUser.toJson()));
          return freshUser;
        }
      } catch (_) {
        // Nếu offline, fallback dùng cached user
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
      // Dù API logout backend có lỗi vẫn tiến hành xóa local storage phía client
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

      // Nếu accessToken hết hạn, kiểm tra xem còn refreshToken không
      final refreshToken = await _storageService.getRefreshToken();
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

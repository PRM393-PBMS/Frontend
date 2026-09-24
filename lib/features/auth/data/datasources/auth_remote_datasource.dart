import 'package:prm393_frontend/core/config/api_endpoints.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request_dto.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestDto dto);
  Future<ApiResponse<UserModel>> getProfile();
  Future<ApiResponse<void>> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestDto dto) async {
    return await _apiClient.post<AuthTokensModel>(
      ApiEndpoints.login,
      data: dto.toJson(),
      fromJsonT: (json) => AuthTokensModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<UserModel>> getProfile() async {
    return await _apiClient.get<UserModel>(
      ApiEndpoints.profile,
      fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<void>> logout(String refreshToken) async {
    return await _apiClient.post<void>(
      ApiEndpoints.logout,
      data: {'refreshTokenKey': refreshToken},
    );
  }
}

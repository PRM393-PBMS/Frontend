import 'package:prm393_frontend/core/config/api_endpoints.dart';
import 'package:prm393_frontend/core/network/api_client.dart';
import 'package:prm393_frontend/core/network/api_response.dart';
import '../models/auth_dto.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request_dto.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestDto dto);
  Future<ApiResponse<UserModel>> getProfile();
  Future<ApiResponse<void>> logout(String refreshToken);

  // Đăng ký & OTP
  Future<ApiResponse<void>> sendRegisterOtp(RegisterRequestDto dto);
  Future<ApiResponse<Map<String, dynamic>>> verifyRegisterOtp(VerifyRegisterOtpDto dto);

  // Quên mật khẩu & Reset
  Future<ApiResponse<void>> requestResetPassword(RequestResetPasswordDto dto);
  Future<ApiResponse<void>> verifyResetPassword(VerifyResetPasswordDto dto);
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

  @override
  Future<ApiResponse<void>> sendRegisterOtp(RegisterRequestDto dto) async {
    return await _apiClient.post<void>(
      ApiEndpoints.sendRegisterOtp,
      data: dto.toJson(),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> verifyRegisterOtp(
    VerifyRegisterOtpDto dto,
  ) async {
    return await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.verifyRegisterOtp,
      data: dto.toJson(),
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  @override
  Future<ApiResponse<void>> requestResetPassword(
    RequestResetPasswordDto dto,
  ) async {
    return await _apiClient.post<void>(
      ApiEndpoints.requestResetPassword,
      data: dto.toJson(),
    );
  }

  @override
  Future<ApiResponse<void>> verifyResetPassword(
    VerifyResetPasswordDto dto,
  ) async {
    return await _apiClient.post<void>(
      ApiEndpoints.verifyResetPassword,
      data: dto.toJson(),
    );
  }
}

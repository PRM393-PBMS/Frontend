import '../entities/user_entity.dart';

/// Repository Interface ở Domain Layer
abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();

  // Đăng ký tài khoản
  Future<void> sendRegisterOtp({
    required String userName,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  });

  Future<void> verifyRegisterOtp({
    required String email,
    required String otp,
  });

  // Quên mật khẩu
  Future<void> requestResetPassword({required String email});

  Future<void> verifyResetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
}

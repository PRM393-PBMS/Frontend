/// DTO gửi lên POST /api/Auth/send-register-otp
class RegisterRequestDto {
  final String userName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;

  const RegisterRequestDto({
    required this.userName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}

/// DTO gửi lên POST /api/Auth/verify-register-otp
class VerifyRegisterOtpDto {
  final String email;
  final String otp;

  const VerifyRegisterOtpDto({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

/// DTO gửi lên POST /api/Auth/request-reset-password
class RequestResetPasswordDto {
  final String email;

  const RequestResetPasswordDto({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// DTO gửi lên POST /api/Auth/verify-reset-password
class VerifyResetPasswordDto {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const VerifyResetPasswordDto({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

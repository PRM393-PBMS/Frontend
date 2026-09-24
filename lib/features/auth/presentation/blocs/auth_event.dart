import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Kiểm tra phiên đăng nhập khi khởi động app
class AuthCheckRequested extends AuthEvent {}

/// Người dùng thực hiện đăng nhập
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Gửi OTP Đăng ký
class AuthSendRegisterOtpSubmitted extends AuthEvent {
  final String userName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;

  const AuthSendRegisterOtpSubmitted({
    required this.userName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [
        userName,
        fullName,
        email,
        phoneNumber,
        password,
        confirmPassword,
      ];
}

/// Xác thực OTP tạo user
class AuthVerifyRegisterOtpSubmitted extends AuthEvent {
  final String email;
  final String otp;

  const AuthVerifyRegisterOtpSubmitted({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

/// Yêu cầu OTP quên mật khẩu
class AuthRequestResetPasswordSubmitted extends AuthEvent {
  final String email;

  const AuthRequestResetPasswordSubmitted({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Xác thực OTP và đặt mật khẩu mới
class AuthVerifyResetPasswordSubmitted extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const AuthVerifyResetPasswordSubmitted({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword, confirmPassword];
}

/// Xóa thông báo lỗi / thành công sau khi hiển thị SnackBar
class AuthClearMessageRequested extends AuthEvent {}

/// Đăng xuất khỏi hệ thống
class AuthLogoutRequested extends AuthEvent {}

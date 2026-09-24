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

/// Đăng xuất khỏi hệ thống
class AuthLogoutRequested extends AuthEvent {}

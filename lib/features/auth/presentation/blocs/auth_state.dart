import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final String? successMessage;
  final bool otpSent;
  final bool registeredSuccess;
  final bool resetPasswordSuccess;
  final String? pendingEmail;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.otpSent = false,
    this.registeredSuccess = false,
    this.resetPasswordSuccess = false,
    this.pendingEmail,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    String? successMessage,
    bool? otpSent,
    bool? registeredSuccess,
    bool? resetPasswordSuccess,
    String? pendingEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
      otpSent: otpSent ?? this.otpSent,
      registeredSuccess: registeredSuccess ?? this.registeredSuccess,
      resetPasswordSuccess: resetPasswordSuccess ?? this.resetPasswordSuccess,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        successMessage,
        otpSent,
        registeredSuccess,
        resetPasswordSuccess,
        pendingEmail,
      ];
}

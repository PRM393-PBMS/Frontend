import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prm393_frontend/core/error/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSendRegisterOtpSubmitted>(_onAuthSendRegisterOtpSubmitted);
    on<AuthVerifyRegisterOtpSubmitted>(_onAuthVerifyRegisterOtpSubmitted);
    on<AuthRequestResetPasswordSubmitted>(_onAuthRequestResetPasswordSubmitted);
    on<AuthVerifyResetPasswordSubmitted>(_onAuthVerifyResetPasswordSubmitted);
    on<AuthClearMessageRequested>(_onAuthClearMessageRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null));

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Đăng nhập không thành công. Vui lòng kiểm tra lại.',
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onAuthSendRegisterOtpSubmitted(
    AuthSendRegisterOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null));

    try {
      await _authRepository.sendRegisterOtp(
        userName: event.userName,
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        otpSent: true,
        pendingEmail: event.email,
        successMessage: 'Mã xác thực OTP đã được gửi về email ${event.email}',
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Không thể gửi mã OTP. Vui lòng thử lại sau.',
      ));
    }
  }

  Future<void> _onAuthVerifyRegisterOtpSubmitted(
    AuthVerifyRegisterOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null));

    try {
      await _authRepository.verifyRegisterOtp(
        email: event.email,
        otp: event.otp,
      );

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        registeredSuccess: true,
        otpSent: false,
        successMessage: 'Đăng ký tài khoản thành công! Vui lòng đăng nhập.',
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Xác thực OTP thất bại. Vui lòng thử lại.',
      ));
    }
  }

  Future<void> _onAuthRequestResetPasswordSubmitted(
    AuthRequestResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null));

    try {
      await _authRepository.requestResetPassword(email: event.email);

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        otpSent: true,
        pendingEmail: event.email,
        successMessage: 'Nếu email tồn tại, mã OTP đặt lại mật khẩu đã được gửi!',
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Yêu cầu đặt lại mật khẩu thất bại.',
      ));
    }
  }

  Future<void> _onAuthVerifyResetPasswordSubmitted(
    AuthVerifyResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, successMessage: null));

    try {
      await _authRepository.verifyResetPassword(
        email: event.email,
        otp: event.otp,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        resetPasswordSuccess: true,
        otpSent: false,
        successMessage: 'Đặt lại mật khẩu thành công! Hãy đăng nhập bằng mật khẩu mới.',
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Đặt lại mật khẩu thất bại. Kiểm tra mã OTP.',
      ));
    }
  }

  void _onAuthClearMessageRequested(
    AuthClearMessageRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}

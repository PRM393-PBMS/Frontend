import 'package:equatable/equatable.dart';

/// Base Failure biểu diễn lỗi chuyển giao từ Repository lên BLoC / UI
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = '',
    super.statusCode = 500,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '',
    super.statusCode,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode = 401,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode = 400,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = '',
  });
}

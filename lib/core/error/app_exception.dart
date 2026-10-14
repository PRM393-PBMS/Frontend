/// Các ngoại lệ hệ thống ánh xạ từ API Backend và Network
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'AppException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = '',
    super.statusCode,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = '',
    super.statusCode = 401,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = '',
    super.statusCode = 403,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.details,
  });
}

class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.statusCode = 409,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = '',
    super.statusCode = 404,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = '',
    super.statusCode = 500,
  });
}

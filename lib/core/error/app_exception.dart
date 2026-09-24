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
  String toString() => 'AppException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
    super.statusCode,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    super.statusCode = 401,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Tài khoản không có quyền truy cập hoặc đã bị khóa.',
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
    super.message = 'Không tìm thấy dữ liệu yêu cầu.',
    super.statusCode = 404,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Hệ thống máy chủ đang bận. Vui lòng thử lại sau.',
    super.statusCode = 500,
  });
}

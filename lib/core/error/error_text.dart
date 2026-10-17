import 'app_exception.dart';
import 'failure.dart';

/// Thông điệp lỗi thân thiện cho người dùng từ bất kỳ lỗi nào.
String errorText(Object error) {
  if (error is NetworkException) {
    return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  }
  if (error is UnauthorizedException) {
    return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  }
  if (error is AppException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is Failure && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return 'Có lỗi xảy ra. Vui lòng thử lại.';
}

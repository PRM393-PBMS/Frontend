import '../../../core/error/app_exception.dart';
import '../../../core/error/error_text.dart';

String scanErrorText(Object error) {
  if (error is AppException) {
    if (error is UnauthorizedException || error.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Đăng nhập lại bằng cùng tài khoản để gửi ảnh đang lưu.';
    }
    if (error is ForbiddenException || error.statusCode == 403) {
      return 'Tài khoản không có quyền gửi ảnh tại cổng này. Liên hệ quản lý.';
    }
    if (error.statusCode == 413) {
      return 'Ảnh quá lớn (tối đa 8MB). Xóa ảnh này và chụp lại.';
    }
    if (error is NetworkException) {
      return 'Chưa xác nhận gửi được ảnh. Kiểm tra mạng và lượt quét gần đây trước khi gửi lại.';
    }
    if ((error.statusCode ?? 0) >= 500) {
      return 'Máy chủ đang lỗi. Ảnh đã lưu, bạn có thể gửi lại sau.';
    }
  }
  return errorText(error);
}

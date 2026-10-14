import '../../l10n/app_localizations.dart';
import '../error/app_exception.dart';
import '../error/failure.dart';

/// Thông điệp lỗi hiển thị cho người dùng.
/// Lỗi phía client (mất mạng, mã HTTP không kèm thông điệp) được dịch theo ngôn ngữ đang chọn;
/// thông điệp nghiệp vụ do backend trả về được giữ nguyên văn.
String errorText(Object? error, AppLocalizations t) {
  if (error is NetworkException) return t.errorNetwork;
  if (error is AppException) {
    if (error.message.trim().isEmpty) {
      return error.statusCode != null
          ? t.errorStatus('${error.statusCode}')
          : t.errorGeneric;
    }
    return error.message;
  }
  if (error is Failure) {
    return error.message.trim().isEmpty ? t.errorGeneric : error.message;
  }
  if (error is String && error.isNotEmpty) return error;
  return t.errorGeneric;
}

bool isNotFound(Object error) => error is NotFoundException;

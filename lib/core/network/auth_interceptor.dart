import 'package:dio/dio.dart';

import '../config/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService storageService;
  final void Function()? onSessionExpired;

  Future<String?>? _refreshFuture;
  Future<void>? _expirationFuture;

  static const _retryKey = 'authRetried';

  static const _publicPaths = {
    ApiEndpoints.login,
    ApiEndpoints.sendRegisterOtp,
    ApiEndpoints.verifyRegisterOtp,
    ApiEndpoints.requestResetPassword,
    ApiEndpoints.verifyResetPassword,
    ApiEndpoints.refreshToken,
  };

  AuthInterceptor({
    required this.dio,
    required this.storageService,
    this.onSessionExpired,
  });

  bool _isPublic(RequestOptions options) {
    return _publicPaths.contains(Uri.parse(options.path).path);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_isPublic(options)) {
        final token = await storageService.getAccessToken();

        if (token != null && token.isNotEmpty) {
          _expirationFuture = null;
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
      }

      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: 'Không thể đọc thông tin đăng nhập.',
        ),
      );
    }
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    if (err.response?.statusCode != 401 ||
        _isPublic(request) ||
        request.extra[_retryKey] == true) {
      handler.next(err);
      return;
    }

    try {
      var token = await storageService.getAccessToken();
      final failedAuthorization = request.headers['Authorization'];

      // Nếu một request khác đã refresh xong, dùng token mới luôn.
      if (token == null ||
          token.isEmpty ||
          failedAuthorization == 'Bearer $token') {
        token = await _refreshOnce();
      }

      if (token == null || token.isEmpty) {
        handler.next(err);
        return;
      }

      final retry = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $token',
        },
        extra: {
          ...request.extra,
          _retryKey: true,
        },
      );

      // FormData đã gửi cần được clone trước khi gửi lại.
      if (request.data is FormData) {
        retry.data = (request.data as FormData).clone();
      }

      try {
        final response = await dio.fetch<dynamic>(retry);
        handler.resolve(response);
      } on DioException catch (retryError) {
        if (retryError.response?.statusCode == 401) {
          await _expireSession();
        }

        handler.next(retryError);
      }
    } on DioException catch (refreshError) {
      // Giữ nguyên lỗi mạng/timeout, không biến thành đăng xuất.
      handler.next(refreshError);
    } catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: request,
          error: error,
          stackTrace: stackTrace,
          message: 'Không thể khôi phục phiên đăng nhập.',
        ),
      );
    }
  }

  Future<String?> _refreshOnce() async {
    final running = _refreshFuture;
    if (running != null) return running;

    final future = _refreshAccessToken();
    _refreshFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await storageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        sendTimeout: dio.options.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refreshTokenKey': refreshToken},
      );

      final data = response.data;

      if (data is! Map<String, dynamic> ||
          data['isSuccess'] != true) {
        if (data is Map<String, dynamic> &&
            (data['statusCode'] == 401 ||
                data['statusCode'] == 403)) {
          await _expireSession();
          return null;
        }

        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Máy chủ không cấp được access token mới.',
        );
      }

      final result = data['result'];
      final token = result is Map<String, dynamic>
          ? result['accessToken']
          : null;

      if (token is! String || token.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Phản hồi refresh thiếu access token.',
        );
      }

      // Không khôi phục token nếu người dùng đã đổi/xóa phiên.
      final currentRefreshToken =
          await storageService.getRefreshToken();

      if (currentRefreshToken != refreshToken) {
        return null;
      }

      await storageService.saveAccessToken(token);
      return token;
    } on DioException catch (error) {
      final status = error.response?.statusCode;

      if (status == 401 || status == 403) {
        await _expireSession();
        return null;
      }

      rethrow;
    } finally {
      refreshDio.close();
    }
  }

  Future<void> _expireSession() {
    return _expirationFuture ??= _clearSession();
  }

  Future<void> _clearSession() async {
    await storageService.clearAuthData();
    onSessionExpired?.call();
  }
}
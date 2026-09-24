import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor tự động thêm Bearer token vào Request và xử lý Refresh Token khi gặp HTTP 401
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService storageService;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.dio,
    required this.storageService,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Không gán token cho các endpoint public như Login, OTP, Refresh
    final path = options.path;
    final isPublicEndpoint = path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.sendRegisterOtp) ||
        path.contains(ApiEndpoints.verifyRegisterOtp) ||
        path.contains(ApiEndpoints.requestResetPassword) ||
        path.contains(ApiEndpoints.verifyResetPassword) ||
        path.contains(ApiEndpoints.refreshToken);

    if (!isPublicEndpoint) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Nếu lỗi không phải 401 hoặc xảy ra ngay tại API auth/refresh, bỏ qua cho handler xử lý lỗi
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains(ApiEndpoints.login) ||
        err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(err);
    }

    // Nếu đang trong quá trình Refresh Token, các request 401 khác sẽ đợi token mới
    if (_isRefreshing) {
      try {
        final newToken = await _refreshCompleter?.future;
        if (newToken != null && newToken.isNotEmpty) {
          final clonedOptions = err.requestOptions;
          clonedOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(clonedOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (_refreshCompleter?.isCompleted == false) {
          _refreshCompleter?.complete(null);
        }
        return handler.next(err);
      }

      // Gọi endpoint cấp Access Token mới: POST /api/Auth/refresh-token
      // DTO: { "refreshTokenKey": "..." }
      final refreshResponse = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshTokenKey': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final responseData = refreshResponse.data;
      if (responseData is Map<String, dynamic> &&
          (responseData['isSuccess'] == true || responseData['statusCode'] == 200)) {
        final result = responseData['result'];
        final newAccessToken = result is Map<String, dynamic>
            ? result['accessToken'] as String?
            : null;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storageService.saveAccessToken(newAccessToken);

          _refreshCompleter?.complete(newAccessToken);

          // Thử lại request ban đầu với Access Token mới
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        }
      }

      if (_refreshCompleter?.isCompleted == false) {
        _refreshCompleter?.complete(null);
      }
      return handler.next(err);
    } catch (e) {
      _handleSessionExpired();
      if (_refreshCompleter?.isCompleted == false) {
        _refreshCompleter?.completeError(e);
      }
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  void _handleSessionExpired() {
    storageService.clearAuthData();
    onSessionExpired?.call();
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ghi log request / response gọn gàng trong Debug mode. Không in header (chứa token).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${options.method.toUpperCase()} ${options.uri}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] ERROR ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri} ${err.response?.data ?? err.message}',
      );
    }
    super.onError(err, handler);
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor ghi log request / response một cách rõ ràng trong môi trường Debug
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ [DIO-REQUEST] 🚀 ${options.method.toUpperCase()} ${options.uri}');
      debugPrint('│ Headers: ${jsonEncode(options.headers)}');
      if (options.data != null) {
        debugPrint('│ Body: ${options.data is FormData ? '[FormData]' : jsonEncode(options.data)}');
      }
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ [DIO-RESPONSE] ✅ ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('│ Data: ${jsonEncode(response.data)}');
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ [DIO-ERROR] ❌ ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('│ Message: ${err.message}');
      debugPrint('│ Response Data: ${err.response?.data}');
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor ghi log request / response một cách rõ ràng trong môi trường Debug.
/// Che token, mật khẩu, OTP và dữ liệu lớn (ảnh chữ ký) trước khi in ra logcat.
class LoggingInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'authorization',
    'password',
    'newpassword',
    'confirmpassword',
    'oldpassword',
    'otp',
    'otpcode',
    'accesstoken',
    'refreshtoken',
    'token',
    'signatureimage',
  };

  /// Bản sao đã che của headers / body / response để ghi log.
  static Object? redact(Object? value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          e.key: _sensitiveKeys.contains(e.key.toString().toLowerCase())
              ? '***'
              : redact(e.value),
      };
    }
    if (value is List) return value.map(redact).toList();
    return value;
  }

  static String _json(Object? value) {
    try {
      return jsonEncode(redact(value));
    } catch (_) {
      return '[không in được]';
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ [DIO-REQUEST] 🚀 ${options.method.toUpperCase()} ${options.uri}');
      debugPrint('│ Headers: ${_json(options.headers)}');
      if (options.data != null) {
        debugPrint('│ Body: ${options.data is FormData ? '[FormData]' : _json(options.data)}');
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
      debugPrint('│ Data: ${_json(response.data)}');
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
      debugPrint('│ Response Data: ${_json(err.response?.data)}');
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}

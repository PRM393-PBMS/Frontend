import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage_service.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// Base API Client bọc Dio, hỗ trợ xử lý lỗi thống nhất và parse theo Envelope PBMS
class ApiClient {
  late final Dio _dio;

  ApiClient({
    required SecureStorageService storageService,
    void Function()? onSessionExpired,
    Dio? customDio,
  }) {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio,
        storageService: storageService,
        onSessionExpired: onSessionExpired,
      ),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Xử lý dữ liệu trả về theo Envelope PBMS
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    final dynamic data = response.data;

    if (data is Map<String, dynamic>) {
      final envelope = ApiResponse<T>.fromJson(data, fromJsonT);

      // Nếu backend trả về isSuccess = false dù HTTP status là 200/400
      if (!envelope.isSuccess && envelope.statusCode >= 400) {
        throw _mapStatusCodeToException(
          envelope.statusCode,
          envelope.message ?? 'Yêu cầu không thành công',
          envelope.result,
        );
      }
      return envelope;
    }

    // Trường hợp trả về raw object không bọc envelope (như upload raw URL)
    return ApiResponse<T>(
      statusCode: response.statusCode ?? 200,
      isSuccess: true,
      message: null,
      result: fromJsonT != null ? fromJsonT(data) : data as T?,
    );
  }

  /// Chuyển đổi DioException thành Domain AppException tương ứng
  AppException _handleDioError(DioException error) {
    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 500;
      final dynamic data = response.data;
      String errorMessage = 'Đã xảy ra lỗi (${response.statusCode})';

      if (data is Map<String, dynamic>) {
        if (data['message'] is String) {
          errorMessage = data['message'];
        } else if (data['message'] is List) {
          errorMessage = (data['message'] as List).join('\n');
        }
      }

      return _mapStatusCodeToException(statusCode, errorMessage, data);
    }

    return AppException(
      message: error.message ?? 'Lỗi kết nối máy chủ không xác định',
    );
  }

  AppException _mapStatusCodeToException(
    int statusCode,
    String message,
    dynamic details,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(message: message, details: details);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ConflictException(message: message);
      case 500:
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }
}

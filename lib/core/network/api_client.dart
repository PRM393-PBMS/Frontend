import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage_service.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// File ảnh chuẩn bị upload (dùng bytes để chạy được cả mobile lẫn web).
class UploadFile {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const UploadFile({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'image/jpeg',
  });
}

/// Base API Client bọc Dio, xử lý lỗi thống nhất và parse Envelope PBMS.
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
            contentType: Headers.jsonContentType,
            headers: {'Accept': 'application/json'},
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
    T Function(dynamic json)? fromJsonT,
  }) =>
      _send<T>(
          () => _dio.get(path, queryParameters: queryParameters), fromJsonT);

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) =>
      _send<T>(() => _dio.post(path, data: data), fromJsonT);

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) =>
      _send<T>(() => _dio.put(path, data: data), fromJsonT);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic json)? fromJsonT,
  }) =>
      _send<T>(() => _dio.delete(path), fromJsonT);

  /// GET danh sách. Backend PBMS trả 404 khi danh sách rỗng, nên 404 được hiểu là `[]`.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response =
          await get<dynamic>(path, queryParameters: queryParameters);
      return parseList(response.result, parse);
    } on NotFoundException {
      return <T>[];
    }
  }

  static List<T> parseList<T>(
      dynamic raw, T Function(Map<String, dynamic> json) parse) {
    if (raw is! List) return <T>[];
    return raw.whereType<Map<String, dynamic>>().map(parse).toList();
  }

  /// Upload multipart field `file`. Một số endpoint upload trả JSON thô (không bọc envelope),
  /// nên hàm trả về body gốc. [acceptStatuses] cho phép đọc body ở mã lỗi nghiệp vụ (vd. 422).
  Future<dynamic> upload(
    String path,
    UploadFile file, {
    Set<int> acceptStatuses = const {},
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes,
        filename: file.fileName,
        contentType: MediaType.parse(file.mimeType),
      ),
    });
    try {
      final response = await _dio.post(path, data: form);
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('isSuccess')) {
        return _handleResponse<dynamic>(response, null).result;
      }
      return data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && acceptStatuses.contains(status)) {
        return e.response?.data;
      }
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? fromJsonT,
  ) async {
    try {
      final response = await request();
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    final dynamic data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('isSuccess')) {
      final envelope = ApiResponse<T>.fromJson(data, fromJsonT);
      if (!envelope.isSuccess) {
        throw _mapStatusCodeToException(
          envelope.statusCode >= 400 ? envelope.statusCode : 400,
          envelope.message ?? '',
          envelope.result,
        );
      }
      return envelope;
    }

    return ApiResponse<T>(
      statusCode: response.statusCode ?? 200,
      isSuccess: true,
      message: null,
      result: fromJsonT != null ? fromJsonT(data) : data as T?,
    );
  }

  AppException _handleDioError(DioException error) {
    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.message != null && error.message!.contains('XMLHttpRequest'))) {
      return const NetworkException();
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 500;
      final dynamic data = response.data;
      String errorMessage = '';

      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          errorMessage = message;
        } else if (message is List) {
          errorMessage = message.join('\n');
        }
      }

      return _mapStatusCodeToException(statusCode, errorMessage, data);
    }

    return AppException(
      message: '',
    );
  }

  AppException _mapStatusCodeToException(
    int statusCode,
    String message,
    dynamic details,
  ) {
    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(
            message: message, statusCode: statusCode, details: details);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ConflictException(message: message);
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }
}

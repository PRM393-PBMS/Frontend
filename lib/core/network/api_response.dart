/// Envelope Response chuẩn PBMS:
/// { "statusCode": 200, "message": "...", "isSuccess": true, "result": ... }
class ApiResponse<T> {
  final int statusCode;
  final String? message;
  final bool isSuccess;
  final T? result;

  const ApiResponse({
    required this.statusCode,
    this.message,
    required this.isSuccess,
    this.result,
  });

  bool get isOk => isSuccess && statusCode >= 200 && statusCode < 300;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      statusCode: json['statusCode'] as int? ?? 200,
      message: json['message'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? false,
      result: json['result'] != null && fromJsonT != null
          ? fromJsonT(json['result'])
          : json['result'] as T?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T value)? toJsonT) {
    return {
      'statusCode': statusCode,
      'message': message,
      'isSuccess': isSuccess,
      'result': result != null && toJsonT != null ? toJsonT(result as T) : result,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, isSuccess: $isSuccess, message: $message, result: $result)';
  }
}

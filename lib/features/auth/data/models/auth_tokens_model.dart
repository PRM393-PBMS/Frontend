import 'user_model.dart';

/// Model chứa kết quả đăng nhập thành công từ POST /api/Auth/login
class AuthTokensModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthTokensModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

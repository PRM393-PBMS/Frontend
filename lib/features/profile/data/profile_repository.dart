import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/user_model.dart';

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository(this._api);

  Future<UserModel> get() async {
    final res = await _api.get<dynamic>(ApiEndpoints.profile);
    return UserModel.fromJson(res.result as Map<String, dynamic>);
  }

  /// POST /api/profile/avatar (multipart `file`, JPEG/PNG/WebP, tối đa 5MB).
  Future<UserModel> uploadAvatar(UploadFile file) async {
    final raw = await _api.upload(ApiEndpoints.profileAvatar, file);
    return UserModel.fromJson(raw as Map<String, dynamic>);
  }

  /// PUT /api/profile chỉ cập nhật các trường được gửi (fullName, phoneNumber, email, password).
  Future<UserModel> update({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? password,
  }) async {
    final res = await _api.put<dynamic>(ApiEndpoints.profile, data: {
      if (fullName != null) 'fullName': fullName.trim(),
      if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
      if (email != null) 'email': email.trim(),
      if (password != null) 'password': password,
    });
    return UserModel.fromJson(res.result as Map<String, dynamic>);
  }
}

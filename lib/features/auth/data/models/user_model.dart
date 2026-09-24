import '../../domain/entities/user_entity.dart';

/// Data Model parse an toàn dữ liệu User từ Backend PBMS
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.userName,
    required super.email,
    super.fullName,
    super.phoneNumber,
    required super.roleName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['userId'] ?? json['id'] ?? '') as String,
      userName: (json['userName'] ?? json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roleName: (json['roleName'] ?? 'User') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'userName': userName,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'roleName': roleName,
    };
  }
}

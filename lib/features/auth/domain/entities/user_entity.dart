import 'package:equatable/equatable.dart';

/// Entity đại diện cho người dùng trong ứng dụng
class UserEntity extends Equatable {
  final String id;
  final String userName;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String roleName;

  const UserEntity({
    required this.id,
    required this.userName,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.roleName,
  });

  bool get isManager => roleName.toLowerCase() == 'manager' || roleName.toLowerCase() == 'admin';
  bool get isStaff => roleName.toLowerCase() == 'staff';
  bool get isCustomer => !isManager && !isStaff;

  @override
  List<Object?> get props => [id, userName, email, fullName, phoneNumber, roleName];
}

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String userName;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String roleName;
  final String? avatarUrl;
  final String? walletId;

  const UserEntity({
    required this.id,
    required this.userName,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.roleName,
    this.avatarUrl,
    this.walletId,
  });

  String get _role => roleName.trim().toLowerCase();

  /// Nhân viên vận hành cổng (backend cho phép cả Staff và Manager).
  bool get isStaff => _role == 'staff' || _role == 'manager';

  /// Tài xế / khách hàng (backend dùng roleName "User" hoặc "Customer").
  bool get isCustomer => _role == 'user' || _role == 'customer';

  /// Vai trò ứng dụng di động chưa hỗ trợ (vd. Admin chỉ dùng trang quản trị).
  bool get isSupported => isStaff || isCustomer;

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty)
      ? fullName!.trim()
      : userName;

  @override
  List<Object?> get props => [
        id,
        userName,
        email,
        fullName,
        phoneNumber,
        roleName,
        avatarUrl,
        walletId,
      ];
}

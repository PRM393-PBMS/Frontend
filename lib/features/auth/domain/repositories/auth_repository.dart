import '../entities/user_entity.dart';

/// Repository Interface ở Domain Layer
abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}

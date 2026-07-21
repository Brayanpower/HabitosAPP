import 'package:habitos_app/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String name, String email, String password);
  Future<void> saveSession(String token, UserEntity user);
  Future<String?> getToken();
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}

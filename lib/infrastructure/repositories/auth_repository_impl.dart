import 'package:habitos_app/domain/datasources/auth_datasource.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;

  AuthRepositoryImpl({required this.datasource});

  @override
  Future<UserEntity> login(String email, String password) {
    return datasource.login(email, password);
  }

  @override
  Future<UserEntity> register(String name, String email, String password) {
    return datasource.register(name, email, password);
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) {
    return datasource.updateUser(user);
  }

  @override
  Future<void> saveSession(String token, UserEntity user) {
    return datasource.saveSession(token, user);
  }

  @override
  Future<String?> getToken() {
    return datasource.getToken();
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    return datasource.getCurrentUser();
  }

  @override
  Future<void> logout() {
    return datasource.logout();
  }

  @override
  Future<bool> isAuthenticated() {
    return datasource.isAuthenticated();
  }
}

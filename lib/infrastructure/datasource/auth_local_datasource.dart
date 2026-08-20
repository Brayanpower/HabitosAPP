import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/datasources/auth_datasource.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/infrastructure/database/database_helper.dart';
import 'package:habitos_app/infrastructure/models/user_model.dart';

class AuthLocalDatasource implements AuthDatasource {
  @override
  Future<UserEntity> login(String email, String password) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isEmpty) {
      throw Exception('Credenciales inválidas');
    }

    final user = UserModel.fromMap(maps.first).toEntity();
    final token = TokenHelper.generateToken(user.id);
    await saveSession(token, user);
    return user;
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
  ) async {
    final db = await DatabaseHelper.database;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      throw Exception('El email ya está registrado');
    }

    final user = UserEntity(
      id: _generateId(),
      name: name,
      email: email,
      password: password,
      createdAt: DateTime.now(),
    );

    await db.insert('users', UserModel.fromEntity(user).toMap());
    return user;
  }

  @override
  Future<void> saveSession(String token, UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(
      AppConstants.userKey,
      jsonEncode(UserModel.fromEntity(user).toMap()),
    );
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null || !TokenHelper.isTokenValid(token)) {
      return null;
    }
    return token;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromMap(map).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  String _generateId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}';
  }
}

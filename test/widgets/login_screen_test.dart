import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/presentation/screens/auth/login_screen.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/domain/repositories/auth_repository.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async {
    return UserEntity(
      id: '1',
      name: 'Test',
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    return UserEntity(
      id: '1',
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveSession(String token, UserEntity user) async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<UserEntity> updateUser(UserEntity user, {String? newPassword}) async => user;
}

void main() {
  group('LoginScreen', () {
    testWidgets('should render login form', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(authRepository: MockAuthRepository()),
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Construye tu mejor versión cada día'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show validation errors on empty form',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(authRepository: MockAuthRepository()),
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Ingresa tu email'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });
  });
}

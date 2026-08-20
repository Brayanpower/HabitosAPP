import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/providers/theme_provider.dart';
import 'package:habitos_app/presentation/screens/auth/login_screen.dart';
import 'package:habitos_app/domain/repositories/auth_repository.dart';
import 'package:habitos_app/domain/repositories/habit_repository.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async {
    return UserEntity(id: '1', name: 'Test', email: email, createdAt: DateTime.now());
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    return UserEntity(id: '1', name: name, email: email, createdAt: DateTime.now());
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
}

class MockHabitRepository implements HabitRepository {
  @override
  Future<List<HabitEntity>> getHabits(String userId) async => [];
  @override
  Future<HabitEntity> getHabitById(String id) async =>
      HabitEntity(id: id, userId: 'u1', name: 'Test', createdAt: DateTime.now());
  @override
  Future<HabitEntity> createHabit(HabitEntity habit) async => habit;
  @override
  Future<HabitEntity> updateHabit(HabitEntity habit) async => habit;
  @override
  Future<void> deleteHabit(String id) async {}
  @override
  Future<void> logHabit(String habitId, DateTime date) async {}
  @override
  Future<void> unlogHabit(String habitId, DateTime date) async {}
  @override
  Future<bool> isHabitCompletedOnDate(String habitId, DateTime date) async => false;
  @override
  Future<List<HabitLogEntity>> getHabitLogs(String habitId) async => [];
  @override
  Future<List<HabitLogEntity>> getLogsByDateRange(String habitId, DateTime start, DateTime end) async => [];
  @override
  Future<Map<DateTime, bool>> getCompletionStatus(String habitId, DateTime start, DateTime end) async => {};
  @override
  Future<int> getCurrentStreak(String habitId) async => 0;
  @override
  Future<int> getBestStreak(String habitId) async => 0;
  @override
  Future<double> getCompletionRate(String habitId, DateTime start, DateTime end) async => 0.0;
  @override
  Future<int> getTotalCompletions(String habitId) async => 0;
}

void main() {
  testWidgets('App should render LoginScreen when unauthenticated', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepository: MockAuthRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => HabitProvider(habitRepository: MockHabitRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

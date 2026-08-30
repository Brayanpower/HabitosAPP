import 'package:habitos_app/infrastructure/database/database_helper.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';
import 'package:habitos_app/infrastructure/models/user_model.dart';

class SeedHelper {
  SeedHelper._();

  static Future<void> seedTestUser() async {
    final db = await DatabaseHelper.database;
    final users = await db.query('users', limit: 1);
    if (users.isEmpty) {
      final user = UserModel(
        id: 'test_user_001',
        name: 'Usuario Demo',
        email: 'demo@habitos.app',
        password: '123456',
        gender: 'masculino',
        weight: 72.5,
        height: 175.0,
        age: 26,
        createdAt: DateTime.now(),
      );

      await db.insert('users', user.toMap());
    }

    // Asegurar que el usuario de prueba tenga solo el hábito de pasos como activo por defecto
    final habits = await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: ['test_user_001'],
      limit: 1,
    );

    if (habits.isEmpty) {
      final stepHabit = HabitModel(
        id: 'habit_step_default_001',
        userId: 'test_user_001',
        name: 'Caminar 8,000 pasos',
        description: 'Medición automática mediante los sensores de movimiento de tu dispositivo.',
        frequency: 'daily',
        category: 'salud',
        createdAt: DateTime.now(),
        isActive: true,
        goalTarget: 30,
        goalDays: 30,
        timesPerDay: 1,
        targetType: 'steps',
        targetValue: 8000,
        unit: 'pasos',
      );
      await db.insert('habits', stepHabit.toMap());
    }
  }

  static Future<void> seedStepHabitForUser(String userId) async {
    final db = await DatabaseHelper.database;
    final habits = await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (habits.isEmpty) {
      final stepHabit = HabitModel(
        id: 'step_habit_$userId',
        userId: userId,
        name: 'Caminar 8,000 pasos',
        description: 'Medición automática mediante los sensores de movimiento de tu dispositivo.',
        frequency: 'daily',
        category: 'salud',
        createdAt: DateTime.now(),
        isActive: true,
        goalTarget: 30,
        goalDays: 30,
        timesPerDay: 1,
        targetType: 'steps',
        targetValue: 8000,
        unit: 'pasos',
      );
      await db.insert('habits', stepHabit.toMap());
    }
  }
}

import 'package:habitos_app/infrastructure/database/database_helper.dart';
import 'package:habitos_app/infrastructure/models/user_model.dart';

class SeedHelper {
  SeedHelper._();

  static Future<void> seedTestUser() async {
    final db = await DatabaseHelper.database;
    final users = await db.query('users', limit: 1);
    if (users.isNotEmpty) return;

    final user = UserModel(
      id: 'test_user_001',
      name: 'Usuario Demo',
      email: 'demo@habitos.app',
      password: '123456',
      createdAt: DateTime.now(),
    );

    await db.insert('users', user.toMap());
  }
}

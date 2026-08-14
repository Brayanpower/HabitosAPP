import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';

class SeedHelper {
  SeedHelper._();

  /// Crea el hábito de pasos por defecto para un usuario si aún no tiene uno.
  static Future<void> seedStepHabitForUser(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final habitsRef = firestore.collection('habits');

    final existing = await habitsRef
        .where('user_id', isEqualTo: userId)
        .where('target_type', isEqualTo: 'steps')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    final stepHabit = HabitModel(
      id: 'step_habit_$userId',
      userId: userId,
      name: 'Caminar 8,000 pasos',
      description:
          'Medición automática mediante los sensores de movimiento de tu dispositivo.',
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

    await habitsRef.doc(stepHabit.id).set(stepHabit.toMap());
  }
}
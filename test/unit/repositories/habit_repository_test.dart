import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';

void main() {
  group('HabitEntity', () {
    test('should create habit with default values', () {
      final habit = HabitEntity(
        id: '1',
        userId: 'u1',
        name: 'Leer',
        createdAt: DateTime(2026, 7, 1),
      );
      expect(habit.frequency, HabitFrequency.daily);
      expect(habit.isActive, true);
      expect(habit.currentStreak, 0);
      expect(habit.bestStreak, 0);
    });

    test('copyWith should update only specified fields', () {
      final habit = HabitEntity(
        id: '1',
        userId: 'u1',
        name: 'Leer',
        createdAt: DateTime(2026, 7, 1),
      );
      final updated = habit.copyWith(name: 'Meditar', currentStreak: 5);
      expect(updated.name, 'Meditar');
      expect(updated.currentStreak, 5);
      expect(updated.id, '1');
      expect(updated.frequency, HabitFrequency.daily);
    });
  });

  group('HabitLogEntity', () {
    test('should create habit log with default isCompleted true', () {
      final log = HabitLogEntity(
        id: '1',
        habitId: 'h1',
        date: DateTime(2026, 7, 29),
      );
      expect(log.isCompleted, true);
    });

    test('copyWith should update fields', () {
      final log = HabitLogEntity(
        id: '1',
        habitId: 'h1',
        date: DateTime(2026, 7, 29),
      );
      final updated = log.copyWith(isCompleted: false);
      expect(updated.isCompleted, false);
      expect(updated.id, '1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';

void main() {
  group('Smart HabitEntity & HabitModel Tests', () {
    test('HabitEntity should correctly classify steps, timer and water habits', () {
      final stepHabit = HabitEntity(
        id: 'h1',
        userId: 'u1',
        name: 'Caminar 8000 pasos',
        frequency: HabitFrequency.daily,
        category: HabitCategory.salud,
        createdAt: DateTime.now(),
        targetType: HabitTargetType.steps,
        targetValue: 8000,
        unit: 'pasos',
      );

      expect(stepHabit.isStepsHabit, isTrue);
      expect(stepHabit.isTimerHabit, isFalse);
      expect(stepHabit.isWaterHabit, isFalse);
      expect(stepHabit.targetValue, 8000);

      final timerHabit = HabitEntity(
        id: 'h2',
        userId: 'u1',
        name: 'Meditar',
        frequency: HabitFrequency.daily,
        category: HabitCategory.salud,
        createdAt: DateTime.now(),
        targetType: HabitTargetType.timer,
        targetValue: 20,
        unit: 'minutos',
      );

      expect(timerHabit.isTimerHabit, isTrue);
      expect(timerHabit.isStepsHabit, isFalse);
      expect(timerHabit.targetValue, 20);

      final waterHabit = HabitEntity(
        id: 'h3',
        userId: 'u1',
        name: 'Beber agua',
        frequency: HabitFrequency.daily,
        category: HabitCategory.salud,
        createdAt: DateTime.now(),
        targetType: HabitTargetType.water,
        targetValue: 2500,
        unit: 'ml',
      );

      expect(waterHabit.isWaterHabit, isTrue);
      expect(waterHabit.targetValue, 2500);
    });

    test('HabitModel should correctly serialize and deserialize targetType and targetValue', () {
      final now = DateTime.now();
      final model = HabitModel(
        id: 'm1',
        userId: 'u1',
        name: 'Caminar Diario',
        frequency: 'daily',
        category: 'salud',
        targetType: 'steps',
        targetValue: 10000,
        unit: 'pasos',
        createdAt: now,
        isActive: true,
        repeatDays: '1,2,3,4,5,6,7',
      );

      final map = model.toMap();
      expect(map['target_type'], 'steps');
      expect(map['target_value'], 10000);
      expect(map['unit'], 'pasos');

      final fromMap = HabitModel.fromMap(map);
      expect(fromMap.targetType, 'steps');
      expect(fromMap.targetValue, 10000);

      final entity = fromMap.toEntity();
      expect(entity.targetType, HabitTargetType.steps);
      expect(entity.targetValue, 10000);
      expect(entity.isStepsHabit, isTrue);
    });

    test('HabitTargetType helpers return proper default values', () {
      expect(HabitTargetType.fromString('steps'), HabitTargetType.steps);
      expect(HabitTargetType.fromString('timer'), HabitTargetType.timer);
      expect(HabitTargetType.fromString('water'), HabitTargetType.water);
      expect(HabitTargetType.fromString('counter'), HabitTargetType.counter);
      expect(HabitTargetType.fromString('invalid'), HabitTargetType.simpleCheck);

      expect(HabitTargetType.timer.defaultUnit, 'minutos');
      expect(HabitTargetType.water.defaultUnit, 'ml');
      expect(HabitTargetType.steps.defaultUnit, 'pasos');
    });
  });
}

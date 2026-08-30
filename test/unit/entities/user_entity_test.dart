import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';

void main() {
  group('UserEntity Biometrics and Health Metrics', () {
    test('should correctly compute BMI (IMC) and category', () {
      final userNormal = UserEntity(
        id: '1',
        name: 'Carlos',
        email: 'carlos@test.com',
        createdAt: DateTime.now(),
        weight: 70, // 70 kg
        height: 175, // 175 cm -> 1.75m -> IMC = 70 / (1.75 * 1.75) = 22.86
        gender: 'masculino',
        age: 25,
      );

      expect(userNormal.bmi, isNotNull);
      expect(userNormal.bmi!, closeTo(22.86, 0.1));
      expect(userNormal.bmiCategory, 'Saludable');

      final userOverweight = UserEntity(
        id: '2',
        name: 'Ana',
        email: 'ana@test.com',
        createdAt: DateTime.now(),
        weight: 80,
        height: 165, // 80 / (1.65^2) = 29.38
        gender: 'femenino',
      );

      expect(userOverweight.bmi!, closeTo(29.38, 0.1));
      expect(userOverweight.bmiCategory, 'Sobrepeso');
    });

    test('should calculate daily water recommendation in liters and glasses', () {
      final user = UserEntity(
        id: '1',
        name: 'Carlos',
        email: 'carlos@test.com',
        createdAt: DateTime.now(),
        weight: 70, // 70 * 35 / 1000 = 2.45 L -> ~10 glasses
      );

      expect(user.recommendedWaterLiters, closeTo(2.45, 0.05));
      expect(user.recommendedWaterGlasses, 10);
    });

    test('copyWith updates biometric fields without mutating original', () {
      final original = UserEntity(
        id: '1',
        name: 'Test',
        email: 'test@mail.com',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        weight: 75.5,
        height: 180.0,
        gender: 'masculino',
        age: 28,
      );

      expect(original.weight, isNull);
      expect(updated.weight, 75.5);
      expect(updated.height, 180.0);
      expect(updated.gender, 'masculino');
      expect(updated.age, 28);
      expect(updated.email, original.email);
    });
  });
}

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? password;
  final String? gender;
  final double? weight; // en kg
  final double? height; // en cm
  final int? age;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.gender,
    this.weight,
    this.height,
    this.age,
    required this.createdAt,
  });

  /// Cálculo de Índice de Masa Corporal (IMC)
  double? get bmi {
    if (weight == null || height == null || height! <= 0 || weight! <= 0) {
      return null;
    }
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Categoría del IMC según estándar OMS
  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'Sin calcular';
    if (b < 18.5) return 'Bajo peso';
    if (b < 25.0) return 'Saludable';
    if (b < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Ingesta recomendada de agua diaria en Litros (35 ml / kg)
  double get recommendedWaterLiters {
    if (weight == null || weight! <= 0) return 2.0;
    final liters = (weight! * 35) / 1000;
    return double.parse(liters.toStringAsFixed(1));
  }

  /// Vasos aproximados de agua (250 ml c/u)
  int get recommendedWaterGlasses {
    return (recommendedWaterLiters / 0.25).round();
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? gender,
    double? weight,
    double? height,
    int? age,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


enum HabitFrequency {
  daily,
  weekly,
  monthly,
}

enum HabitCategory {
  salud,
  trabajo,
  estudio,
  finanzas,
  hogar,
  social,
  ocio,
  otro;

  String get label {
    switch (this) {
      case HabitCategory.salud:
        return 'Salud';
      case HabitCategory.trabajo:
        return 'Trabajo';
      case HabitCategory.estudio:
        return 'Estudio';
      case HabitCategory.finanzas:
        return 'Finanzas';
      case HabitCategory.hogar:
        return 'Hogar';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.ocio:
        return 'Ocio';
      case HabitCategory.otro:
        return 'Otro';
    }
  }
}

class HabitEntity {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final HabitCategory category;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isActive;
  final int currentStreak;
  final int bestStreak;

  HabitEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.category = HabitCategory.otro,
    required this.createdAt,
    this.reminderTime,
    this.isActive = true,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  HabitEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    HabitFrequency? frequency,
    HabitCategory? category,
    DateTime? createdAt,
    DateTime? reminderTime,
    bool? isActive,
    int? currentStreak,
    int? bestStreak,
  }) {
    return HabitEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

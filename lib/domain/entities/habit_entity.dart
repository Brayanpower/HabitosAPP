enum HabitFrequency {
  daily,
  weekly,
  monthly,
}

class HabitEntity {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
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
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

class HabitLogEntity {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;

  HabitLogEntity({
    required this.id,
    required this.habitId,
    required this.date,
    this.isCompleted = true,
    this.completedAt,
  });

  HabitLogEntity copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return HabitLogEntity(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

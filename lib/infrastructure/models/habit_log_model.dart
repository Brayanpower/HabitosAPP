import 'package:habitos_app/domain/entities/habit_log_entity.dart';

class HabitLogModel {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    this.isCompleted = true,
    this.completedAt,
  });

  factory HabitLogModel.fromEntity(HabitLogEntity entity) {
    return HabitLogModel(
      id: entity.id,
      habitId: entity.habitId,
      date: entity.date,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
    );
  }

  factory HabitLogModel.fromMap(Map<String, dynamic> map) {
    return HabitLogModel(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().substring(0, 10),
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  HabitLogEntity toEntity() {
    return HabitLogEntity(
      id: id,
      habitId: habitId,
      date: date,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }
}

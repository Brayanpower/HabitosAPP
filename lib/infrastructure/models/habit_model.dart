import 'package:habitos_app/domain/entities/habit_entity.dart';

class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isActive;
  final int currentStreak;
  final int bestStreak;

  HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = 'daily',
    required this.createdAt,
    this.reminderTime,
    this.isActive = true,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  factory HabitModel.fromEntity(HabitEntity entity) {
    return HabitModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      frequency: entity.frequency.name,
      createdAt: entity.createdAt,
      reminderTime: entity.reminderTime,
      isActive: entity.isActive,
      currentStreak: entity.currentStreak,
      bestStreak: entity.bestStreak,
    );
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequency: map['frequency'] as String? ?? 'daily',
      createdAt: DateTime.parse(map['created_at'] as String),
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      isActive: (map['is_active'] as int) == 1,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
    };
  }

  HabitEntity toEntity() {
    return HabitEntity(
      id: id,
      userId: userId,
      name: name,
      description: description,
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == frequency,
        orElse: () => HabitFrequency.daily,
      ),
      createdAt: createdAt,
      reminderTime: reminderTime,
      isActive: isActive,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}

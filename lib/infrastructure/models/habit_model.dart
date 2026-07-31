import 'package:habitos_app/domain/entities/habit_entity.dart';

class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final String category;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isActive;
  final int currentStreak;
  final int bestStreak;

  final int? goalTarget;
  final int? goalDays;
  final String repeatDays;
  final int timesPerDay;
  final String targetType;
  final int targetValue;
  final String unit;

  HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = 'daily',
    this.category = 'otro',
    required this.createdAt,
    this.reminderTime,
    this.isActive = true,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.goalTarget,
    this.goalDays,
    this.repeatDays = '',
    this.timesPerDay = 1,
    this.targetType = 'simpleCheck',
    this.targetValue = 1,
    this.unit = 'check',
  });

  factory HabitModel.fromEntity(HabitEntity entity) {
    return HabitModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      frequency: entity.frequency.name,
      category: entity.category.name,
      createdAt: entity.createdAt,
      reminderTime: entity.reminderTime,
      isActive: entity.isActive,
      currentStreak: entity.currentStreak,
      bestStreak: entity.bestStreak,
      goalTarget: entity.goalTarget,
      goalDays: entity.goalDays,
      repeatDays: entity.repeatDays.join(','),
      timesPerDay: entity.timesPerDay,
      targetType: entity.targetType.name,
      targetValue: entity.targetValue,
      unit: entity.unit,
    );
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequency: map['frequency'] as String? ?? 'daily',
      category: map['category'] as String? ?? 'otro',
      createdAt: DateTime.parse(map['created_at'] as String),
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      isActive: (map['is_active'] as int) == 1,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      goalTarget: map['goal_target'] as int?,
      goalDays: map['goal_days'] as int?,
      repeatDays: map['repeat_days'] as String? ?? '',
      timesPerDay: map['times_per_day'] as int? ?? 1,
      targetType: map['target_type'] as String? ?? 'simpleCheck',
      targetValue: map['target_value'] as int? ?? 1,
      unit: map['unit'] as String? ?? 'check',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'goal_target': goalTarget,
      'goal_days': goalDays,
      'repeat_days': repeatDays,
      'times_per_day': timesPerDay,
      'target_type': targetType,
      'target_value': targetValue,
      'unit': unit,
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
      category: HabitCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => HabitCategory.otro,
      ),
      createdAt: createdAt,
      reminderTime: reminderTime,
      isActive: isActive,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      goalTarget: goalTarget,
      goalDays: goalDays,
      repeatDays: repeatDays.isEmpty
          ? []
          : repeatDays.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((d) => d > 0).toList(),
      timesPerDay: timesPerDay,
      targetType: HabitTargetType.values.firstWhere(
        (t) => t.name == targetType,
        orElse: () => HabitTargetType.simpleCheck,
      ),
      targetValue: targetValue,
      unit: unit,
    );
  }
}

import 'package:habitos_app/domain/datasources/habit_datasource.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:habitos_app/domain/repositories/habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitDatasource datasource;

  HabitRepositoryImpl({required this.datasource});

  @override
  Future<List<HabitEntity>> getHabits(String userId) {
    return datasource.getHabits(userId);
  }

  @override
  Future<HabitEntity> getHabitById(String id) {
    return datasource.getHabitById(id);
  }

  @override
  Future<HabitEntity> createHabit(HabitEntity habit) {
    return datasource.createHabit(habit);
  }

  @override
  Future<HabitEntity> updateHabit(HabitEntity habit) {
    return datasource.updateHabit(habit);
  }

  @override
  Future<void> deleteHabit(String id) {
    return datasource.deleteHabit(id);
  }

  @override
  Future<void> logHabit(String habitId, DateTime date) {
    return datasource.logHabit(habitId, date);
  }

  @override
  Future<void> unlogHabit(String habitId, DateTime date) {
    return datasource.unlogHabit(habitId, date);
  }

  @override
  Future<bool> isHabitCompletedOnDate(String habitId, DateTime date) {
    return datasource.isHabitCompletedOnDate(habitId, date);
  }

  @override
  Future<List<HabitLogEntity>> getHabitLogs(String habitId) {
    return datasource.getHabitLogs(habitId);
  }

  @override
  Future<List<HabitLogEntity>> getLogsByDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) {
    return datasource.getLogsByDateRange(habitId, start, end);
  }

  @override
  Future<Map<DateTime, bool>> getCompletionStatus(
    String habitId,
    DateTime start,
    DateTime end,
  ) {
    return datasource.getCompletionStatus(habitId, start, end);
  }

  @override
  Future<int> getCurrentStreak(String habitId) {
    return datasource.getCurrentStreak(habitId);
  }

  @override
  Future<int> getBestStreak(String habitId) {
    return datasource.getBestStreak(habitId);
  }

  @override
  Future<double> getCompletionRate(
    String habitId,
    DateTime start,
    DateTime end,
  ) {
    return datasource.getCompletionRate(habitId, start, end);
  }

  @override
  Future<int> getTotalCompletions(String habitId) {
    return datasource.getTotalCompletions(habitId);
  }
}

import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';

abstract class HabitRepository {
  Future<List<HabitEntity>> getHabits(String userId);
  Future<HabitEntity> getHabitById(String id);
  Future<HabitEntity> createHabit(HabitEntity habit);
  Future<HabitEntity> updateHabit(HabitEntity habit);
  Future<void> deleteHabit(String id);

  Future<void> logHabit(String habitId, DateTime date);
  Future<void> unlogHabit(String habitId, DateTime date);
  Future<bool> isHabitCompletedOnDate(String habitId, DateTime date);
  Future<List<HabitLogEntity>> getHabitLogs(String habitId);
  Future<List<HabitLogEntity>> getLogsByDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  );
  Future<Map<DateTime, bool>> getCompletionStatus(
    String habitId,
    DateTime start,
    DateTime end,
  );
  Future<int> getCurrentStreak(String habitId);
  Future<int> getBestStreak(String habitId);
  Future<double> getCompletionRate(String habitId, DateTime start, DateTime end);
  Future<int> getTotalCompletions(String habitId);
}

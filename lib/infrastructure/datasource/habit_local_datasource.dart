import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';
import 'package:habitos_app/domain/datasources/habit_datasource.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:habitos_app/infrastructure/database/database_helper.dart';
import 'package:habitos_app/infrastructure/models/habit_log_model.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';

class HabitLocalDatasource implements HabitDatasource {
  final _uuid = const Uuid();

  @override
  Future<List<HabitEntity>> getHabits(String userId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => HabitModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<HabitEntity> getHabitById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) throw Exception('Hábito no encontrado');
    return HabitModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<HabitEntity> createHabit(HabitEntity habit) async {
    final db = await DatabaseHelper.database;
    final model = HabitModel.fromEntity(habit);
    await db.insert('habits', model.toMap());
    return habit;
  }

  @override
  Future<HabitEntity> updateHabit(HabitEntity habit) async {
    final db = await DatabaseHelper.database;
    final model = HabitModel.fromEntity(habit);
    await db.update('habits', model.toMap(), where: 'id = ?', whereArgs: [habit.id]);
    return habit;
  }

  @override
  Future<void> deleteHabit(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> logHabit(String habitId, DateTime date) async {
    final db = await DatabaseHelper.database;
    final dateStr = DateHelper.formatDate(date);

    await db.insert('habit_logs', {
      'id': _uuid.v4(),
      'habit_id': habitId,
      'date': dateStr,
      'is_completed': 1,
      'completed_at': DateTime.now().toIso8601String(),
    });
    await _updateStreaks(habitId);
  }

  @override
  Future<void> unlogHabit(String habitId, DateTime date) async {
    final db = await DatabaseHelper.database;
    final dateStr = DateHelper.formatDate(date);
    final rows = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ? AND is_completed = 1',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await db.delete(
        'habit_logs',
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }
    await _updateStreaks(habitId);
  }

  @override
  Future<bool> isHabitCompletedOnDate(String habitId, DateTime date) async {
    final count = await getCountForDate(habitId, date);
    return count > 0;
  }

  @override
  Future<int> getCountForDate(String habitId, DateTime date) async {
    final db = await DatabaseHelper.database;
    final dateStr = DateHelper.formatDate(date);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habit_logs WHERE habit_id = ? AND date = ? AND is_completed = 1',
      [habitId, dateStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<HabitLogEntity>> getHabitLogs(String habitId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => HabitLogModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<HabitLogEntity>> getLogsByDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date >= ? AND date <= ?',
      whereArgs: [
        habitId,
        DateHelper.formatDate(start),
        DateHelper.formatDate(end),
      ],
      orderBy: 'date ASC',
    );
    return maps.map((m) => HabitLogModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<Map<DateTime, bool>> getCompletionStatus(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final logs = await getLogsByDateRange(habitId, start, end);
    final status = <DateTime, bool>{};
    for (final log in logs) {
      status[DateTime(log.date.year, log.date.month, log.date.day)] =
          log.isCompleted;
    }
    return status;
  }

  @override
  Future<int> getCurrentStreak(String habitId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT current_streak FROM habits WHERE id = ?',
      [habitId],
    );
    if (result.isEmpty) return 0;
    return result.first['current_streak'] as int? ?? 0;
  }

  @override
  Future<int> getBestStreak(String habitId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT best_streak FROM habits WHERE id = ?',
      [habitId],
    );
    if (result.isEmpty) return 0;
    return result.first['best_streak'] as int? ?? 0;
  }

  @override
  Future<double> getCompletionRate(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final days = DateHelper.daysBetween(start, end) + 1;
    if (days <= 0) return 0;

    final logs = await getLogsByDateRange(habitId, start, end);
    final completedDays = logs.where((l) => l.isCompleted).length;

    return completedDays / days;
  }

  @override
  Future<int> getTotalCompletions(String habitId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habit_logs WHERE habit_id = ? AND is_completed = 1',
      [habitId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<Map<DateTime, int>> getDailyCompletions(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT hl.date, COUNT(DISTINCT hl.habit_id) as count
      FROM habit_logs hl
      INNER JOIN habits h ON h.id = hl.habit_id
      WHERE h.user_id = ? AND hl.date >= ? AND hl.date <= ? AND hl.is_completed = 1
      GROUP BY hl.date
      ORDER BY hl.date ASC
    ''', [
      userId,
      DateHelper.formatDate(start),
      DateHelper.formatDate(end),
    ]);
    final result = <DateTime, int>{};
    for (final map in maps) {
      final date = DateTime.parse(map['date'] as String);
      result[DateTime(date.year, date.month, date.day)] =
          (map['count'] as int?) ?? 0;
    }
    return result;
  }

  @override
  Future<Map<String, int>> getCompletionsByCategory(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT h.category, COUNT(DISTINCT hl.habit_id) as count
      FROM habit_logs hl
      INNER JOIN habits h ON h.id = hl.habit_id
      WHERE h.user_id = ? AND hl.date >= ? AND hl.date <= ? AND hl.is_completed = 1
      GROUP BY h.category
      ORDER BY count DESC
    ''', [
      userId,
      DateHelper.formatDate(start),
      DateHelper.formatDate(end),
    ]);
    final result = <String, int>{};
    for (final map in maps) {
      result[map['category'] as String] = (map['count'] as int?) ?? 0;
    }
    return result;
  }

  @override
  Future<Map<int, int>> getWeekdayDistribution(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT hl.date, COUNT(DISTINCT hl.habit_id) as count
      FROM habit_logs hl
      INNER JOIN habits h ON h.id = hl.habit_id
      WHERE h.user_id = ? AND hl.date >= ? AND hl.date <= ? AND hl.is_completed = 1
      GROUP BY hl.date
    ''', [
      userId,
      DateHelper.formatDate(start),
      DateHelper.formatDate(end),
    ]);
    final weekdayTotals = <int, int>{};
    for (final map in maps) {
      final date = DateTime.parse(map['date'] as String);
      final wd = date.weekday;
      weekdayTotals[wd] =
          (weekdayTotals[wd] ?? 0) + ((map['count'] as int?) ?? 0);
    }
    return weekdayTotals;
  }

  @override
  Future<Map<String, dynamic>> getGoalProgress(String habitId) async {
    final db = await DatabaseHelper.database;
    final habitResult = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [habitId],
    );
    if (habitResult.isEmpty) {
      return {'completed': 0, 'target': 0, 'days': 0};
    }
    final habit = HabitModel.fromMap(habitResult.first).toEntity();
    final target = habit.goalTarget ?? 0;
    final days = habit.goalDays ?? 0;
    if (target <= 0 || days <= 0) {
      return {'completed': 0, 'target': 0, 'days': 0};
    }
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final count = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habit_logs WHERE habit_id = ? AND date >= ? AND date <= ? AND is_completed = 1',
      [habitId, DateHelper.formatDate(start), DateHelper.formatDate(end)],
    );
    final completed = Sqflite.firstIntValue(count) ?? 0;
    return {
      'completed': completed,
      'target': target,
      'days': days,
    };
  }

  Future<void> _updateStreaks(String habitId) async {
    final db = await DatabaseHelper.database;
    final logs = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND is_completed = 1',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );

    int currentStreak = 0;
    int bestStreak = 0;
    final today = DateHelper.today();
    var checkDate = today;

    for (final log in logs) {
      final logDate = DateTime.parse(log['date'] as String);
      if (DateHelper.isSameDay(logDate, checkDate) ||
          DateHelper.isSameDay(logDate, checkDate.subtract(const Duration(days: 1)))) {
        currentStreak++;
        checkDate = logDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final habitResult = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (habitResult.isNotEmpty) {
      bestStreak = habitResult.first['best_streak'] as int? ?? 0;
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    await db.update(
      'habits',
      {
        'current_streak': currentStreak,
        'best_streak': bestStreak,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
}

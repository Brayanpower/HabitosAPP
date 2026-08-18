import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';
import 'package:habitos_app/domain/datasources/habit_datasource.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:habitos_app/infrastructure/models/habit_log_model.dart';
import 'package:habitos_app/infrastructure/models/habit_model.dart';
import 'package:habitos_app/config/helpers/firebase_error_helper.dart';

class HabitFirestoreDatasource implements HabitDatasource {
  final FirebaseFirestore _firestore;

  HabitFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _habits =>
      _firestore.collection('habits');

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('habit_logs');

  @override
  Future<List<HabitEntity>> getHabits(String userId) async {
    final snapshot = await _habits
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs
        .map((d) => HabitModel.fromMap({...d.data(), 'id': d.id}).toEntity())
        .toList();
  }

  @override
  Future<HabitEntity> getHabitById(String id) async {
    final doc = await _habits.doc(id).get();
    if (!doc.exists) throw Exception('Hábito no encontrado');
    return HabitModel.fromMap({...doc.data()!, 'id': doc.id}).toEntity();
  }

  @override
  Future<HabitEntity> createHabit(HabitEntity habit) async {
    try {
      await _habits
          .doc(habit.id)
          .set(HabitModel.fromEntity(habit).toMap());
      return habit;
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<HabitEntity> updateHabit(HabitEntity habit) async {
    try {
      await _habits
          .doc(habit.id)
          .set(HabitModel.fromEntity(habit).toMap(), SetOptions(merge: true));
      return habit;
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    try {
      final logs = await _logs.where('habit_id', isEqualTo: id).get();
      final batch = _firestore.batch();
      for (final doc in logs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_habits.doc(id));
      await batch.commit();
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<void> logHabit(String habitId, DateTime date) async {
    try {
      final userId = await _userIdForHabit(habitId);
      await _logs.add({
        'habit_id': habitId,
        'user_id': userId,
        'date': DateHelper.formatDate(date),
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
      await _updateStreaks(habitId);
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<void> unlogHabit(String habitId, DateTime date) async {
    try {
      final snapshot = await _logs
          .where('habit_id', isEqualTo: habitId)
          .where('date', isEqualTo: DateHelper.formatDate(date))
          .where('is_completed', isEqualTo: 1)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }
      await _updateStreaks(habitId);
    } catch (e) {
      throw Exception(FirebaseErrorHelper.translate(e));
    }
  }

  @override
  Future<bool> isHabitCompletedOnDate(String habitId, DateTime date) async {
    final count = await getCountForDate(habitId, date);
    return count > 0;
  }

  @override
  Future<int> getCountForDate(String habitId, DateTime date) async {
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .where('date', isEqualTo: DateHelper.formatDate(date))
        .where('is_completed', isEqualTo: 1)
        .get();
    return snapshot.docs.length;
  }

  @override
  Future<List<HabitLogEntity>> getHabitLogs(String habitId) async {
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .get();
    return _logsFromSnapshot(snapshot);
  }

  @override
  Future<List<HabitLogEntity>> getLogsByDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: DateHelper.formatDate(start))
        .where('date', isLessThanOrEqualTo: DateHelper.formatDate(end))
        .orderBy('date')
        .get();
    return _logsFromSnapshot(snapshot);
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
    final doc = await _habits.doc(habitId).get();
    if (!doc.exists) return 0;
    return doc.data()!['current_streak'] as int? ?? 0;
  }

  @override
  Future<int> getBestStreak(String habitId) async {
    final doc = await _habits.doc(habitId).get();
    if (!doc.exists) return 0;
    return doc.data()!['best_streak'] as int? ?? 0;
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
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .where('is_completed', isEqualTo: 1)
        .get();
    return snapshot.docs.length;
  }

  @override
  Future<Map<DateTime, int>> getDailyCompletions(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _logs
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateHelper.formatDate(start))
        .where('date', isLessThanOrEqualTo: DateHelper.formatDate(end))
        .orderBy('date')
        .get();

    final byDate = <String, Set<String>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['is_completed'] as int? ?? 1) != 1) continue;
      byDate
          .putIfAbsent(data['date'] as String, () => {})
          .add(data['habit_id'] as String);
    }

    final result = <DateTime, int>{};
    byDate.forEach((dateStr, habitIds) {
      final date = DateTime.parse(dateStr);
      result[DateTime(date.year, date.month, date.day)] = habitIds.length;
    });
    return result;
  }

  @override
  Future<Map<String, int>> getCompletionsByCategory(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final habitsSnapshot =
        await _habits.where('user_id', isEqualTo: userId).get();
    final categoryByHabit = <String, String>{
      for (final d in habitsSnapshot.docs)
        d.id: (d.data()['category'] as String? ?? 'otro'),
    };

    final snapshot = await _logs
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateHelper.formatDate(start))
        .where('date', isLessThanOrEqualTo: DateHelper.formatDate(end))
        .get();

    final byCategory = <String, Set<String>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['is_completed'] as int? ?? 1) != 1) continue;
      final habitId = data['habit_id'] as String;
      final category = categoryByHabit[habitId] ?? 'otro';
      byCategory.putIfAbsent(category, () => {}).add(habitId);
    }

    final result = <String, int>{};
    byCategory.forEach((category, habitIds) {
      result[category] = habitIds.length;
    });
    return result;
  }

  @override
  Future<Map<int, int>> getWeekdayDistribution(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _logs
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: DateHelper.formatDate(start))
        .where('date', isLessThanOrEqualTo: DateHelper.formatDate(end))
        .get();

    final byDate = <String, Set<String>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['is_completed'] as int? ?? 1) != 1) continue;
      byDate
          .putIfAbsent(data['date'] as String, () => {})
          .add(data['habit_id'] as String);
    }

    final weekdayTotals = <int, int>{};
    byDate.forEach((dateStr, habitIds) {
      final date = DateTime.parse(dateStr);
      weekdayTotals[date.weekday] =
          (weekdayTotals[date.weekday] ?? 0) + habitIds.length;
    });
    return weekdayTotals;
  }

  @override
  Future<Map<String, dynamic>> getGoalProgress(String habitId) async {
    final habitDoc = await _habits.doc(habitId).get();
    if (!habitDoc.exists) {
      return {'completed': 0, 'target': 0, 'days': 0};
    }
    final habit = HabitModel.fromMap({...habitDoc.data()!, 'id': habitDoc.id})
        .toEntity();
    final target = habit.goalTarget ?? 0;
    final days = habit.goalDays ?? 0;
    if (target <= 0 || days <= 0) {
      return {'completed': 0, 'target': 0, 'days': 0};
    }

    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: DateHelper.formatDate(start))
        .where('date', isLessThanOrEqualTo: DateHelper.formatDate(end))
        .where('is_completed', isEqualTo: 1)
        .get();

    return {
      'completed': snapshot.docs.length,
      'target': target,
      'days': days,
    };
  }

  Future<String> _userIdForHabit(String habitId) async {
    final doc = await _habits.doc(habitId).get();
    if (!doc.exists) throw Exception('Hábito no encontrado');
    return doc.data()!['user_id'] as String;
  }

  Future<void> _updateStreaks(String habitId) async {
    final snapshot = await _logs
        .where('habit_id', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .get();

    int currentStreak = 0;
    final today = DateHelper.today();
    var checkDate = today;

    for (final doc in snapshot.docs) {
      final logDate = DateTime.parse(doc.data()['date'] as String);
      if (DateHelper.isSameDay(logDate, checkDate) ||
          DateHelper.isSameDay(
              logDate, checkDate.subtract(const Duration(days: 1)))) {
        currentStreak++;
        checkDate = logDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final habitDoc = await _habits.doc(habitId).get();
    if (!habitDoc.exists) return;
    final bestStreak = habitDoc.data()!['best_streak'] as int? ?? 0;

    await _habits.doc(habitId).update({
      'current_streak': currentStreak,
      'best_streak': currentStreak > bestStreak ? currentStreak : bestStreak,
    });
  }

  List<HabitLogEntity> _logsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((d) {
      final data = {...d.data(), 'id': d.id};
      return HabitLogModel.fromMap(data).toEntity();
    }).toList();
  }
}
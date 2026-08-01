import 'package:flutter/foundation.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';
import 'package:habitos_app/config/helpers/notification_helper.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/domain/entities/habit_log_entity.dart';
import 'package:habitos_app/domain/repositories/habit_repository.dart';

enum HabitStatus { initial, loading, loaded, error }

class HabitProvider extends ChangeNotifier {
  final HabitRepository _habitRepository;

  HabitProvider({required HabitRepository habitRepository})
      : _habitRepository = habitRepository;

  HabitStatus _status = HabitStatus.initial;
  List<HabitEntity> _habits = [];
  HabitEntity? _selectedHabit;
  List<HabitLogEntity> _logs = [];
  String? _error;
  String? _userId;

  HabitStatus get status => _status;
  List<HabitEntity> get habits => _habits;
  HabitEntity? get selectedHabit => _selectedHabit;
  List<HabitLogEntity> get logs => _logs;
  String? get error => _error;

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> loadHabits() async {
    if (_userId == null) return;
    _status = HabitStatus.loading;
    notifyListeners();

    try {
      _habits = await _habitRepository.getHabits(_userId!);
      _status = HabitStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = HabitStatus.error;
    }
    notifyListeners();
  }

  Future<void> createHabit(HabitEntity habit) async {
    try {
      await _habitRepository.createHabit(habit);
      await loadHabits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHabit(HabitEntity habit) async {
    try {
      await _habitRepository.updateHabit(habit);
      await loadHabits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _habitRepository.deleteHabit(id);
      await loadHabits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleHabit(String habitId, DateTime date, {String? habitName}) async {
    final isCompleted = await _habitRepository.isHabitCompletedOnDate(
      habitId,
      date,
    );

    if (isCompleted) {
      await _habitRepository.unlogHabit(habitId, date);
    } else {
      await _habitRepository.logHabit(habitId, date);
      if (habitName != null && habitName.isNotEmpty) {
        NotificationHelper.showHabitCompletedNotification(
          habitName: habitName,
          message: '¡Excelente! Has cumplido "$habitName".',
        );
      }
    }

    await loadHabits();
  }

  /// Completa un hábito de tipo Temporizador
  Future<void> completeTimerHabit(
    String habitId,
    DateTime date, {
    required String habitName,
    required int minutes,
  }) async {
    final isCompleted = await _habitRepository.isHabitCompletedOnDate(habitId, date);
    if (!isCompleted) {
      await _habitRepository.logHabit(habitId, date);
      await NotificationHelper.showTimerCompletedNotification(
        habitName: habitName,
        minutes: minutes,
      );
      await loadHabits();
    }
  }

  /// Añade una toma de agua (+250ml o por vaso)
  Future<void> addWaterIntake(
    String habitId,
    DateTime date, {
    int amountMl = 250,
    required int targetMl,
    required String habitName,
  }) async {
    await _habitRepository.logHabit(habitId, date);
    final count = await _habitRepository.getCountForDate(habitId, date);
    final totalMl = count * amountMl;

    if (totalMl >= targetMl) {
      await NotificationHelper.showWaterGoalReachedNotification(targetMl: targetMl);
    } else {
      await NotificationHelper.showImmediate(
        id: 8820,
        title: '¡Vaso de agua registrado! 💧',
        body: 'Llevas ${totalMl}ml de tu meta de ${targetMl}ml ($count vasos).',
      );
    }
    await loadHabits();
  }

  /// Completa el hábito de pasos cuando el sensor alcanza la meta
  Future<void> completeStepHabit(
    String habitId,
    DateTime date, {
    required int steps,
    required String habitName,
  }) async {
    final isCompleted = await _habitRepository.isHabitCompletedOnDate(habitId, date);
    if (!isCompleted) {
      await _habitRepository.logHabit(habitId, date);
      await NotificationHelper.showStepGoalReachedNotification(steps: steps);
      await loadHabits();
    }
  }

  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    return _habitRepository.isHabitCompletedOnDate(habitId, date);
  }

  Future<int> getCountForDate(String habitId, DateTime date) async {
    return _habitRepository.getCountForDate(habitId, date);
  }

  Future<Map<DateTime, bool>> getCompletionStatus(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    return _habitRepository.getCompletionStatus(habitId, start, end);
  }

  Future<int> getStreak(String habitId) async {
    return _habitRepository.getCurrentStreak(habitId);
  }

  Future<int> getBestStreak(String habitId) async {
    return _habitRepository.getBestStreak(habitId);
  }

  Future<double> getCompletionRate(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    return _habitRepository.getCompletionRate(habitId, start, end);
  }

  Future<int> getTotalCompletions(String habitId) async {
    return _habitRepository.getTotalCompletions(habitId);
  }

  Future<void> loadLogs(String habitId) async {
    _logs = await _habitRepository.getHabitLogs(habitId);
    notifyListeners();
  }

  void selectHabit(HabitEntity? habit) {
    _selectedHabit = habit;
    notifyListeners();
  }

  List<HabitEntity> get todaysHabits {
    final now = DateTime.now();
    return _habits.where((h) => h.isScheduledForDate(now)).toList();
  }

  List<HabitEntity> getHabitsForDate(DateTime date) {
    return _habits.where((h) => h.isScheduledForDate(date)).toList();
  }

  int get totalActiveHabits => _habits.where((h) => h.isActive).length;
  int get totalHabits => _habits.length;

  int get currentOverallStreak {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.currentStreak).fold(0, (max, s) => s > max ? s : max);
  }

  int get bestOverallStreak {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.bestStreak).fold(0, (max, s) => s > max ? s : max);
  }

  Future<void> addHabitFromTemplate(dynamic template, {double? userWeight}) async {
    if (_userId == null) return;
    final habit = template.toEntity(_userId!, userWeight: userWeight);
    await createHabit(habit);
  }

  Future<int> getCompletedTodayCount() async {
    final today = DateHelper.today();
    int count = 0;
    for (final habit in _habits.where((h) => h.isActive)) {
      if (await _habitRepository.isHabitCompletedOnDate(habit.id, today)) {
        count++;
      }
    }
    return count;
  }

  Future<int> getCompletedOnDateCount(DateTime date) async {
    final dayOnly = DateTime(date.year, date.month, date.day);
    int count = 0;
    for (final habit in getHabitsForDate(date)) {
      if (await _habitRepository.isHabitCompletedOnDate(habit.id, dayOnly)) {
        count++;
      }
    }
    return count;
  }

  Future<Map<DateTime, int>> getDailyCompletions(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return {};
    return _habitRepository.getDailyCompletions(_userId!, start, end);
  }

  Future<Map<String, int>> getCompletionsByCategory(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return {};
    return _habitRepository.getCompletionsByCategory(_userId!, start, end);
  }

  Future<Map<int, int>> getWeekdayDistribution(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return {};
    return _habitRepository.getWeekdayDistribution(_userId!, start, end);
  }

  Future<Map<String, dynamic>> getGoalProgress(String habitId) async {
    return _habitRepository.getGoalProgress(habitId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

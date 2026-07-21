import 'package:flutter/foundation.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';
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

  Future<void> toggleHabit(String habitId, DateTime date) async {
    final isCompleted = await _habitRepository.isHabitCompletedOnDate(
      habitId,
      date,
    );

    if (isCompleted) {
      await _habitRepository.unlogHabit(habitId, date);
    } else {
      await _habitRepository.logHabit(habitId, date);
    }

    await loadHabits();
  }

  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    return _habitRepository.isHabitCompletedOnDate(habitId, date);
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
    return _habits.where((h) => h.isActive).toList();
  }

  int get totalActiveHabits => _habits.where((h) => h.isActive).length;
  int get totalHabits => _habits.length;

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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime month;
  final List<HabitEntity> habits;
  final HabitProvider habitProvider;

  const CalendarWidget({
    super.key,
    required this.month,
    required this.habits,
    required this.habitProvider,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  Map<int, double> _intensity = {};
  Map<int, Map<String, int>> _dailyCounts = {};
  int _progressDays = 0;
  int _totalDays = 0;
  List<List<int>> _streakRuns = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final start = DateTime(widget.month.year, widget.month.month, 1);
    final end = DateTime(widget.month.year, widget.month.month + 1, 0);
    final daysInMonth = end.day;
    final activeHabits = widget.habits.where((h) => h.isActive).toList();
    final provider = widget.habitProvider;

    final dailyStatus = <int, Map<String, int>>{};
    final counts = <int, int>{};
    final totalHabits = <int, int>{};

    for (final habit in activeHabits) {
      final status = await provider.getCompletionStatus(
        habit.id,
        start,
        end,
      );
      for (final entry in status.entries) {
        final day = entry.key.day;
        if (!_isDayAllowed(habit, entry.key.weekday)) continue;
        if (entry.value) {
          final count = await provider.getCountForDate(
            habit.id,
            entry.key,
          );
          dailyStatus.putIfAbsent(day, () => {});
          dailyStatus[day]![habit.id] = count;
          counts[day] = (counts[day] ?? 0) + 1;
          totalHabits[day] = (totalHabits[day] ?? 0);
        }
      }
    }

    for (final habit in activeHabits) {
      for (var day = 1; day <= daysInMonth; day++) {
        final date = DateTime(
          widget.month.year, widget.month.month, day,
        );
        if (_isDayAllowed(habit, date.weekday)) {
          totalHabits[day] = (totalHabits[day] ?? 0) + 1;
        }
      }
    }

    final intensity = <int, double>{};
    int progressDays = 0;

    for (var day = 1; day <= daysInMonth; day++) {
      final completed = counts[day] ?? 0;
      final total = totalHabits[day] ?? 0;
      final ratio = total > 0 ? completed / total : 0.0;
      intensity[day] = ratio;
      dailyStatus.putIfAbsent(day, () => {});
      if (completed > 0) progressDays++;
    }

    final streakRuns = _detectStreaks(counts, daysInMonth);

    if (mounted) {
      setState(() {
        _intensity = intensity;
        _dailyCounts = dailyStatus;
        _progressDays = progressDays;
        _totalDays = daysInMonth;
        _streakRuns = streakRuns;
      });
    }
  }

  bool _isDayAllowed(HabitEntity habit, int weekday) {
    if (!habit.hasCustomDays) return true;
    return habit.repeatDays.contains(weekday);
  }

  List<List<int>> _detectStreaks(Map<int, int> counts, int daysInMonth) {
    final runs = <List<int>>[];
    List<int>? current;
    for (var day = 1; day <= daysInMonth; day++) {
      if ((counts[day] ?? 0) > 0) {
        current ??= [];
        current.add(day);
      } else {
        if (current != null && current.length >= 2) {
          runs.add(current);
        }
        current = null;
      }
    }
    if (current != null && current.length >= 2) {
      runs.add(current);
    }
    return runs;
  }

  bool _isInStreak(int day) {
    for (final run in _streakRuns) {
      if (run.contains(day) && run.length >= 2) return true;
    }
    return false;
  }

  Color _heatmapColor(double ratio) {
    if (ratio <= 0) return AppTheme.borderLight.withValues(alpha: 0.3);
    if (ratio < 0.25) return const Color(0xFFC8E6C9);
    if (ratio < 0.5) return const Color(0xFF81C784);
    if (ratio < 0.75) return const Color(0xFF4CAF50);
    return const Color(0xFF2E7D32);
  }

  void _showDayDetail(int day) {
    final statusMap = _dailyCounts[day] ?? {};
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final date = DateTime(
          widget.month.year,
          widget.month.month,
          day,
        );
        final dayName = DateHelper.weekdayName(date);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$dayName ${date.day} de ${DateHelper.monthName(date)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.habits.where((h) => h.isActive).where((h) {
                final date = DateTime(widget.month.year, widget.month.month, day);
                return _isDayAllowed(h, date.weekday);
              }).map((habit) {
                final count = statusMap[habit.id] ?? 0;
                final done = count > 0;
                return ListTile(
                  leading: Icon(
                    done ? Icons.check_circle : Icons.cancel_outlined,
                    color: done ? AppTheme.success : AppTheme.error,
                    size: 28,
                  ),
                  title: Text(habit.name),
                  trailing: done && habit.isMultiTimes
                      ? Text(
                          '×$count',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                  dense: true,
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = DateHelper.getCurrentMonthDays(widget.month);
    final firstWeekday =
        DateTime(widget.month.year, widget.month.month, 1).weekday;
    final daysInMonth = days.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeekdayHeader(context),
            const SizedBox(height: 8),
            _buildDaysGrid(days, firstWeekday, daysInMonth),
            const SizedBox(height: 12),
            _buildSummary(context),
            const SizedBox(height: 8),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.today,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          '$_progressDays/$_totalDays días con progreso',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        if (_streakRuns.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 4),
              Text(
                'Racha: ${_streakRuns.last.length} días',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('0', AppTheme.borderLight.withValues(alpha: 0.3)),
        _legendItem('25%', const Color(0xFFC8E6C9)),
        _legendItem('50%', const Color(0xFF81C784)),
        _legendItem('75%', const Color(0xFF4CAF50)),
        _legendItem('100%', const Color(0xFF2E7D32)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: color == AppTheme.borderLight.withValues(alpha: 0.3)
                  ? Border.all(color: AppTheme.borderLight)
                  : null,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(BuildContext context) {
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 36,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid(
    List<DateTime> days,
    int firstWeekday,
    int daysInMonth,
  ) {
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (final day in days) {
      final dayNum = day.day;
      final ratio = _intensity[dayNum] ?? 0.0;
      final isToday = DateHelper.isToday(day);
      final inStreak = _isInStreak(dayNum);

      cells.add(
        GestureDetector(
          onTap: () => _showDayDetail(dayNum),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? null : _heatmapColor(ratio),
              border: isToday
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : inStreak
                      ? Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : null,
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isToday || (ratio > 0.5) ? FontWeight.bold : null,
                      color: ratio > 0.5 ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: cells,
    );
  }
}

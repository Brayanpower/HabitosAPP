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
  Map<String, Set<int>> _completedDates = {};

  @override
  void initState() {
    super.initState();
    _loadCompletionData();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
      _loadCompletionData();
    }
  }

  Future<void> _loadCompletionData() async {
    final start = DateTime(widget.month.year, widget.month.month, 1);
    final end = DateTime(widget.month.year, widget.month.month + 1, 0);
    final data = <String, Set<int>>{};

    for (final habit in widget.habits.where((h) => h.isActive)) {
      final status = await widget.habitProvider.getCompletionStatus(
        habit.id,
        start,
        end,
      );
      final days = status.entries
          .where((e) => e.value)
          .map((e) => e.key.day)
          .toSet();
      if (days.isNotEmpty) {
        data[habit.id] = days;
      }
    }

    if (mounted) {
      setState(() => _completedDates = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = DateHelper.getCurrentMonthDays(widget.month);
    final firstWeekday = DateTime(widget.month.year, widget.month.month, 1)
        .weekday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeekdayHeader(context),
            const SizedBox(height: 8),
            _buildDaysGrid(days, firstWeekday),
          ],
        ),
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

  Widget _buildDaysGrid(List<DateTime> days, int firstWeekday) {
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    for (final day in days) {
      final totalCompleted = _completedDates.values
          .where((s) => s.contains(day.day))
          .length;
      final totalHabits =
          widget.habits.where((h) => h.isActive).length;
      final isAllCompleted =
          totalHabits > 0 && totalCompleted >= totalHabits;
      final isPartiallyCompleted = totalCompleted > 0 && !isAllCompleted;
      final isToday = DateHelper.isToday(day);

      cells.add(
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : null,
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAllCompleted
                    ? AppTheme.primaryColor
                    : isPartiallyCompleted
                        ? AppTheme.primaryColor.withValues(alpha: 0.4)
                        : null,
                border: isToday
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isAllCompleted
                        ? Colors.white
                        : isPartiallyCompleted
                            ? Colors.white
                            : null,
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

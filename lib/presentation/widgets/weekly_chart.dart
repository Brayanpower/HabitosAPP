import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';

class WeeklyChart extends StatefulWidget {
  final HabitProvider habitProvider;
  final List<HabitEntity> habits;

  const WeeklyChart({
    super.key,
    required this.habitProvider,
    required this.habits,
  });

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  Map<String, List<int>> _weeklyData = {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final now = DateTime.now();
    final weekDays = DateHelper.getWeekDays(now);
    final start = weekDays.first;
    final end = weekDays.last;

    final data = <String, List<int>>{};

    for (final habit in widget.habits) {
      final status = await widget.habitProvider.getCompletionStatus(
        habit.id,
        start,
        end,
      );
      final days = List.generate(7, (i) {
        final date = weekDays[i];
        return status[DateTime(date.year, date.month, date.day)] == true
            ? 1
            : 0;
      });
      data[habit.id] = days;
    }

    if (mounted) {
      setState(() => _weeklyData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_weeklyData.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos esta semana',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final totalCompletions = List.generate(7, (i) {
      int sum = 0;
      for (final days in _weeklyData.values) {
        sum += days[i];
      }
      return sum;
    });

    final maxY = widget.habits.length.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LegendItem(
                  color: AppTheme.primaryColor,
                  label: 'Completados',
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  label: 'Pendientes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} hábitos',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.borderLight,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  barGroups: List.generate(7, (i) {
                    final completed = totalCompletions[i];
                    final pending = widget.habits.length - completed;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: completed.toDouble(),
                          color: AppTheme.primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        if (pending > 0)
                          BarChartRodData(
                            toY: pending.toDouble(),
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habitos_app/config/config.dart';

class TrendLineChart extends StatelessWidget {
  final Map<DateTime, int> dailyCompletions;
  final int totalHabits;

  const TrendLineChart({
    super.key,
    required this.dailyCompletions,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    if (totalHabits == 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final days = List.generate(30, (i) {
      return DateTime(now.year, now.month, now.day).subtract(
        Duration(days: 29 - i),
      );
    });

    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final completed = dailyCompletions[days[i]] ?? 0;
      final rate = totalHabits > 0 ? completed / totalHabits : 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia 30 días',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final day = days[spot.spotIndex];
                          final completed = dailyCompletions[day] ?? 0;
                          return LineTooltipItem(
                            '${day.day}/${day.month}: '
                            '$completed/$totalHabits '
                            '(${(spot.y * 100).toInt()}%)',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
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
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            final d = days[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${d.day}/${d.month}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textSecondary,
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
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.borderLight,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppTheme.primaryColor,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: spots.length <= 15,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 2,
                            color: AppTheme.primaryColor,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

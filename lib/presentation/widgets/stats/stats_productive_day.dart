import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habitos_app/config/config.dart';

class ProductiveWeekdayCard extends StatelessWidget {
  final Map<int, int> weekdayData;

  const ProductiveWeekdayCard({super.key, required this.weekdayData});

  static const _weekdayNames = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    if (weekdayData.isEmpty) return const SizedBox.shrink();

    final maxValue = weekdayData.values.fold(0, (a, b) => a > b ? a : b);
    final mostProductive = weekdayData.entries
        .fold<int?>(null, (prev, e) {
          if (prev == null || e.value > (weekdayData[prev] ?? 0)) return e.key;
          return prev;
        });
    final bestDay = mostProductive != null
        ? _weekdayNames[mostProductive - 1]
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Día más productivo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$bestDay — $maxValue hábitos completados',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxValue + 1).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final wd = group.x + 1;
                        final name = _weekdayNames[group.x];
                        final val = weekdayData[wd] ?? 0;
                        return BarTooltipItem(
                          '$name: $val hábitos',
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
                        reservedSize: 24,
                        interval: 1,
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
                          final index = value.toInt();
                          if (index >= 0 && index < _weekdayNames.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _weekdayNames[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: (index + 1) == mostProductive
                                      ? AppTheme.primaryColor
                                      : null,
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
                    final wd = i + 1;
                    final value = weekdayData[wd] ?? 0;
                    final isBest = wd == mostProductive;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        color: isBest
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ]);
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

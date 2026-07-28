import 'package:flutter/material.dart';
import 'package:habitos_app/config/config.dart';

class MonthComparisonCard extends StatelessWidget {
  final double currentMonthRate;
  final double previousMonthRate;

  const MonthComparisonCard({
    super.key,
    required this.currentMonthRate,
    required this.previousMonthRate,
  });

  @override
  Widget build(BuildContext context) {
    final change = previousMonthRate > 0
        ? ((currentMonthRate - previousMonthRate) / previousMonthRate * 100)
        : (currentMonthRate > 0 ? 100.0 : 0.0);
    final isUp = change >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativa mensual',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MonthRate(
                    label: 'Mes actual',
                    rate: currentMonthRate,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MonthRate(
                    label: 'Mes anterior',
                    rate: previousMonthRate,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (isUp ? AppTheme.success : AppTheme.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.trending_up : Icons.trending_down,
                        color: isUp ? AppTheme.success : AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUp ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthRate extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;

  const _MonthRate({
    required this.label,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(rate * 100).toInt()}%',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

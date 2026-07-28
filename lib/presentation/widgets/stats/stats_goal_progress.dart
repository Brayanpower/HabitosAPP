import 'package:flutter/material.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';

class GoalProgressCard extends StatelessWidget {
  final HabitEntity habit;
  final int completed;

  const GoalProgressCard({
    super.key,
    required this.habit,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final target = habit.goalTarget ?? 0;
    final days = habit.goalDays ?? 0;
    if (target <= 0 || days <= 0) return const SizedBox.shrink();

    final progress = (completed / target).clamp(0.0, 1.0);
    final isComplete = completed >= target;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.emoji_events : Icons.flag_outlined,
                  color: isComplete ? AppTheme.warning : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$completed/$target',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isComplete
                        ? AppTheme.success
                        : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? AppTheme.success : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$completed completados en $days días · '
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

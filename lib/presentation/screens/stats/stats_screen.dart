import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/widgets/weekly_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, _) {
          if (habitProvider.status == HabitStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeHabits =
              habitProvider.habits.where((h) => h.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(AppConstants.padding),
            children: [
              _MetricsGrid(habitProvider: habitProvider),
              const SizedBox(height: 24),
              if (activeHabits.isNotEmpty) ...[
                Text(
                  'Progreso semanal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: WeeklyChart(
                    habitProvider: habitProvider,
                    habits: activeHabits,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Detalle por hábito',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...activeHabits.map((habit) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _loadHabitStats(habitProvider, habit.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Cargando...'),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(habit.name),
                          subtitle: Text(
                            'Racha: ${data['streak']} días · Mejor: ${data['bestStreak']} · ${data['totalCompletions']} completados',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${((data['completionRate'] as double) * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Crea hábitos para ver\ntus estadísticas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadHabitStats(
    HabitProvider provider,
    String habitId,
  ) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final streak = await provider.getStreak(habitId);
    final bestStreak = await provider.getBestStreak(habitId);
    final totalCompletions = await provider.getTotalCompletions(habitId);
    final completionRate = await provider.getCompletionRate(
      habitId,
      weekAgo,
      now,
    );
    return {
      'streak': streak,
      'bestStreak': bestStreak,
      'totalCompletions': totalCompletions,
      'completionRate': completionRate,
    };
  }
}

class _MetricsGrid extends StatelessWidget {
  final HabitProvider habitProvider;

  const _MetricsGrid({required this.habitProvider});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: habitProvider.getCompletedTodayCount(),
      builder: (context, snapshot) {
        final completedToday = snapshot.data ?? 0;
        final totalHabits = habitProvider.totalActiveHabits;
        final allHabits = habitProvider.totalHabits;

        return Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline,
                label: 'Hoy',
                value: '$completedToday',
                subValue: 'de $totalHabits',
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.auto_awesome,
                label: 'Hábitos',
                value: '$allHabits',
                subValue: 'totales',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department,
                label: 'Racha',
                value: '${_getMaxStreak()}',
                subValue: 'mejor',
                color: AppTheme.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  int _getMaxStreak() {
    int maxStreak = 0;
    for (final habit in habitProvider.habits) {
      if (habit.bestStreak > maxStreak) {
        maxStreak = habit.bestStreak;
      }
    }
    return maxStreak;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              subValue,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

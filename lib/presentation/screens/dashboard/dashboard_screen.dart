import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/widgets/habit_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final habitProvider = context.read<HabitProvider>();
      if (authProvider.user != null) {
        habitProvider.setUserId(authProvider.user!.id);
        habitProvider.loadHabits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateHelper.today();
    final dayName = DateHelper.formatDayName(today);
    final formattedDate = DateHelper.formatDisplayDate(today);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              dayName[0].toUpperCase() + dayName.substring(1),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push(AppRoutes.calendar),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push(AppRoutes.stats),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Consumer2<HabitProvider, AuthProvider>(
        builder: (context, habitProvider, authProvider, _) {
          if (habitProvider.status == HabitStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final habits = habitProvider.todaysHabits;

          return RefreshIndicator(
            onRefresh: () => habitProvider.loadHabits(),
            child: Column(
              children: [
                _ProgressCard(
                  totalHabits: habits.length,
                  completedHabits: 0,
                ),
                Expanded(
                  child: habits.isEmpty
                      ? _EmptyState(
                          onCreateHabit: () =>
                              context.push(AppRoutes.habitForm),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.padding,
                          ),
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            return FutureBuilder<bool>(
                              future: habitProvider.isCompletedOnDate(
                                habit.id,
                                today,
                              ),
                              builder: (context, snapshot) {
                                final isCompleted =
                                    snapshot.data ?? false;
                                return HabitTile(
                                  habit: habit,
                                  isCompleted: isCompleted,
                                  onToggle: () => habitProvider.toggleHabit(
                                    habit.id,
                                    today,
                                  ),
                                  onTap: () {
                                    habitProvider.selectHabit(habit);
                                    context.push(
                                      '${AppRoutes.habitForm}?id=${habit.id}',
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.habitForm),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int totalHabits;
  final int completedHabits;

  const _ProgressCard({
    required this.totalHabits,
    required this.completedHabits,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppConstants.padding),
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de hoy',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedHabits / $totalHabits hábitos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(
                    AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateHabit;

  const _EmptyState({required this.onCreateHabit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay hábitos aún',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer hábito y comienza\na construir una mejor versión de ti',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateHabit,
              icon: const Icon(Icons.add),
              label: const Text('Crear hábito'),
            ),
          ],
        ),
      ),
    );
  }
}

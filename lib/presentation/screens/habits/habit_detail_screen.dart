import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  int _streak = 0;
  int _bestStreak = 0;
  int _totalCompletions = 0;
  double _completionRate = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    final hp = context.read<HabitProvider>();
    final today = DateHelper.today();
    final start = today.subtract(const Duration(days: 30));
    final habit = hp.habits.where((h) => h.id == widget.habitId).firstOrNull;
    if (habit == null) return;

    final streak = await hp.getStreak(widget.habitId);
    final best = await hp.getBestStreak(widget.habitId);
    final total = await hp.getTotalCompletions(widget.habitId);
    final rate = await hp.getCompletionRate(widget.habitId, start, today);

    if (mounted) {
      setState(() {
        _streak = streak;
        _bestStreak = best;
        _totalCompletions = total;
        _completionRate = rate;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HabitProvider>();
    final habit = hp.habits.where((h) => h.id == widget.habitId).firstOrNull;

    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        body: const Center(child: Text('Hábito no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              hp.selectHabit(habit);
              context.push('${AppRoutes.habitForm}?id=${habit.id}');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padding),
        children: [
          _HeaderCard(habit: habit),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            _StatsRow(
              streak: _streak,
              bestStreak: _bestStreak,
              totalCompletions: _totalCompletions,
              completionRate: _completionRate,
            ),
            const SizedBox(height: 24),
            Text(
              'Historial de actividad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _ActivityLog(habitId: widget.habitId),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final dynamic habit;

  const _HeaderCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(habit.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: categoryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (habit.description != null &&
                      habit.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description!,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Chip(habit.category.label, categoryColor),
                      const SizedBox(width: 8),
                      _Chip(
                        _frequencyLabel(habit.frequency),
                        AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.salud:
        return Colors.green;
      case HabitCategory.trabajo:
        return Colors.blue;
      case HabitCategory.estudio:
        return Colors.purple;
      case HabitCategory.finanzas:
        return Colors.teal;
      case HabitCategory.hogar:
        return Colors.orange;
      case HabitCategory.social:
        return Colors.pink;
      case HabitCategory.ocio:
        return Colors.amber;
      case HabitCategory.otro:
        return Colors.grey;
    }
  }

  String _frequencyLabel(HabitFrequency freq) {
    switch (freq) {
      case HabitFrequency.daily:
        return 'Diario';
      case HabitFrequency.weekly:
        return 'Semanal';
      case HabitFrequency.monthly:
        return 'Mensual';
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int totalCompletions;
  final double completionRate;

  const _StatsRow({
    required this.streak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('Racha actual', '$streak', Icons.local_fire_department, Colors.orange),
        _StatCard('Mejor racha', '$bestStreak', Icons.emoji_events, Colors.amber),
        _StatCard('Total', '$totalCompletions', Icons.check_circle, Colors.green),
        _StatCard('30 días', '${(completionRate * 100).toInt()}%', Icons.trending_up, AppTheme.primaryColor),
      ].expand((w) => [Expanded(child: w), const SizedBox(width: 8)]).toList()..removeLast(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLog extends StatefulWidget {
  final String habitId;

  const _ActivityLog({required this.habitId});

  @override
  State<_ActivityLog> createState() => _ActivityLogState();
}

class _ActivityLogState extends State<_ActivityLog> {
  Map<DateTime, bool>? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final hp = context.read<HabitProvider>();
    final start = DateHelper.today().subtract(const Duration(days: 60));
    final status = await hp.getCompletionStatus(widget.habitId, start, DateHelper.today());
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final sortedDates = _status!.keys.toList()..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return const Center(
        child: Text('No hay registros aún', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return Column(
      children: sortedDates.map((date) {
        final completed = _status![date] ?? false;
        return ListTile(
          dense: true,
          leading: Icon(
            completed ? Icons.check_circle : Icons.cancel_outlined,
            color: completed ? Colors.green : Colors.red.shade300,
          ),
          title: Text(DateHelper.formatDisplayDate(date)),
          trailing: Text(
            completed ? 'Completado' : 'No completado',
            style: TextStyle(
              fontSize: 12,
              color: completed ? Colors.green : Colors.red.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }
}

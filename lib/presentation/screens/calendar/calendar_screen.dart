import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/widgets/calendar_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _previousMonth,
          ),
          Text(
            DateHelper.formatMonth(_selectedMonth),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, _) {
          if (habitProvider.status == HabitStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.padding),
            children: [
              CalendarWidget(
                month: _selectedMonth,
                habits: habitProvider.habits,
                habitProvider: habitProvider,
              ),
              const SizedBox(height: 24),
              Text(
                'Hábitos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...habitProvider.habits.where((h) => h.isActive).map((habit) {
                return FutureBuilder<int>(
                  future: habitProvider.getStreak(habit.id),
                  builder: (context, snapshot) {
                    final streak = snapshot.data ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: streak > 0
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                        ),
                        title: Text(habit.name),
                        subtitle: streak > 0
                            ? Text('Racha: $streak días')
                            : const Text('Sin racha activa'),
                        trailing: streak > 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: AppTheme.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

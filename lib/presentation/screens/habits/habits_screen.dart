import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/providers/step_provider.dart';
import 'package:habitos_app/presentation/widgets/habit_timer_dialog.dart';
import 'package:habitos_app/presentation/widgets/template_habits_sheet.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  HabitCategory? _selectedCategory;

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habitProvider = context.watch<HabitProvider>();
    final stepProvider = context.watch<StepProvider>();

    // Filtrar estrictamente por la fecha seleccionada en el carrusel
    final allDayHabits = habitProvider.getHabitsForDate(_selectedDate);
    final filteredHabits = _selectedCategory == null
        ? allDayHabits
        : allDayHabits
            .where((h) => h.category == _selectedCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Catálogo de Hábitos',
            onPressed: () => TemplateHabitsSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nuevo Hábito',
            onPressed: () => context.push(AppRoutes.habitForm),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de fecha principal con botones < >
          _buildDateHeader(context, isDark),

          // Carrusel horizontal de días centrado en la fecha seleccionada
          _buildDayPickerStrip(context, isDark),

          // Chips de categorías
          _buildCategoryChips(isDark),

          const Divider(height: 1),

          // Lista de hábitos del día
          Expanded(
            child: habitProvider.status == HabitStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : filteredHabits.isEmpty
                    ? _buildEmptyState(context, isDark, allDayHabits.isEmpty)
                    : RefreshIndicator(
                        onRefresh: () => habitProvider.loadHabits(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: filteredHabits.length,
                          itemBuilder: (context, index) {
                            final habit = filteredHabits[index];
                            return _buildSmartHabitCard(
                              context,
                              habit,
                              habitProvider,
                              stepProvider,
                              isDark,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Hábito'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                ),
                title: const Text(
                  'Catálogo de Hábitos Saludables',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Activa agua, temporizadores, pasos o descanso'),
                onTap: () {
                  Navigator.pop(ctx);
                  TemplateHabitsSheet.show(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.create_rounded, color: AppTheme.accent),
                ),
                title: const Text(
                  'Crear Hábito Personalizado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Define temporizador, agua, pasos o metas propias'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.habitForm);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _selectedDate.isAtSameMomentAs(today);

    final dateLabel = DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Día anterior',
            onPressed: () => _changeDate(-1),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _selectDate(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel[0].toUpperCase() + dateLabel.substring(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HOY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Día siguiente',
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPickerStrip(BuildContext context, bool isDark) {
    final days = List.generate(7, (i) => _selectedDate.add(Duration(days: i - 3)));

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;

          final now = DateTime.now();
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;

          final weekdayName = DateFormat('E', 'es').format(day).toUpperCase();

          return GestureDetector(
            onTap: () => _selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : isDark
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : isToday
                          ? AppTheme.primary.withValues(alpha: 0.5)
                          : isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() => _selectedCategory = null),
            selectedColor: AppTheme.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: _selectedCategory == null
                  ? AppTheme.primary
                  : isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
              fontWeight:
                  _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          ...HabitCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.label),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedCategory = isSelected ? null : cat;
                }),
                selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSmartHabitCard(
    BuildContext context,
    HabitEntity habit,
    HabitProvider provider,
    StepProvider stepProvider,
    bool isDark,
  ) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadHabitCardState(habit, provider),
      builder: (context, snapshot) {
        final state = snapshot.data ?? {'isCompleted': false, 'count': 0};
        final isCompleted = state['isCompleted'] as bool;
        final count = state['count'] as int;

        // Si es hábito de pasos y hoy se cumplió la meta, sincronizar
        if (habit.isStepsHabit && isToday && stepProvider.todaySteps >= habit.targetValue && !isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.completeStepHabit(
              habit.id,
              _selectedDate,
              steps: stepProvider.todaySteps,
              habitName: habit.name,
            );
          });
        }

        return Dismissible(
          key: ValueKey('${habit.id}_${_selectedDate.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Eliminar hábito?'),
                content: Text('Se eliminará "${habit.name}" y todos sus registros.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => provider.deleteHabit(habit.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight,
                width: isCompleted ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                context.push('${AppRoutes.habitDetail}?id=${habit.id}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila superior: Icono de categoría/tipo, Nombre, Racha y Check
                    Row(
                      children: [
                        _buildTypeIcon(habit),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? AppTheme.textSecondary
                                      : isDark
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight,
                                ),
                              ),
                              if (habit.description != null &&
                                  habit.description!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  habit.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (habit.currentStreak > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6D00).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 14,
                                  color: Color(0xFFFF6D00),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${habit.currentStreak} d',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6D00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Checkbox rápido
                        GestureDetector(
                          onTap: () {
                            provider.toggleHabit(
                              habit.id,
                              _selectedDate,
                              habitName: habit.name,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppTheme.success
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCompleted
                                    ? AppTheme.success
                                    : AppTheme.textSecondary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Controles y visualización inteligente según tipo de hábito
                    if (habit.isStepsHabit) ...[
                      _buildStepsCardContent(
                        habit,
                        stepProvider,
                        isToday,
                        isCompleted,
                        isDark,
                      ),
                    ] else if (habit.isTimerHabit) ...[
                      _buildTimerCardContent(
                        context,
                        habit,
                        isCompleted,
                        isDark,
                      ),
                    ] else if (habit.isWaterHabit) ...[
                      _buildWaterCardContent(
                        habit,
                        count,
                        provider,
                        isCompleted,
                        isDark,
                      ),
                    ] else if (habit.targetType == HabitTargetType.counter) ...[
                      _buildCounterCardContent(
                        habit,
                        count,
                        provider,
                        isCompleted,
                        isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadHabitCardState(
    HabitEntity habit,
    HabitProvider provider,
  ) async {
    final isCompleted = await provider.isCompletedOnDate(habit.id, _selectedDate);
    final count = await provider.getCountForDate(habit.id, _selectedDate);
    return {'isCompleted': isCompleted, 'count': count};
  }

  Widget _buildTypeIcon(HabitEntity habit) {
    IconData icon;
    Color color;

    switch (habit.targetType) {
      case HabitTargetType.steps:
        icon = Icons.directions_walk_rounded;
        color = const Color(0xFF00B894);
        break;
      case HabitTargetType.timer:
        icon = Icons.timer_outlined;
        color = const Color(0xFF6C5CE7);
        break;
      case HabitTargetType.water:
        icon = Icons.water_drop_rounded;
        color = const Color(0xFF0288D1);
        break;
      case HabitTargetType.counter:
        icon = Icons.repeat_rounded;
        color = const Color(0xFFE65100);
        break;
      case HabitTargetType.simpleCheck:
        icon = Icons.check_circle_outline_rounded;
        color = AppTheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildStepsCardContent(
    HabitEntity habit,
    StepProvider stepProvider,
    bool isToday,
    bool isCompleted,
    bool isDark,
  ) {
    final target = habit.targetValue > 0 ? habit.targetValue : 8000;
    final currentSteps = isToday ? stepProvider.todaySteps : (isCompleted ? target : 0);
    final progress = (target > 0) ? (currentSteps / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    stepProvider.isSensorAvailable
                        ? Icons.sensors_rounded
                        : Icons.directions_walk_rounded,
                    size: 16,
                    color: const Color(0xFF00B894),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isToday
                        ? (stepProvider.isSensorAvailable
                            ? 'Sensor en vivo: $currentSteps / $target pasos'
                            : 'Pasos hoy: $currentSteps / $target')
                        : 'Meta: $target pasos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B894),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B894),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B894)),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stepProvider.pedestrianStatus,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF00B894),
                  ),
                  onPressed: () => stepProvider.addSimulatedSteps(500),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    '+500 pasos (Simular)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerCardContent(
    BuildContext context,
    HabitEntity habit,
    bool isCompleted,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Color(0xFF6C5CE7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Meta: ${habit.targetValue} minutos',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                Text(
                  isCompleted ? '¡Sesión de hoy completada!' : 'Inicia la cuenta regresiva guiada',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? AppTheme.success : const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              HabitTimerDialog.show(context, habit, _selectedDate);
            },
            icon: Icon(
              isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
              size: 16,
            ),
            label: Text(
              isCompleted ? 'Repetir' : 'Iniciar',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCardContent(
    HabitEntity habit,
    int count,
    HabitProvider provider,
    bool isCompleted,
    bool isDark,
  ) {
    final targetMl = habit.targetValue > 0 ? habit.targetValue : 2000;
    final currentMl = count * 250;
    final progress = (targetMl > 0) ? (currentMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0288D1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💧 $currentMl / $targetMl ml ($count vasos)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0288D1),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0288D1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0288D1)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  provider.addWaterIntake(
                    habit.id,
                    _selectedDate,
                    amountMl: 250,
                    targetMl: targetMl,
                    habitName: habit.name,
                  );
                },
                icon: const Icon(Icons.local_drink_rounded, size: 16),
                label: const Text(
                  '+250 ml (1 vaso)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCardContent(
    HabitEntity habit,
    int count,
    HabitProvider provider,
    bool isCompleted,
    bool isDark,
  ) {
    final target = habit.targetValue > 0 ? habit.targetValue : 3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Progreso: $count / $target veces',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: count > 0
                    ? () => provider.toggleHabit(habit.id, _selectedDate)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                onPressed: () {
                  provider.toggleHabit(
                    habit.id,
                    _selectedDate,
                    habitName: habit.name,
                  );
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool noHabitsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              noHabitsAtAll
                  ? 'No hay hábitos programados para este día'
                  : 'Ningún hábito coincide con el filtro',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes crear un hábito personalizado o activar hábitos saludables desde el catálogo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => TemplateHabitsSheet.show(context),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Explorar Catálogo de Hábitos'),
            ),
          ],
        ),
      ),
    );
  }
}

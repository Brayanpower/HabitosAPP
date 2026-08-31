import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final String? habitId;

  const HabitFormScreen({super.key, this.habitId});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  HabitCategory _category = HabitCategory.salud;
  HabitTargetType _targetType = HabitTargetType.simpleCheck;

  bool _hasGoal = false;
  final _goalTargetController = TextEditingController();
  final _goalDaysController = TextEditingController();
  TimeOfDay? _reminderTime;
  Set<int> _selectedDays = {};
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    if (widget.habitId != null) {
      final habitProvider = context.read<HabitProvider>();
      try {
        HabitEntity? habit = habitProvider.selectedHabit;
        if (habit == null || habit.id != widget.habitId) {
          final habits = habitProvider.habits;
          habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
        }
        if (habit != null) {
          _nameController.text = habit.name;
          _descriptionController.text = habit.description ?? '';
          _frequency = habit.frequency;
          _category = habit.category;
          _targetType = habit.targetType;
          _targetValueController.text = habit.targetValue.toString();

          if (habit.goalTarget != null) {
            _hasGoal = true;
            _goalTargetController.text = habit.goalTarget.toString();
            _goalDaysController.text = (habit.goalDays ?? 30).toString();
          }
          if (habit.reminderTime != null) {
            _reminderTime = TimeOfDay.fromDateTime(habit.reminderTime!);
          }
          _selectedDays = habit.repeatDays.toSet();
          _isEditing = true;
        }
      } catch (_) {}
    } else {
      _targetValueController.text = '1';
    }
    _isLoading = false;
    if (mounted) setState(() {});
  }

  void _onTargetTypeChanged(HabitTargetType type) {
    setState(() {
      _targetType = type;
      switch (type) {
        case HabitTargetType.timer:
          _targetValueController.text = '20';
          break;
        case HabitTargetType.water:
          _targetValueController.text = '2000';
          break;
        case HabitTargetType.steps:
          _targetValueController.text = '8000';
          break;
        case HabitTargetType.counter:
          _targetValueController.text = '3';
          break;
        case HabitTargetType.simpleCheck:
          _targetValueController.text = '1';
          break;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _goalTargetController.dispose();
    _goalDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      final exact = await NotificationHelper.hasExactAlarmPermission();
      if (!exact) {
        final granted = await NotificationHelper.requestExactAlarmPermission();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permite alarmas exactas para notificaciones puntuales'),
            ),
          );
        }
      }
      setState(() => _reminderTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final habitProvider = context.read<HabitProvider>();

    DateTime? reminderDateTime;
    if (_reminderTime != null) {
      final now = DateTime.now();
      final nowRounded = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
      if (scheduled.isBefore(nowRounded)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      reminderDateTime = scheduled;
    }

    final targetVal = int.tryParse(_targetValueController.text.trim()) ?? 1;
    final goalTarget = _hasGoal
        ? int.tryParse(_goalTargetController.text.trim())
        : null;
    final goalDays = _hasGoal
        ? int.tryParse(_goalDaysController.text.trim())
        : null;

    if (_isEditing && widget.habitId != null) {
      final habitData = habitProvider.selectedHabit;
      if (habitData == null) return;
      final updated = habitData.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        category: _category,
        targetType: _targetType,
        targetValue: targetVal,
        unit: _targetType.defaultUnit,
        goalTarget: goalTarget,
        goalDays: goalDays,
        reminderTime: reminderDateTime,
        repeatDays: _selectedDays.toList(),
      );
      await habitProvider.updateHabit(updated);
      if (reminderDateTime != null) {
        await NotificationHelper.requestNotificationPermission();
        await NotificationHelper.scheduleAlarmNotification(
          id: updated.id.hashCode.abs(),
          title: 'Recordatorio',
          body: '¡Hora de ${updated.name}!',
          scheduledDate: reminderDateTime,
        );
      } else {
        await NotificationHelper.cancelNotification(updated.id.hashCode.abs());
      }
    } else {
      final habit = HabitEntity(
        id: const Uuid().v4(),
        userId: authProvider.user!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        category: _category,
        targetType: _targetType,
        targetValue: targetVal,
        unit: _targetType.defaultUnit,
        createdAt: DateTime.now(),
        reminderTime: reminderDateTime,
        goalTarget: goalTarget,
        goalDays: goalDays,
        repeatDays: _selectedDays.toList(),
      );
      await habitProvider.createHabit(habit);
      if (reminderDateTime != null) {
        await NotificationHelper.requestNotificationPermission();
        await NotificationHelper.scheduleAlarmNotification(
          id: habit.id.hashCode.abs(),
          title: 'Recordatorio',
          body: '¡Hora de ${habit.name}!',
          scheduledDate: reminderDateTime,
        );
      }
    }

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) context.pop();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text('¿Estás seguro de eliminar "${_nameController.text.trim()}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && widget.habitId != null && mounted) {
      await context.read<HabitProvider>().deleteHabit(widget.habitId!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Hábito' : 'Nuevo Hábito'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del hábito',
                        hintText: 'Ej: Caminar, Meditar, Beber agua...',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa un nombre para el hábito';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: '¿Por qué es importante este hábito para ti?',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Tipo de Objetivo Inteligente
                    Text(
                      'Tipo de Objetivo & Medición',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige cómo se registrará el cumplimiento diario.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _TargetTypeSelector(
                      selected: _targetType,
                      onChanged: _onTargetTypeChanged,
                    ),
                    const SizedBox(height: 16),

                    // Campo de Valor según Tipo de Objetivo
                    if (_targetType != HabitTargetType.simpleCheck) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTargetFieldLabel(_targetType),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _targetValueController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: _targetType.defaultUnit,
                                prefixIcon: Icon(_getTargetFieldIcon(_targetType)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa un valor';
                                final n = int.tryParse(v.trim());
                                if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getTargetFieldHelper(_targetType),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Frecuencia
                    Text(
                      'Frecuencia',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FrequencySelector(
                      selected: _frequency,
                      onChanged: (f) {
                        setState(() {
                          if (_frequency != f) {
                            _frequency = f;
                            _selectedDays.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_frequency == HabitFrequency.monthly)
                      _MonthDaySelector(
                        selectedDays: _selectedDays,
                        onChanged: (days) => setState(() => _selectedDays = days),
                      )
                    else
                      _DaySelector(
                        selectedDays: _selectedDays,
                        isWeekly: _frequency == HabitFrequency.weekly,
                        onChanged: (days) => setState(() => _selectedDays = days),
                      ),
                    const SizedBox(height: 24),

                    // Categoría
                    Text(
                      'Categoría',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategorySelector(
                      selected: _category,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 24),

                    // Meta (opcional)
                    Text(
                      'Racha / Meta a largo plazo (opcional)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Establecer meta de días'),
                      value: _hasGoal,
                      onChanged: (v) => setState(() => _hasGoal = v ?? false),
                    ),
                    if (_hasGoal) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _goalTargetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Completar',
                                hintText: 'Ej: 25',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              validator: _hasGoal
                                  ? (v) {
                                      if (v == null || v.isEmpty) return 'Requerido';
                                      final n = int.tryParse(v);
                                      if (n == null || n <= 0) return 'Número válido';
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('veces en'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _goalDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'días',
                                hintText: 'Ej: 30',
                              ),
                              validator: _hasGoal
                                  ? (v) {
                                      if (v == null || v.isEmpty) return 'Requerido';
                                      final n = int.tryParse(v);
                                      if (n == null || n <= 0) return 'Número válido';
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Recordatorio diario
                    Text(
                      'Recordatorio diario puntual',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            const SizedBox(width: 12),
                            Text(
                              _reminderTime != null
                                  ? _reminderTime!.format(context)
                                  : 'Seleccionar hora de notificación',
                              style: TextStyle(
                                color: _reminderTime != null
                                    ? null
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (_reminderTime != null)
                              GestureDetector(
                                onTap: () => setState(() => _reminderTime = null),
                                child: const Icon(Icons.close, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        _isEditing ? 'Guardar Cambios' : 'Crear Hábito',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar hábito'),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  String _getTargetFieldLabel(HabitTargetType type) {
    switch (type) {
      case HabitTargetType.timer:
        return 'Duración diaria en minutos:';
      case HabitTargetType.water:
        return 'Meta diaria de hidratación (mililitros):';
      case HabitTargetType.steps:
        return 'Objetivo diario de pasos:';
      case HabitTargetType.counter:
        return 'Repeticiones deseadas por día:';
      case HabitTargetType.simpleCheck:
        return 'Meta';
    }
  }

  IconData _getTargetFieldIcon(HabitTargetType type) {
    switch (type) {
      case HabitTargetType.timer:
        return Icons.timer_outlined;
      case HabitTargetType.water:
        return Icons.water_drop_outlined;
      case HabitTargetType.steps:
        return Icons.directions_walk_rounded;
      case HabitTargetType.counter:
        return Icons.repeat_rounded;
      case HabitTargetType.simpleCheck:
        return Icons.check_circle_outline;
    }
  }

  String _getTargetFieldHelper(HabitTargetType type) {
    switch (type) {
      case HabitTargetType.timer:
        return 'Podrás iniciar un temporizador interactivo con cuenta regresiva para cumplirlo.';
      case HabitTargetType.water:
        return 'Podrás registrar cada toma rápidamente con un botón de +250ml (1 vaso).';
      case HabitTargetType.steps:
        return 'Se medirá automáticamente en tiempo real usando el podómetro del teléfono.';
      case HabitTargetType.counter:
        return 'Podrás aumentar el contador con botones + y - durante el día.';
      case HabitTargetType.simpleCheck:
        return '';
    }
  }
}

class _TargetTypeSelector extends StatelessWidget {
  final HabitTargetType selected;
  final ValueChanged<HabitTargetType> onChanged;

  const _TargetTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = [
      (HabitTargetType.simpleCheck, 'Check simple', Icons.check_box_outlined),
      (HabitTargetType.timer, 'Temporizador', Icons.timer_outlined),
      (HabitTargetType.water, 'Agua (ml)', Icons.water_drop_outlined),
      (HabitTargetType.steps, 'Pasos (Sensor)', Icons.directions_walk_rounded),
      (HabitTargetType.counter, 'Contador (+/-)', Icons.plus_one_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.$1 == selected;
        return ChoiceChip(
          avatar: Icon(
            opt.$3,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
          label: Text(opt.$2),
          selected: isSelected,
          onSelected: (_) => onChanged(opt.$1),
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final HabitFrequency selected;
  final ValueChanged<HabitFrequency> onChanged;

  const _FrequencySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: HabitFrequency.values.map((f) {
        final isSelected = f == selected;
        final labels = {
          HabitFrequency.daily: 'Diario',
          HabitFrequency.weekly: 'Semanal',
          HabitFrequency.monthly: 'Mensual',
        };
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: f != HabitFrequency.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  labels[f]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final bool isWeekly;
  final ValueChanged<Set<int>> onChanged;

  const _DaySelector({
    required this.selectedDays,
    this.isWeekly = false,
    required this.onChanged,
  });

  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Días de la semana',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (isWeekly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selectedDays.length}/3 días',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isWeekly
              ? 'Selecciona hasta un máximo de 3 días a la semana'
              : (selectedDays.isEmpty
                  ? 'Todos los días'
                  : 'Solo los días seleccionados'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                final updated = Set<int>.from(selectedDays);
                if (isSelected) {
                  updated.remove(day);
                } else {
                  if (isWeekly && updated.length >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Los hábitos semanales permiten hasta 3 días.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  updated.add(day);
                }
                onChanged(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _dayNames[i],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MonthDaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  const _MonthDaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Días del mes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${selectedDays.length}/3 días',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Selecciona hasta 3 días específicos del mes (ej. 1, 15, 30)',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(31, (i) {
              final dayNumber = i + 1;
              final isSelected = selectedDays.contains(dayNumber);

              return GestureDetector(
                onTap: () {
                  final updated = Set<int>.from(selectedDays);
                  if (isSelected) {
                    updated.remove(dayNumber);
                  } else {
                    if (updated.length >= 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Los hábitos mensuales permiten hasta 3 días.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    updated.add(dayNumber);
                  }
                  onChanged(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final HabitCategory selected;
  final ValueChanged<HabitCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<HabitCategory>(
      initialValue: selected,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.label_outline),
      ),
      items: HabitCategory.values.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c.label),
        );
      }).toList(),
      onChanged: (c) {
        if (c != null) onChanged(c);
      },
    );
  }
}

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
  HabitFrequency _frequency = HabitFrequency.daily;
  HabitCategory _category = HabitCategory.otro;
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
    }
    _isLoading = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
              content: Text('Ve a Ajustes > Permitir alarmas exactas para recibir notificaciones puntuales'),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recordatorio actualizado para ${DateHelper.formatTime(reminderDateTime)}',
              ),
            ),
          );
        }
      } else {
        await NotificationHelper.cancelNotification(
          updated.id.hashCode.abs(),
        );
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
        createdAt: DateTime.now(),
        reminderTime: reminderDateTime,
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recordatorio programado para ${DateHelper.formatTime(reminderDateTime)}',
              ),
            ),
          );
        }
      }
    }

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar hábito' : 'Nuevo hábito'),
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
                        hintText: 'Ej: Meditar, Leer, Ejercicio...',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: '¿Por qué quieres crear este hábito?',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Frecuencia',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _FrequencySelector(
                      selected: _frequency,
                      onChanged: (f) => setState(() => _frequency = f),
                    ),
                    const SizedBox(height: 16),
                    _DaySelector(
                      selectedDays: _selectedDays,
                      onChanged: (days) => setState(() => _selectedDays = days),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Categoría',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _CategorySelector(
                      selected: _category,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Meta (opcional)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Establecer meta'),
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
                                hintText: 'Ej: 20',
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
                    Text(
                      'Recordatorio (opcional)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                          color: Theme.of(context)
                              .inputDecorationTheme
                              .fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            const SizedBox(width: 12),
                            Text(
                              _reminderTime != null
                                  ? _reminderTime!.format(context)
                                  : 'Seleccionar hora',
                              style: TextStyle(
                                color: _reminderTime != null
                                    ? null
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (_reminderTime != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _reminderTime = null),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(
                        _isEditing ? 'Guardar cambios' : 'Crear hábito',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar hábito'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  labels[f]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
  final ValueChanged<Set<int>> onChanged;

  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días de la semana',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          selectedDays.isEmpty
              ? 'Todos los días'
              : 'Solo los días seleccionados',
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
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderLight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _dayNames[i],
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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

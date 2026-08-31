import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/domain/entities/habit_entity.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/providers/step_provider.dart';
import 'package:habitos_app/presentation/widgets/habit_timer_dialog.dart';
import 'package:habitos_app/presentation/widgets/template_habits_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToHabits;

  const DashboardScreen({
    super.key,
    this.onNavigateToProfile,
    this.onNavigateToHabits,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _completedToday = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HabitProvider>();
      if (provider.status == HabitStatus.loaded) {
        _updateCompletedCount(provider);
      }
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final habitProvider = context.read<HabitProvider>();
    if (authProvider.user != null) {
      habitProvider.setUserId(authProvider.user!.id);
      await habitProvider.loadHabits();
      await _updateCompletedCount(habitProvider);
    }
  }

  Future<void> _updateCompletedCount(HabitProvider habitProvider) async {
    final count = await habitProvider.getCompletedTodayCount();
    if (mounted) setState(() => _completedToday = count);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateHelper.today();
    final dayName = DateHelper.formatDayName(today);
    final formattedDate = DateHelper.formatDisplayDate(today);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                text: 'Vital',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
                children: const [
                  TextSpan(
                    text: 'Habit',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Catálogo de Hábitos',
            onPressed: () => TemplateHabitsSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Consumer3<HabitProvider, AuthProvider, StepProvider>(
        builder: (context, habitProvider, authProvider, stepProvider, _) {
          if (habitProvider.status == HabitStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.user;
          final todaysHabits = habitProvider.todaysHabits;
          final totalTodays = todaysHabits.length;
          final progress = totalTodays > 0 ? _completedToday / totalTodays : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              await habitProvider.loadHabits();
              await _updateCompletedCount(habitProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Saludo & Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user?.name.split(' ').first ?? 'Atleta'}! 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dayName[0].toUpperCase()}${dayName.substring(1)}, $formattedDate',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: widget.onNavigateToProfile ??
                          () => context.push(AppRoutes.profile),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hero Card: Racha Activa y Progreso del Día
                _buildHeroStreakCard(
                  context,
                  habitProvider,
                  _completedToday,
                  totalTodays,
                  progress,
                  isDark,
                ),
                const SizedBox(height: 14),

                // Widget de Podómetro en Vivo
                _buildLiveStepWidget(context, stepProvider, isDark),
                const SizedBox(height: 14),

                // Tarjeta de Salud & Biometría Resumida
                if (user != null)
                  _buildHealthQuickCard(context, user, isDark),
                const SizedBox(height: 20),

                // Encabezado de Hábitos de Hoy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hábitos de Hoy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToHabits,
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lista de Hábitos de Hoy
                if (todaysHabits.isEmpty)
                  _buildEmptyState(context, isDark)
                else
                  ...todaysHabits.map((habit) => _buildTodayHabitTile(
                        context,
                        habit,
                        habitProvider,
                        stepProvider,
                        today,
                        isDark,
                      )),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStepWidget(
    BuildContext context,
    StepProvider stepProvider,
    bool isDark,
  ) {
    final steps = stepProvider.todaySteps;
    final goal = stepProvider.stepGoal;
    final progress = stepProvider.progress;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B894).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: Color(0xFF00B894),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Podómetro Sensor Activo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B894),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$steps de $goal pasos diarios',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B894)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStreakCard(
    BuildContext context,
    HabitProvider habitProvider,
    int completed,
    int total,
    double progress,
    bool isDark,
  ) {
    final currentStreak = habitProvider.currentOverallStreak;
    final bestStreak = habitProvider.bestOverallStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF3730A3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFFB74D),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentStreak ${currentStreak == 1 ? "día" : "días"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Racha activa',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bestStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD54F),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Mejor: $bestStreak d',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Barra de progreso de hoy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso diario ($completed de $total)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E676),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthQuickCard(
    BuildContext context,
    dynamic user,
    bool isDark,
  ) {
    final bmi = user.bmi;
    final bmiCat = user.bmiCategory;
    final water = user.recommendedWaterLiters;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppTheme.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bmi != null
                      ? 'IMC: ${bmi.toStringAsFixed(1)} ($bmiCat)'
                      : 'Configura tus datos biométricos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meta sugerida de agua: ${water.toStringAsFixed(1)} L/día',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onNavigateToProfile ?? () => context.push(AppRoutes.profile),
            child: const Text('Ver perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHabitTile(
    BuildContext context,
    HabitEntity habit,
    HabitProvider provider,
    StepProvider stepProvider,
    DateTime today,
    bool isDark,
  ) {
    return FutureBuilder<bool>(
      future: provider.isCompletedOnDate(habit.id, today),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.success.withValues(alpha: 0.4)
                  : isDark
                      ? AppTheme.borderDark
                      : AppTheme.borderLight,
              width: isCompleted ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: GestureDetector(
              onTap: () async {
                await provider.toggleHabit(habit.id, today, habitName: habit.name);
                await _updateCompletedCount(provider);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.success
                        : AppTheme.textSecondary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : null,
              ),
            ),
            title: Text(
              habit.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? AppTheme.textSecondary
                    : isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              habit.isStepsHabit
                  ? 'Meta: ${habit.targetValue} pasos (Sensor)'
                  : habit.isTimerHabit
                      ? 'Meta: ${habit.targetValue} min (Temporizador)'
                      : habit.isWaterHabit
                          ? 'Meta: ${habit.targetValue} ml (Agua)'
                          : habit.category.label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: habit.isTimerHabit
                ? IconButton(
                    icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primary),
                    tooltip: 'Iniciar Temporizador',
                    onPressed: () => HabitTimerDialog.show(context, habit, today),
                  )
                : const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            onTap: () {
              context.push('${AppRoutes.habitDetail}?id=${habit.id}');
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_rtl_rounded,
            size: 48,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            '¡No tienes hábitos para hoy!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Comienza activando hábitos saludables desde el catálogo o crea uno propio.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => TemplateHabitsSheet.show(context),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Catálogo'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.push(AppRoutes.habitForm),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear Hábito'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/widgets/weekly_chart.dart';
import 'package:habitos_app/presentation/widgets/stats/stats_category_donut.dart';
import 'package:habitos_app/presentation/widgets/stats/stats_trend_chart.dart';
import 'package:habitos_app/presentation/widgets/stats/stats_comparison_card.dart';
import 'package:habitos_app/presentation/widgets/stats/stats_productive_day.dart';
import 'package:habitos_app/presentation/widgets/stats/stats_goal_progress.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers para edición de perfil
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;
  bool _isSaving = false;

  // Datos para la pestaña de estadísticas
  Map<String, int>? _categoryData;
  Map<DateTime, int>? _trendData;
  Map<int, int>? _weekdayData;
  double _currentMonthRate = 0;
  double _previousMonthRate = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserData();
      _loadStatsData();
    });
  }

  void _initUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _selectedGender = user.gender;
      _weightController.text =
          user.weight != null ? user.weight!.toStringAsFixed(1) : '';
      _heightController.text =
          user.height != null ? user.height!.toStringAsFixed(0) : '';
      _ageController.text = user.age != null ? user.age!.toString() : '';
      setState(() {});
    }
  }

  Future<void> _loadStatsData() async {
    final provider = context.read<HabitProvider>();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0);

    final trendStart = monthStart.subtract(const Duration(days: 29));
    final trendEnd = monthEnd;

    try {
      final results = await Future.wait([
        provider.getDailyCompletions(monthStart, monthEnd),
        provider.getCompletionsByCategory(monthStart, monthEnd),
        provider.getDailyCompletions(trendStart, trendEnd),
        provider.getWeekdayDistribution(monthStart, monthEnd),
        provider.getDailyCompletions(prevMonthStart, prevMonthEnd),
      ]);

      if (!mounted) return;

      final currentDaily = results[0] as Map<DateTime, int>;
      final category = results[1] as Map<String, int>;
      final trend = results[2] as Map<DateTime, int>;
      final weekday = results[3] as Map<int, int>;
      final prevDaily = results[4] as Map<DateTime, int>;

      final totalHabits = provider.totalActiveHabits;
      final currentDays = monthEnd.day;
      final prevDays = prevMonthEnd.day;

      setState(() {
        _categoryData = category;
        _trendData = trend;
        _weekdayData = weekday;
        _currentMonthRate = currentDays > 0 && totalHabits > 0
            ? currentDaily.values.fold(0, (a, b) => a + b) /
                (currentDays * totalHabits)
            : 0;
        _previousMonthRate = prevDays > 0 && totalHabits > 0
            ? prevDaily.values.fold(0, (a, b) => a + b) /
                (prevDays * totalHabits)
            : 0;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newPass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    if (newPass.isNotEmpty) {
      if (newPass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (newPass != confirmPass) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final age = int.tryParse(_ageController.text.trim());

    setState(() => _isSaving = true);

    final success = await context.read<AuthProvider>().updateProfile(
          name: name,
          password: newPass.isNotEmpty ? newPass : null,
          gender: _selectedGender,
          weight: weight,
          height: height,
          age: age,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil y datos biométricos actualizados con éxito!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().error ??
                  'Error al actualizar el perfil',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header compacto de usuario
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (user.bmi != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'IMC: ${user.bmi!.toStringAsFixed(1)} (${user.bmiCategory})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pestañas (Datos & Biometría | Estadísticas)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_pin_rounded, size: 20),
                        text: 'Datos & Biometría',
                      ),
                      Tab(
                        icon: Icon(Icons.insights_rounded, size: 20),
                        text: 'Estadísticas',
                      ),
                    ],
                  ),
                ),

                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileAndBiometricsTab(context, user, isDark),
                      _buildStatsTab(context, isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileAndBiometricsTab(
    BuildContext context,
    dynamic user,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta de Resultados de Salud (IMC & Hidratación)
        _buildHealthSummaryCard(user, isDark),
        const SizedBox(height: 16),

        // Sección: Datos de Cuenta
        _buildSectionCard(
          title: 'Información de la Cuenta',
          icon: Icons.badge_outlined,
          isDark: isDark,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.email,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico (No modificable)',
                prefixIcon: const Icon(Icons.email_outlined),
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña (opcional)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                hintText: 'Dejar en blanco para no cambiar',
              ),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Sección: Biometría & Medidas
        _buildSectionCard(
          title: 'Datos Biométricos para Hábitos',
          icon: Icons.monitor_weight_outlined,
          isDark: isDark,
          children: [
            // Género Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Género',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                DropdownMenuItem(value: 'otro', child: Text('Otro / Prefiero no decir')),
              ],
              onChanged: (val) {
                setState(() => _selectedGender = val);
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.scale_outlined),
                      hintText: 'Ej. 70.5',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Estatura (cm)',
                      prefixIcon: Icon(Icons.height_outlined),
                      hintText: 'Ej. 175',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Edad (años)',
                prefixIcon: Icon(Icons.cake_outlined),
                hintText: 'Ej. 25',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Botón Guardar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
          onPressed: _isSaving ? null : _saveProfileChanges,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _isSaving ? 'Guardando...' : 'Guardar Datos de Perfil',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHealthSummaryCard(dynamic user, bool isDark) {
    final bmi = user.bmi;
    final bmiCategory = user.bmiCategory;
    final waterLiters = user.recommendedWaterLiters;
    final waterGlasses = user.recommendedWaterGlasses;

    Color badgeColor = AppTheme.primary;
    if (bmi != null) {
      if (bmi < 18.5) {
        badgeColor = AppTheme.warning;
      } else if (bmi < 25.0) {
        badgeColor = AppTheme.success;
      } else if (bmi < 30.0) {
        badgeColor = AppTheme.warning;
      } else {
        badgeColor = AppTheme.error;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Métricas de Salud Estimadas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // IMC Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.backgroundDark
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Índice Masa Corporal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bmi != null ? bmi.toStringAsFixed(1) : '--',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bmiCategory,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Ingesta Agua Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.backgroundDark
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agua Recomendada',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${waterLiters.toStringAsFixed(1)} L/día',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '~$waterGlasses vasos (250ml)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, bool isDark) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, _) {
        if (habitProvider.status == HabitStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeHabits =
            habitProvider.habits.where((h) => h.isActive).toList();

        return RefreshIndicator(
          onRefresh: _loadStatsData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Métricas globales
              _buildMetricsGrid(habitProvider, isDark),
              const SizedBox(height: 16),

              if (activeHabits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no tienes hábitos activos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Agrega hábitos y completa tus registros diarios para ver tus estadísticas detalladas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_categoryData != null && _categoryData!.isNotEmpty) ...[
                  CategoryDonutChart(categoryData: _categoryData!),
                  const SizedBox(height: 16),
                ],
                if (_trendData != null) ...[
                  TrendLineChart(
                    dailyCompletions: _trendData!,
                    totalHabits: habitProvider.totalActiveHabits,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_weekdayData != null && _weekdayData!.isNotEmpty) ...[
                  ProductiveWeekdayCard(weekdayData: _weekdayData!),
                  const SizedBox(height: 16),
                ],
                MonthComparisonCard(
                  currentMonthRate: _currentMonthRate,
                  previousMonthRate: _previousMonthRate,
                ),
                const SizedBox(height: 16),
                Text(
                  'Progreso Semanal',
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
                const SizedBox(height: 16),
                ..._buildGoalSections(habitProvider, activeHabits),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(HabitProvider provider, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          title: 'Racha Actual',
          value: '${provider.currentOverallStreak} d',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6D00),
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Mejor Racha',
          value: '${provider.bestOverallStreak} d',
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFFFD600),
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Hábitos Activos',
          value: '${provider.totalActiveHabits}',
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.primary,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Cumplimiento Mes',
          value: '${(_currentMonthRate * 100).toStringAsFixed(0)}%',
          icon: Icons.trending_up_rounded,
          color: AppTheme.success,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGoalSections(
    HabitProvider habitProvider,
    List<dynamic> activeHabits,
  ) {
    final habitsWithGoals = activeHabits
        .where((h) => h.goalTarget != null && h.goalDays != null)
        .toList();

    if (habitsWithGoals.isEmpty) return [];

    return [
      Text(
        'Metas de Hábitos',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      ...habitsWithGoals.map((habit) {
        return FutureBuilder<Map<String, dynamic>>(
          future: habitProvider.getGoalProgress(habit.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GoalProgressCard(
                habit: habit,
                completed: (data['completed'] ?? data['completions'] ?? 0) as int,
              ),
            );
          },
        );
      }),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/infrastructure/database/database_helper.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/step_provider.dart';
import 'package:habitos_app/presentation/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final stepProvider = context.watch<StepProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Sección: Sensores & Podómetro
          _buildSectionHeader('Sensores y Podómetro'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: Color(0xFF00B894),
                    ),
                  ),
                  title: const Text(
                    'Meta diaria de pasos',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${stepProvider.stepGoal} pasos diarios'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showStepGoalDialog(context, stepProvider),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      stepProvider.isSensorAvailable
                          ? Icons.sensors_rounded
                          : Icons.sensors_off_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Estado del sensor de movimiento',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    stepProvider.isSensorAvailable
                        ? 'Hardware activo (${stepProvider.pedestrianStatus})'
                        : 'Modo autónomo/simulación disponible',
                  ),
                  trailing: stepProvider.isSensorAvailable
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20)
                      : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restart_alt_rounded, color: AppTheme.warning),
                  ),
                  title: const Text('Reiniciar contador de pasos de hoy'),
                  subtitle: const Text('Vuelve a poner en 0 el contador'),
                  onTap: () async {
                    await stepProvider.resetSteps();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pasos de hoy reiniciados a 0')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección: Apariencia
          _buildSectionHeader('Apariencia y Tema'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _ThemeOption(
                  title: 'Claro',
                  subtitle: 'Tema claro siempre activo',
                  value: ThemeMode.light,
                  selected: themeProvider.themeMode,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _ThemeOption(
                  title: 'Oscuro',
                  subtitle: 'Tema oscuro siempre activo',
                  value: ThemeMode.dark,
                  selected: themeProvider.themeMode,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _ThemeOption(
                  title: 'Automático / Sistema',
                  subtitle: 'Se ajusta a la configuración del dispositivo',
                  value: ThemeMode.system,
                  selected: themeProvider.themeMode,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección: Notificaciones
          _buildSectionHeader('Notificaciones y Alarmas'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active, color: AppTheme.primary),
                  ),
                  title: const Text(
                    'Probar notificación instantánea',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Envía una notificación de prueba de VitalHabit'),
                  onTap: () async {
                    await NotificationHelper.requestNotificationPermission();
                    final granted = await NotificationHelper.requestExactAlarmPermission();
                    await NotificationHelper.showImmediate(
                      id: 999,
                      title: '¡Notificación de VitalHabit! 🎯',
                      body: 'Tus notificaciones y alertas están funcionando a la perfección.',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted
                              ? 'Notificación enviada con éxito'
                              : 'Notificación enviada (permiso de alarma exacta pendiente)'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_rounded, color: AppTheme.warning),
                  ),
                  title: const Text(
                    'Agendar recordatorio en 1 minuto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Prueba de alarma con hora programada'),
                  onTap: () async {
                    await NotificationHelper.requestNotificationPermission();
                    final date = DateTime.now().add(const Duration(minutes: 1));
                    await NotificationHelper.scheduleAlarmNotification(
                      id: 998,
                      title: '¡Hora de tu hábito! 🔔',
                      body: 'Esta es una prueba de tu recordatorio programado.',
                      scheduledDate: date,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Alarma agendada para las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección: Cuenta & Perfil
          _buildSectionHeader('Cuenta y Perfil'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.accent),
                  ),
                  title: const Text(
                    'Mi Perfil & Estadísticas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Edita tu nombre, contraseña, peso, estatura e IMC'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.push(AppRoutes.profile);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await authProvider.logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección: Almacenamiento & Datos
          _buildSectionHeader('Almacenamiento y Base de Datos'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
              ),
              title: const Text(
                'Borrar todos los datos locales',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Reinicia la base de datos de la app'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Borrar todos los datos?'),
                    content: const Text(
                      'Se eliminarán todos los hábitos, registros y usuarios. Esta acción no se puede deshacer.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Borrar todo'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await DatabaseHelper.resetDatabase();
                  await authProvider.logout();
                  await SeedHelper.seedTestUser();
                  if (context.mounted) context.go(AppRoutes.login);
                }
              },
            ),
          ),
          const SizedBox(height: 32),

          // Pie de pantalla
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v2.0.0',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Desarrollo para Dispositivos Inteligentes',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showStepGoalDialog(BuildContext context, StepProvider stepProvider) {
    final controller = TextEditingController(text: '${stepProvider.stepGoal}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meta de pasos diarios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa cuántos pasos diarios deseas alcanzar:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pasos',
                suffixText: 'pasos',
                prefixIcon: Icon(Icons.directions_walk),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                await stepProvider.setStepGoal(val);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Radio<ThemeMode>(
              value: value,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

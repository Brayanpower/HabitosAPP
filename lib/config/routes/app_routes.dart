import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/screens/auth/login_screen.dart';
import 'package:habitos_app/presentation/screens/auth/register_screen.dart';
import 'package:habitos_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:habitos_app/presentation/screens/habits/habit_detail_screen.dart';
import 'package:habitos_app/presentation/screens/habits/habit_form_screen.dart';
import 'package:habitos_app/presentation/screens/calendar/calendar_screen.dart';
import 'package:habitos_app/presentation/screens/stats/stats_screen.dart';
import 'package:habitos_app/presentation/screens/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String habitForm = '/habits/form';
  static const String habitDetail = '/habits/detail';
  static const String calendar = '/calendar';
  static const String stats = '/stats';
  static const String settings = '/settings';

  static GoRouter router({Listenable? refreshListenable}) => GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: login,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuth = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == login ||
          state.matchedLocation == register;

      if (!isAuth && !isAuthRoute) return login;
      if (isAuth && isAuthRoute) return home;
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: habitForm,
        name: 'habitForm',
        builder: (context, state) {
          final habitId = state.uri.queryParameters['id'];
          return HabitFormScreen(habitId: habitId);
        },
      ),
      GoRoute(
        path: habitDetail,
        name: 'habitDetail',
        builder: (context, state) {
          final habitId = state.uri.queryParameters['id'] ?? '';
          return HabitDetailScreen(habitId: habitId);
        },
      ),
      GoRoute(
        path: calendar,
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: stats,
        name: 'stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

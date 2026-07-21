import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String habits = '/habits';
  static const String habitForm = '/habits/form';
  static const String calendar = '/calendar';
  static const String stats = '/stats';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
      ),
      GoRoute(
        path: habitForm,
        name: 'habitForm',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Habit Form'),
      ),
      GoRoute(
        path: calendar,
        name: 'calendar',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Calendar'),
      ),
      GoRoute(
        path: stats,
        name: 'stats',
        builder: (context, state) => const _PlaceholderScreen(title: 'Stats'),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

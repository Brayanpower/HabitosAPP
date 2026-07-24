import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/infrastructure/datasource/auth_local_datasource.dart';
import 'package:habitos_app/infrastructure/datasource/habit_local_datasource.dart';
import 'package:habitos_app/infrastructure/repositories/auth_repository_impl.dart';
import 'package:habitos_app/infrastructure/repositories/habit_repository_impl.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/providers/habit_provider.dart';
import 'package:habitos_app/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await NotificationHelper.init();
  await SeedHelper.seedTestUser();

  final authDatasource = AuthLocalDatasource();
  final habitDatasource = HabitLocalDatasource();

  final authRepository = AuthRepositoryImpl(datasource: authDatasource);
  final habitRepository = HabitRepositoryImpl(datasource: habitDatasource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(habitRepository: habitRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const HabitosApp(),
    ),
  );
}

class HabitosApp extends StatelessWidget {
  const HabitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRoutes.router,
    );
  }
}

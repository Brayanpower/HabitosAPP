import 'package:flutter/material.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:habitos_app/presentation/screens/habits/habits_screen.dart';
import 'package:habitos_app/presentation/screens/calendar/calendar_screen.dart';
import 'package:habitos_app/presentation/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;

  const MainNavigationScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = [
      DashboardScreen(
        onNavigateToProfile: () => _onTabTapped(3),
        onNavigateToHabits: () => _onTabTapped(1),
      ),
      const HabitsScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist_rounded, color: AppTheme.primary),
              label: 'Hábitos',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

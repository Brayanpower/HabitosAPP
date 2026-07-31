class AppConstants {
  AppConstants._();

  static const String appName = 'VitalHabit';
  static const String dbName = 'habitos.db';
  static const int dbVersion = 7;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String themeKey = 'theme_mode';
  static const String stepGoalKey = 'pref_step_goal';
  static const String waterGlassKey = 'pref_water_glass_ml';
  static const String morningReminderKey = 'pref_morning_reminder';
  static const String eveningReminderKey = 'pref_evening_reminder';
  static const String morningTimeKey = 'pref_morning_time';
  static const String eveningTimeKey = 'pref_evening_time';
  static const String celebrationNotificationKey = 'pref_celebration_notify';

  static const Duration tokenDuration = Duration(days: 7);

  static const double borderRadius = 16.0;
  static const double smallRadius = 8.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
}

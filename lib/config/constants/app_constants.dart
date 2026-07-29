class AppConstants {
  AppConstants._();

  static const String appName = 'Habitos App';
  static const String dbName = 'habitos.db';
  static const int dbVersion = 5;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String themeKey = 'theme_mode';

  static const Duration tokenDuration = Duration(days: 7);

  static const double borderRadius = 16.0;
  static const double smallRadius = 8.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
}

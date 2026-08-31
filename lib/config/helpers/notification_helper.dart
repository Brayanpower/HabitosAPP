import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createAlarmChannel();
      await requestNotificationPermission();
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationHelper.init error: $e');
    }
  }

  static Future<void> _createAlarmChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'habits_alarm_channel',
        'Alertas de hábitos',
        description: 'Alertas con sonido para recordatorios de hábitos',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    return await androidPlugin.requestNotificationsPermission() ?? false;
  }

  static void _onNotificationTap(NotificationResponse response) {}

  static AndroidNotificationDetails _alarmDetails() {
    return AndroidNotificationDetails(
      'habits_alarm_channel',
      'Alertas de hábitos',
      channelDescription: 'Alertas con sonido para recordatorios de hábitos',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([500, 500, 500, 500]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
  }

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) await init();
      await _createAlarmChannel();
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: _alarmDetails(),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('showImmediate error: $e');
    }
  }

  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await showImmediate(id: id, title: title, body: body, payload: payload);
  }

  /// Notificación de Temporizador de Hábito Completado
  static Future<void> showTimerCompletedNotification({
    required String habitName,
    required int minutes,
  }) async {
    await showImmediate(
      id: 8801,
      title: '¡Tiempo completado! ⏱️🎉',
      body: 'Has cumplido tus $minutes minutos dedicados a "$habitName" hoy. ¡Excelente disciplina!',
    );
  }

  /// Notificación de Meta de Agua Alcanzada
  static Future<void> showWaterGoalReachedNotification({
    required int targetMl,
  }) async {
    final liters = (targetMl / 1000).toStringAsFixed(1);
    await showImmediate(
      id: 8802,
      title: '¡Meta de Hidratación Alcanzada! 💧🎉',
      body: '¡Felicidades! Completaste tus ${liters}L ($targetMl ml) de agua del día.',
    );
  }

  /// Notificación de Meta de Pasos Alcanzada con Sensores
  static Future<void> showStepGoalReachedNotification({
    required int steps,
  }) async {
    await showImmediate(
      id: 8803,
      title: '¡Meta de Pasos Diarios Alcanzada! 🚶‍♂️🌟',
      body: '¡Increíble! Tus sensores registraron $steps pasos hoy. Has completado tu objetivo de caminata.',
    );
  }

  /// Notificación genérica de hábito completado
  static Future<void> showHabitCompletedNotification({
    required String habitName,
    String? message,
  }) async {
    await showImmediate(
      id: 8804,
      title: '¡Hábito Completado! ✨',
      body: message ?? 'Has marcado "$habitName" como completado hoy. ¡Sigue así!',
    );
  }

  static Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.requestExactAlarmsPermission() ?? false;
  }

  static Future<bool> hasExactAlarmPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.canScheduleExactNotifications() ?? false;
  }

  static Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_initialized) await init();
      var tzDate = tz.TZDateTime.local(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );
      final now = tz.TZDateTime.now(tz.local);
      final nowRounded = tz.TZDateTime.local(
        now.year, now.month, now.day, now.hour, now.minute,
      );
      if (tzDate.isBefore(nowRounded)) {
        tzDate = tzDate.add(const Duration(days: 1));
      }

      final exact = await hasExactAlarmPermission();

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: _alarmDetails(),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleAlarmNotification error: $e');
    }
  }

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await scheduleAlarmNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

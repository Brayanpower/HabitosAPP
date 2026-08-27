import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }

  static String formatDayName(DateTime date) {
    return DateFormat('EEEE', 'es').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'es').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool isToday(DateTime date) {
    final todayDate = today();
    return date.year == todayDate.year &&
        date.month == todayDate.month &&
        date.day == todayDate.day;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  static List<DateTime> getCurrentMonthDays(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    for (var day = 1; day <= last.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }
    return days;
  }

  static List<DateTime> getWeekDays(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static int weekNumber(DateTime date) {
    return int.parse(DateFormat('w').format(date));
  }

  static String weekdayName(DateTime date) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[date.weekday - 1];
  }

  static String monthName(DateTime date) {
    const names = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return names[date.month - 1];
  }
}

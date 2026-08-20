import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/config/helpers/date_helper.dart';

void main() {
  group('DateHelper', () {
    test('formatDate should return yyyy-MM-dd format', () {
      final date = DateTime(2026, 7, 29);
      expect(DateHelper.formatDate(date), '2026-07-29');
    });

    test('isToday should return true for current date', () {
      expect(DateHelper.isToday(DateTime.now()), true);
    });

    test('isToday should return false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelper.isToday(yesterday), false);
    });

    test('isSameDay should compare dates correctly', () {
      final a = DateTime(2026, 7, 29, 10, 30);
      final b = DateTime(2026, 7, 29, 15, 0);
      expect(DateHelper.isSameDay(a, b), true);
    });

    test('isSameDay should return false for different days', () {
      final a = DateTime(2026, 7, 29);
      final b = DateTime(2026, 7, 30);
      expect(DateHelper.isSameDay(a, b), false);
    });

    test('daysBetween should calculate difference correctly', () {
      final from = DateTime(2026, 7, 1);
      final to = DateTime(2026, 7, 10);
      expect(DateHelper.daysBetween(from, to), 9);
    });

    test('getCurrentMonthDays should return correct number of days', () {
      final month = DateTime(2026, 7, 15);
      final days = DateHelper.getCurrentMonthDays(month);
      expect(days.length, 31);
      expect(days.first.day, 1);
      expect(days.last.day, 31);
    });

    test('getWeekDays should return 7 days starting from Monday', () {
      // 2026-07-29 is a Wednesday
      final date = DateTime(2026, 7, 29);
      final week = DateHelper.getWeekDays(date);
      expect(week.length, 7);
      expect(week.first.weekday, DateTime.monday);
      expect(week.last.weekday, DateTime.sunday);
    });

    test('today should return date without time', () {
      final today = DateHelper.today();
      expect(today.hour, 0);
      expect(today.minute, 0);
      expect(today.second, 0);
    });
  });
}

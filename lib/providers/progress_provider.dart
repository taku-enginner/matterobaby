import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import 'attendance_provider.dart';
import 'settings_provider.dart';

class ProgressData {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int qualifyingMonths;
  final int totalMonthsElapsed;
  final int remainingMonths;
  final bool goalAchieved;
  final double progressPercent;
  final int currentMonthDays;
  final int daysNeededThisMonth;

  ProgressData({
    required this.periodStart,
    required this.periodEnd,
    required this.qualifyingMonths,
    required this.totalMonthsElapsed,
    required this.remainingMonths,
    required this.goalAchieved,
    required this.progressPercent,
    required this.currentMonthDays,
    required this.daysNeededThisMonth,
  });
}

final progressProvider = Provider<ProgressData?>((ref) {
  final settings = ref.watch(settingsProvider);
  final attendance = ref.watch(attendanceProvider);

  if (settings == null) return null;

  final now = DateTime.now();
  final periodStart = settings.periodStartDate;
  final periodEnd = settings.periodEndDate;

  final qualifyingMonths = _countQualifyingMonths(attendance, periodStart, now);
  final totalMonthsElapsed = _monthsDifference(periodStart, now);
  final remainingMonths = _monthsDifference(now, periodEnd);
  final currentMonthDays = attendance
      .where((r) => r.date.year == now.year && r.date.month == now.month)
      .length;

  return ProgressData(
    periodStart: periodStart,
    periodEnd: periodEnd,
    qualifyingMonths: qualifyingMonths,
    totalMonthsElapsed: totalMonthsElapsed,
    remainingMonths: remainingMonths > 0 ? remainingMonths : 0,
    goalAchieved: qualifyingMonths >= AppConstants.requiredQualifyingMonths,
    progressPercent: (qualifyingMonths / AppConstants.requiredQualifyingMonths * 100)
        .clamp(0, 100),
    currentMonthDays: currentMonthDays,
    daysNeededThisMonth:
        (AppConstants.requiredDaysPerMonth - currentMonthDays).clamp(0, AppConstants.requiredDaysPerMonth),
  );
});

int _countQualifyingMonths(
    List attendance, DateTime start, DateTime end) {
  int count = 0;
  DateTime current = DateTime(start.year, start.month, 1);

  while (current.isBefore(end) || current.month == end.month && current.year == end.year) {
    final daysInMonth = attendance
        .where((r) => r.date.year == current.year && r.date.month == current.month)
        .length;
    if (daysInMonth >= AppConstants.requiredDaysPerMonth) {
      count++;
    }
    current = DateTime(current.year, current.month + 1, 1);
  }

  return count;
}

int _monthsDifference(DateTime from, DateTime to) {
  return (to.year - from.year) * 12 + (to.month - from.month);
}

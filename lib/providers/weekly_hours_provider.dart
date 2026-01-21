import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_record.dart';
import 'attendance_provider.dart';
import 'settings_provider.dart';

/// 週の開始日（月曜日）を取得
DateTime getWeekStart(DateTime date) {
  final weekday = date.weekday; // 1=月, 7=日
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}

/// 週の終了日（日曜日）を取得
DateTime getWeekEnd(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day + (7 - weekday));
}

/// 週間勤務データ
class WeeklyHoursData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalHours;
  final double goalHours;
  final List<DailyWorkRecord> dailyRecords;
  final Map<String?, double> hoursByWorkplace; // workplaceId -> hours

  WeeklyHoursData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalHours,
    required this.goalHours,
    required this.dailyRecords,
    required this.hoursByWorkplace,
  });

  double get progressRatio =>
      goalHours > 0 ? (totalHours / goalHours).clamp(0.0, 1.0) : 0.0;

  bool get isGoalMet => totalHours >= goalHours;

  int get daysWorked => dailyRecords.where((r) => r.totalHours > 0).length;
}

/// 1日の勤務データ（複数勤務先対応）
class DailyWorkRecord {
  final DateTime date;
  final List<WorkEntry> entries;

  DailyWorkRecord({
    required this.date,
    required this.entries,
  });

  double get totalHours =>
      entries.fold(0.0, (sum, entry) => sum + entry.hours);
}

/// 勤務エントリ（1つの勤務記録）
class WorkEntry {
  final String? workplaceId;
  final double hours;

  WorkEntry({
    this.workplaceId,
    required this.hours,
  });
}

/// 現在の週の勤務時間プロバイダー
final currentWeekHoursProvider = Provider<WeeklyHoursData>((ref) {
  final records = ref.watch(attendanceProvider);
  final settings = ref.watch(settingsProvider);
  final defaultHours = settings?.defaultWorkHours ?? 8.0;
  final goalHours = settings?.weeklyHoursGoal ?? 20.0;

  return _calculateWeeklyHours(
    records,
    DateTime.now(),
    defaultHours,
    goalHours,
  );
});

/// 過去N週間の勤務時間プロバイダー
final recentWeeksHoursProvider =
    Provider.family<List<WeeklyHoursData>, int>((ref, weeksCount) {
  final records = ref.watch(attendanceProvider);
  final settings = ref.watch(settingsProvider);
  final defaultHours = settings?.defaultWorkHours ?? 8.0;
  final goalHours = settings?.weeklyHoursGoal ?? 20.0;

  final weeks = <WeeklyHoursData>[];
  final now = DateTime.now();

  for (var i = 0; i < weeksCount; i++) {
    final weekDate = now.subtract(Duration(days: i * 7));
    weeks.add(_calculateWeeklyHours(
      records,
      weekDate,
      defaultHours,
      goalHours,
    ));
  }

  return weeks;
});

/// 指定された週の勤務時間を計算
WeeklyHoursData _calculateWeeklyHours(
  List<AttendanceRecord> records,
  DateTime dateInWeek,
  double defaultHours,
  double goalHours,
) {
  final weekStart = getWeekStart(dateInWeek);
  final weekEnd = getWeekEnd(dateInWeek);

  // この週の記録をフィルタ
  final weekRecords = records.where((r) {
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
  }).toList();

  // 日ごとにグループ化
  final dailyMap = <String, List<AttendanceRecord>>{};
  for (final record in weekRecords) {
    final key = record.dateKey;
    dailyMap.putIfAbsent(key, () => []).add(record);
  }

  // DailyWorkRecord を作成
  final dailyRecords = <DailyWorkRecord>[];
  for (var i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayRecords = dailyMap[key] ?? [];

    final entries = dayRecords.map((r) {
      return WorkEntry(
        workplaceId: r.workplaceId,
        hours: r.workHours ?? defaultHours,
      );
    }).toList();

    dailyRecords.add(DailyWorkRecord(
      date: date,
      entries: entries,
    ));
  }

  final totalHours =
      dailyRecords.fold(0.0, (sum, day) => sum + day.totalHours);

  // 勤務先別の時間を集計
  final hoursByWorkplace = <String?, double>{};
  for (final day in dailyRecords) {
    for (final entry in day.entries) {
      hoursByWorkplace[entry.workplaceId] =
          (hoursByWorkplace[entry.workplaceId] ?? 0.0) + entry.hours;
    }
  }

  return WeeklyHoursData(
    weekStart: weekStart,
    weekEnd: weekEnd,
    totalHours: totalHours,
    goalHours: goalHours,
    dailyRecords: dailyRecords,
    hoursByWorkplace: hoursByWorkplace,
  );
}

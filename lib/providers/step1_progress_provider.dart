import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'weekly_hours_provider.dart';

/// STEP1進捗データ（雇用保険加入条件）
class Step1ProgressData {
  final WeeklyHoursData currentWeek;
  final List<WeeklyHoursData> recentWeeks;
  final int consecutiveWeeksMet;
  final bool isCurrentWeekMet;

  Step1ProgressData({
    required this.currentWeek,
    required this.recentWeeks,
    required this.consecutiveWeeksMet,
    required this.isCurrentWeekMet,
  });

  /// 進捗メッセージ
  String get progressMessage {
    if (isCurrentWeekMet) {
      return '今週の目標達成！';
    }
    final remaining = currentWeek.goalHours - currentWeek.totalHours;
    return 'あと${remaining.toStringAsFixed(1)}時間';
  }
}

/// STEP1進捗プロバイダー
final step1ProgressProvider = Provider<Step1ProgressData>((ref) {
  final currentWeek = ref.watch(currentWeekHoursProvider);
  final recentWeeks = ref.watch(recentWeeksHoursProvider(8)); // 過去8週間

  // 連続で目標達成した週数をカウント
  var consecutiveCount = 0;
  for (final week in recentWeeks) {
    if (week.isGoalMet) {
      consecutiveCount++;
    } else {
      break;
    }
  }

  return Step1ProgressData(
    currentWeek: currentWeek,
    recentWeeks: recentWeeks,
    consecutiveWeeksMet: consecutiveCount,
    isCurrentWeekMet: currentWeek.isGoalMet,
  );
});

/// 現在のステップ（1 or 2）
final currentStepProvider = Provider<int>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings?.isEmploymentInsuranceEnrolled ?? false) {
    return 2;
  }
  return 1;
});

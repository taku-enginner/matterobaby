import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/settings_datasource.dart';
import '../data/models/user_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings?>((ref) {
  return SettingsNotifier();
});

final tutorialRestartRequestProvider = StateProvider<bool>((ref) => false);

class SettingsNotifier extends StateNotifier<UserSettings?> {
  SettingsNotifier() : super(null);

  final _datasource = SettingsDatasource();

  Future<void> init() async {
    try {
      var data = await _datasource.getSettings();
      // 設定が存在しない場合は作成
      data ??= await _datasource.createSettings(
        periodStartDate: DateTime.now(),
      );
      state = UserSettings.fromJson(data);
    } catch (e) {
      // エラー時はデフォルト設定を使用
      state = UserSettings(periodStartDate: DateTime.now());
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    try {
      final data = await _datasource.updateSettings(settings.toJson());
      state = UserSettings.fromJson(data);
    } catch (e) {
      // エラー時もローカル状態は更新
      state = settings;
    }
  }

  Future<void> updateNotifications({
    bool? enabled,
    int? hour,
    int? minute,
    List<int>? days,
    int? weeklyGoal,
  }) async {
    if (state == null) return;

    final updated = state!.copyWith(
      notificationsEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
      reminderDays: days,
      weeklyGoalDays: weeklyGoal,
    );
    await updateSettings(updated);
  }

  Future<void> setScheduledWeekdays(List<int> weekdays) async {
    if (state == null) return;

    final updated = state!.copyWith(scheduledWeekdays: weekdays);
    await updateSettings(updated);
  }

  Future<void> markTutorialSeen() async {
    final current = state ?? UserSettings(periodStartDate: DateTime.now());
    final updated = current.copyWith(hasSeenOnboarding: true);
    await updateSettings(updated);
  }

  Future<void> setEmploymentInsuranceEnrolled(bool enrolled) async {
    if (state == null) return;

    final updated = state!.copyWith(
      isEmploymentInsuranceEnrolled: enrolled,
      employmentInsuranceEnrolledDate: enrolled ? DateTime.now() : null,
    );
    await updateSettings(updated);
  }

  Future<void> setWeeklyHoursGoal(double hours) async {
    if (state == null) return;

    final updated = state!.copyWith(weeklyHoursGoal: hours);
    await updateSettings(updated);
  }

  Future<void> setDefaultWorkHours(double hours) async {
    if (state == null) return;

    final updated = state!.copyWith(defaultWorkHours: hours);
    await updateSettings(updated);
  }
}

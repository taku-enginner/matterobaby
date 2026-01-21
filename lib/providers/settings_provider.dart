import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings?>((ref) {
  return SettingsNotifier();
});

final tutorialRestartRequestProvider = StateProvider<bool>((ref) => false);

class SettingsNotifier extends StateNotifier<UserSettings?> {
  SettingsNotifier() : super(null);

  Box<UserSettings>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<UserSettings>(AppConstants.settingsBoxName);
    if (_box!.isEmpty) {
      final settings = UserSettings(periodStartDate: DateTime.now());
      await _box!.add(settings);
    }
    state = _box!.values.first;
  }

  Future<void> updateSettings(UserSettings settings) async {
    if (_box != null && _box!.isNotEmpty) {
      final key = _box!.keys.first;
      await _box!.put(key, settings);
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
    if (state == null) return;

    final updated = state!.copyWith(hasSeenOnboarding: true);
    await updateSettings(updated);
  }

  /// 雇用保険加入状態を更新
  Future<void> setEmploymentInsuranceEnrolled(bool enrolled) async {
    if (state == null) return;

    final updated = state!.copyWith(
      isEmploymentInsuranceEnrolled: enrolled,
      employmentInsuranceEnrolledDate: enrolled ? DateTime.now() : null,
    );
    await updateSettings(updated);
  }

  /// 週間勤務時間目標を更新
  Future<void> setWeeklyHoursGoal(double hours) async {
    if (state == null) return;

    final updated = state!.copyWith(weeklyHoursGoal: hours);
    await updateSettings(updated);
  }

  /// デフォルト勤務時間を更新
  Future<void> setDefaultWorkHours(double hours) async {
    if (state == null) return;

    final updated = state!.copyWith(defaultWorkHours: hours);
    await updateSettings(updated);
  }
}

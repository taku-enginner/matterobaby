import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0)
  final DateTime periodStartDate;

  @HiveField(1)
  final bool notificationsEnabled;

  @HiveField(2)
  final int weeklyGoalDays;

  @HiveField(3)
  final int reminderHour;

  @HiveField(4)
  final int reminderMinute;

  @HiveField(5)
  final List<int> reminderDays;

  @HiveField(6)
  final String? shareCode;

  @HiveField(7)
  final DateTime? shareCodeCreatedAt;

  @HiveField(8)
  final List<int> scheduledWeekdays;

  @HiveField(9, defaultValue: false)
  final bool hasSeenOnboarding;

  @HiveField(10, defaultValue: false)
  final bool isEmploymentInsuranceEnrolled;

  @HiveField(11, defaultValue: null)
  final DateTime? employmentInsuranceEnrolledDate;

  @HiveField(12, defaultValue: 20.0)
  final double weeklyHoursGoal;

  @HiveField(13, defaultValue: 8.0)
  final double defaultWorkHours;

  UserSettings({
    required this.periodStartDate,
    this.notificationsEnabled = false,
    this.weeklyGoalDays = 3,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.reminderDays = const [1, 2, 3, 4, 5],
    this.shareCode,
    this.shareCodeCreatedAt,
    this.scheduledWeekdays = const [],
    this.hasSeenOnboarding = false,
    this.isEmploymentInsuranceEnrolled = false,
    this.employmentInsuranceEnrolledDate,
    this.weeklyHoursGoal = 20.0,
    this.defaultWorkHours = 8.0,
  });

  DateTime get periodEndDate =>
      DateTime(periodStartDate.year + 2, periodStartDate.month, periodStartDate.day);

  UserSettings copyWith({
    DateTime? periodStartDate,
    bool? notificationsEnabled,
    int? weeklyGoalDays,
    int? reminderHour,
    int? reminderMinute,
    List<int>? reminderDays,
    String? shareCode,
    DateTime? shareCodeCreatedAt,
    List<int>? scheduledWeekdays,
    bool? hasSeenOnboarding,
    bool? isEmploymentInsuranceEnrolled,
    DateTime? employmentInsuranceEnrolledDate,
    double? weeklyHoursGoal,
    double? defaultWorkHours,
  }) {
    return UserSettings(
      periodStartDate: periodStartDate ?? this.periodStartDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderDays: reminderDays ?? this.reminderDays,
      shareCode: shareCode ?? this.shareCode,
      shareCodeCreatedAt: shareCodeCreatedAt ?? this.shareCodeCreatedAt,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      isEmploymentInsuranceEnrolled: isEmploymentInsuranceEnrolled ?? this.isEmploymentInsuranceEnrolled,
      employmentInsuranceEnrolledDate: employmentInsuranceEnrolledDate ?? this.employmentInsuranceEnrolledDate,
      weeklyHoursGoal: weeklyHoursGoal ?? this.weeklyHoursGoal,
      defaultWorkHours: defaultWorkHours ?? this.defaultWorkHours,
    );
  }
}

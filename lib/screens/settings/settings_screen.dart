import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/tutorial/tutorial_keys.dart';
import '../../data/models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workplace_provider.dart';
import '../../services/notification_service.dart';
import 'workplace_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _notificationService = NotificationService();
  String? _notificationError;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
        children: [
          _buildSectionHeader(context, '期間設定'),
          ListTile(
            key: TutorialKeys.periodStartDate,
            leading: const Icon(Icons.calendar_month),
            title: const Text('開始日'),
            subtitle: Text(
              DateFormat.yMMMd('ja_JP').format(settings.periodStartDate),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '残り${_getRemainingMonths(settings.periodStartDate)}ヶ月',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showDatePicker(context, settings.periodStartDate, isStartDate: true),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('終了日'),
            subtitle: Text(
              DateFormat.yMMMd('ja_JP').format(settings.periodEndDate),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDatePicker(context, settings.periodEndDate, isStartDate: false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '育休取得条件：2年間で12ヶ月（各月11日以上）の出勤が必要です',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, '勤務設定'),
          SwitchListTile(
            secondary: const Icon(Icons.verified_user),
            title: const Text('雇用保険加入済み'),
            subtitle: Text(
              settings.isEmploymentInsuranceEnrolled
                  ? '育休取得条件（STEP2）を表示中'
                  : '雇用保険加入条件（STEP1）を表示中',
            ),
            value: settings.isEmploymentInsuranceEnrolled,
            onChanged: (value) async {
              await ref.read(settingsProvider.notifier).setEmploymentInsuranceEnrolled(value);
            },
          ),
          ListTile(
            key: TutorialKeys.workplaceSettings,
            leading: const Icon(Icons.business),
            title: const Text('勤務先管理'),
            subtitle: _buildWorkplaceSubtitle(ref),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkplaceManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('週間勤務時間目標'),
            subtitle: Text('${settings.weeklyHoursGoal.toStringAsFixed(0)}時間/週'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWeeklyHoursGoalDialog(context, settings.weeklyHoursGoal),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('1日のデフォルト勤務時間'),
            subtitle: Text('${settings.defaultWorkHours.toStringAsFixed(1)}時間'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDefaultWorkHoursDialog(context, settings.defaultWorkHours),
          ),
          const Divider(),
          _buildSectionHeader(context, '通知設定'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('リマインダー通知'),
            subtitle: _notificationError != null
                ? Text(
                    _notificationError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                : const Text('出勤目標を思い出すための通知'),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationError = null);
              if (value) {
                final granted = await _notificationService.requestPermission();
                if (!granted) {
                  setState(() => _notificationError = '通知の許可が必要です');
                  return;
                }
              }
              await ref.read(settingsProvider.notifier).updateNotifications(
                    enabled: value,
                  );
              if (value) {
                _scheduleNotifications(settings);
              } else {
                await _notificationService.cancelAll();
              }
            },
          ),
          if (settings.notificationsEnabled) ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('通知時刻'),
              subtitle: Text(
                '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                  ),
                );
                if (time != null) {
                  await ref.read(settingsProvider.notifier).updateNotifications(
                        hour: time.hour,
                        minute: time.minute,
                      );
                  _scheduleNotifications(settings);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('通知する曜日'),
              subtitle: Text(_formatReminderDays(settings.reminderDays)),
              onTap: () => _showDaySelectionDialog(context, settings.reminderDays),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('週間目標'),
              subtitle: Text('${settings.weeklyGoalDays}日/週'),
              onTap: () => _showGoalSelectionDialog(context, settings.weeklyGoalDays),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, 'その他'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('使い方を見る'),
            subtitle: const Text('チュートリアルを再表示します'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restartTutorial(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('アプリについて'),
            subtitle: const Text('出勤カウント v1.0.0'),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  int _getRemainingMonths(DateTime startDate) {
    final endDate = DateTime(startDate.year + 2, startDate.month, startDate.day);
    final now = DateTime.now();
    return (endDate.year - now.year) * 12 + (endDate.month - now.month);
  }

  String _formatReminderDays(List<int> days) {
    const dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => dayNames[d - 1]).join(', ');
  }

  Future<void> _showDaySelectionDialog(BuildContext context, List<int> currentDays) async {
    final selected = List<int>.from(currentDays);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('通知する曜日'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 7; i++)
                    CheckboxListTile(
                      title: Text(['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'][i - 1]),
                      value: selected.contains(i),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selected.add(i);
                          } else {
                            selected.remove(i);
                          }
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(settingsProvider.notifier).updateNotifications(
                          days: selected,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGoalSelectionDialog(BuildContext context, int currentGoal) async {
    int selected = currentGoal;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('週間目標'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 7; i++)
                    RadioListTile<int>(
                      title: Text('$i日/週'),
                      value: i,
                      groupValue: selected,
                      onChanged: (value) {
                        setState(() {
                          selected = value!;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(settingsProvider.notifier).updateNotifications(
                          weeklyGoal: selected,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _scheduleNotifications(UserSettings settings) {
    _notificationService.scheduleWeeklyReminder(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      days: settings.reminderDays,
      weeklyGoal: settings.weeklyGoalDays,
    );
  }

  Future<void> _showDatePicker(BuildContext context, DateTime currentDate, {required bool isStartDate}) async {
    final settings = ref.read(settingsProvider);
    if (settings == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('ja', 'JP'),
      helpText: isStartDate ? '開始日を選択' : '終了日を選択',
    );

    if (picked != null && context.mounted) {
      if (isStartDate) {
        final updated = settings.copyWith(periodStartDate: picked);
        await ref.read(settingsProvider.notifier).updateSettings(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('開始日を${DateFormat.yMMMd('ja_JP').format(picked)}に変更しました'),
            ),
          );
        }
      } else {
        final periodYears = picked.difference(settings.periodStartDate).inDays / 365;
        if (periodYears < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('終了日は開始日から1年以上先を選択してください')),
          );
          return;
        }
        final newStartDate = DateTime(
          picked.year - 2,
          picked.month,
          picked.day,
        );
        final updated = settings.copyWith(periodStartDate: newStartDate);
        await ref.read(settingsProvider.notifier).updateSettings(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('終了日を${DateFormat.yMMMd('ja_JP').format(picked)}に変更しました'),
            ),
          );
        }
      }
    }
  }

  void _restartTutorial(BuildContext context) {
    ref.read(tutorialRestartRequestProvider.notifier).state = true;
  }

  Widget _buildWorkplaceSubtitle(WidgetRef ref) {
    final workplaces = ref.watch(workplaceProvider);
    if (workplaces.isEmpty) {
      return const Text('未登録');
    }
    return Text('${workplaces.length}件登録');
  }

  Future<void> _showWeeklyHoursGoalDialog(BuildContext context, double currentValue) async {
    double selected = currentValue;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('週間勤務時間目標'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selected.toStringAsFixed(0)}時間/週',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selected,
                    min: 10,
                    max: 40,
                    divisions: 30,
                    label: '${selected.toStringAsFixed(0)}時間',
                    onChanged: (value) {
                      setState(() => selected = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '雇用保険加入には週20時間以上の勤務が必要です',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(settingsProvider.notifier).setWeeklyHoursGoal(selected);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDefaultWorkHoursDialog(BuildContext context, double currentValue) async {
    double selected = currentValue;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('1日のデフォルト勤務時間'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selected.toStringAsFixed(1)}時間',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selected,
                    min: 1,
                    max: 12,
                    divisions: 22,
                    label: '${selected.toStringAsFixed(1)}時間',
                    onChanged: (value) {
                      setState(() => selected = (value * 2).round() / 2); // 0.5時間刻み
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '記録時に時間を指定しない場合、この値が使用されます',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(settingsProvider.notifier).setDefaultWorkHours(selected);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

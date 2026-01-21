import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/japanese_holidays.dart';
import '../../core/tutorial/tutorial_keys.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/workplace.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/step1_progress_provider.dart';
import '../../providers/workplace_provider.dart';
import 'widgets/progress_card.dart';
import 'widgets/monthly_status_card.dart';
import 'widgets/schedule_settings_sheet.dart';
import 'widgets/step_indicator.dart';
import 'widgets/step1_progress_card.dart';

enum EditMode { attendance, schedule }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  EditMode _editMode = EditMode.attendance;

  void _showAttendanceDetail(DateTime selectedDay, List<Workplace> workplaces) {
    final attendanceRecords = ref.read(attendanceProvider);
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    // その日の記録を取得
    final dayRecords = attendanceRecords.where((r) {
      final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
      return recordDate == normalizedDay;
    }).toList();

    if (dayRecords.isEmpty) {
      return; // 記録がない場合は何もしない
    }

    final settings = ref.read(settingsProvider);
    final defaultHours = settings?.defaultWorkHours ?? 8.0;

    // 記録詳細を表示
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${selectedDay.month}/${selectedDay.day}の出勤記録',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...dayRecords.map((record) {
                final workplace = workplaces.where((w) => w.id == record.workplaceId).firstOrNull;
                final color = workplace != null
                    ? Color(workplace.colorValue)
                    : colorScheme.primary;
                final name = workplace?.name ?? '未設定';
                final hours = record.workHours ?? defaultHours;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color,
                          child: const Icon(Icons.work, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${hours.toStringAsFixed(1)}時間',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecords = ref.watch(attendanceProvider);
    final attendance = ref.watch(attendanceProvider.notifier);
    final schedule = ref.watch(scheduleProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final currentStep = ref.watch(currentStepProvider);
    final step1Progress = ref.watch(step1ProgressProvider);
    final workplaces = ref.watch(workplaceProvider);
    final markedDates = attendance.getMarkedDates();
    final scheduledDates = schedule.getScheduledDates();
    final colorScheme = Theme.of(context).colorScheme;

    final scheduledWeekdays = settings?.scheduledWeekdays ?? [];

    // Build a map for quick lookup of attendance records by date
    final attendanceByDate = <DateTime, List<AttendanceRecord>>{};
    for (final record in attendanceRecords) {
      final normalizedDate = DateTime(record.date.year, record.date.month, record.date.day);
      attendanceByDate.putIfAbsent(normalizedDate, () => []).add(record);
    }

    // Build a map for quick workplace color lookup
    final workplaceColors = <String?, Color>{};
    for (final wp in workplaces) {
      workplaceColors[wp.id] = Color(wp.colorValue);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 予定設定ボタン
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: TutorialKeys.scheduleSettingsButton,
                  icon: const Icon(Icons.edit_calendar),
                  tooltip: '予定設定',
                  onPressed: () => _showScheduleSettings(context),
                ),
              ),
              // ステップインジケーター
              KeyedSubtree(
                key: TutorialKeys.progressCard,
                child: StepIndicator(
                  currentStep: currentStep,
                ),
              ),
            const SizedBox(height: 16),

            // STEP 1: 週間勤務時間の進捗
            if (currentStep == 1) ...[
              Step1ProgressCard(
                currentWeek: step1Progress.currentWeek,
                recentWeeks: step1Progress.recentWeeks,
              ),
              const SizedBox(height: 16),
            ],

            // STEP 2: 月別達成の進捗（既存のProgressCard）
            if (currentStep == 2 && progress != null) ...[
              ProgressCard(progress: progress),
              const SizedBox(height: 16),
              MonthlyStatusCard(
                year: _focusedDay.year,
                month: _focusedDay.month,
                daysWorked: attendance.getDaysWorkedInMonth(
                  _focusedDay.year,
                  _focusedDay.month,
                ),
                daysScheduled: _getScheduledDaysInMonth(
                  _focusedDay.year,
                  _focusedDay.month,
                  scheduledDates,
                  scheduledWeekdays,
                ),
              ),
              const SizedBox(height: 16),
            ],
            KeyedSubtree(
              key: TutorialKeys.editModeSelector,
              child: _buildEditModeSelector(colorScheme),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: TutorialKeys.calendar,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                  locale: 'ja_JP',
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => false,
                  onDaySelected: (selectedDay, focusedDay) async {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    if (_editMode == EditMode.attendance) {
                      // 記録確認のみ（タップで詳細表示）
                      _showAttendanceDetail(selectedDay, workplaces);
                    } else {
                      await ref.read(scheduleProvider.notifier).toggleDate(selectedDay);
                    }
                  },
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: colorScheme.tertiary),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: colorScheme.onSurface),
                    weekendStyle: TextStyle(color: colorScheme.tertiary),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayCell(
                        context,
                        day,
                        markedDates,
                        scheduledDates,
                        scheduledWeekdays,
                        attendanceByDate: attendanceByDate,
                        workplaceColors: workplaceColors,
                        isToday: false,
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildDayCell(
                        context,
                        day,
                        markedDates,
                        scheduledDates,
                        scheduledWeekdays,
                        attendanceByDate: attendanceByDate,
                        workplaceColors: workplaceColors,
                        isToday: true,
                      );
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      );
                    },
                    dowBuilder: (context, day) {
                      final text = DateFormat.E('ja_JP').format(day);
                      Color color;
                      if (day.weekday == DateTime.sunday) {
                        color = Colors.red;
                      } else if (day.weekday == DateTime.saturday) {
                        color = Colors.blue;
                      } else {
                        color = colorScheme.onSurface;
                      }
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (date, locale) =>
                        DateFormat.yMMMM(locale).format(date),
                    headerPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(colorScheme, workplaces),
            const SizedBox(height: 24),
            _buildStatisticsSection(context, ref, colorScheme),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
      BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final attendance = ref.watch(attendanceProvider);
    final settings = ref.watch(settingsProvider);
    final monthlyData = _getMonthlyData(attendance, settings?.periodStartDate);
    final totalDays = attendance.length;
    final qualifyingMonths =
        monthlyData.where((m) => m.days >= AppConstants.requiredDaysPerMonth).length;
    final averageDays = monthlyData.isNotEmpty
        ? (monthlyData.map((m) => m.days).reduce((a, b) => a + b) /
            monthlyData.length)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '総出勤日数',
                value: '$totalDays日',
                icon: Icons.calendar_today,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: '達成月',
                value: '$qualifyingMonths月',
                icon: Icons.check_circle,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: '月平均',
                value: '${averageDays.toStringAsFixed(1)}日',
                icon: Icons.trending_up,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '月別出勤日数',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: TutorialKeys.barChart,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: monthlyData.isEmpty
                    ? const Center(child: Text('データがありません'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toInt()}日',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < monthlyData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${monthlyData[value.toInt()].month}月',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value % 5 == 0) {
                                    return Text(
                                      '${value.toInt()}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) {
                              if (value == AppConstants.requiredDaysPerMonth) {
                                return FlLine(
                                  color: colorScheme.error.withValues(alpha: 0.5),
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                );
                              }
                              return FlLine(
                                color: colorScheme.outlineVariant,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              monthlyData.asMap().entries.map((entry) {
                            final isQualified = entry.value.days >=
                                AppConstants.requiredDaysPerMonth;
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.days.toDouble(),
                                  color: isQualified
                                      ? colorScheme.tertiary
                                      : colorScheme.primary,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 16,
              height: 3,
              color: colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '${AppConstants.requiredDaysPerMonth}日ライン（達成基準）',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  List<_MonthlyDataPoint> _getMonthlyData(List attendance, DateTime? startDate) {
    if (startDate == null) return [];

    final now = DateTime.now();
    final List<_MonthlyDataPoint> data = [];
    DateTime current = DateTime(startDate.year, startDate.month, 1);

    while (current.isBefore(now) ||
        (current.year == now.year && current.month == now.month)) {
      final daysInMonth = attendance
          .where((r) => r.date.year == current.year && r.date.month == current.month)
          .length;
      data.add(_MonthlyDataPoint(
        year: current.year,
        month: current.month,
        days: daysInMonth,
      ));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return data.length > 12 ? data.sublist(data.length - 12) : data;
  }

  Widget _buildEditModeSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '出勤実績モード',
              selected: _editMode == EditMode.attendance,
              child: InkWell(
                onTap: () => setState(() => _editMode = EditMode.attendance),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _editMode == EditMode.attendance
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '出勤実績',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _editMode == EditMode.attendance
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: '出勤予定モード',
              selected: _editMode == EditMode.schedule,
              child: InkWell(
                onTap: () => setState(() => _editMode = EditMode.schedule),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _editMode == EditMode.schedule
                        ? colorScheme.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '出勤予定',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _editMode == EditMode.schedule
                          ? colorScheme.onSecondary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildDayCell(
    BuildContext context,
    DateTime day,
    Set<DateTime> markedDates,
    Set<DateTime> scheduledDates,
    List<int> scheduledWeekdays, {
    required Map<DateTime, List<AttendanceRecord>> attendanceByDate,
    required Map<String?, Color> workplaceColors,
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final isMarked = markedDates.contains(normalizedDay);
    final isWeekdayScheduled = scheduledWeekdays.contains(day.weekday);
    final isDateOverridden = scheduledDates.contains(normalizedDay);
    // XOR: 固定曜日と個別指定が排他的に動作
    // - 固定曜日に含まれる日をタップ → 例外的に休み
    // - 固定曜日に含まれない日をタップ → 例外的に出勤
    final isScheduled = isWeekdayScheduled != isDateOverridden;
    final isHoliday = JapaneseHolidays.isHoliday(day);
    final isSunday = day.weekday == DateTime.sunday;
    final isSaturday = day.weekday == DateTime.saturday;
    final isRedDay = isSunday || isHoliday;

    // Get workplace colors for this day
    final dayRecords = attendanceByDate[normalizedDay] ?? [];
    final dayWorkplaceColors = dayRecords
        .map((r) => workplaceColors[r.workplaceId] ?? colorScheme.primary)
        .toSet()
        .toList();
    final hasMultipleWorkplaces = dayWorkplaceColors.length > 1;
    final primaryDayColor = dayWorkplaceColors.isNotEmpty
        ? dayWorkplaceColors.first
        : colorScheme.primary;

    Color? textColor;
    if (isMarked) {
      textColor = Colors.white;
    } else if (isRedDay) {
      textColor = Colors.red;
    } else if (isSaturday) {
      textColor = colorScheme.tertiary;
    } else if (isScheduled) {
      textColor = colorScheme.secondary;
    } else if (isToday) {
      textColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isMarked
            ? primaryDayColor
            : isScheduled && !isMarked
                ? colorScheme.secondary.withValues(alpha: 0.2)
                : isToday
                    ? colorScheme.primaryContainer
                    : null,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: colorScheme.primary, width: 2)
            : isScheduled && !isMarked
                ? Border.all(color: colorScheme.secondary, width: 2)
                : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 複数勤務先の場合、下に小さなドットで示す
          if (isMarked && hasMultipleWorkplaces)
            Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: dayWorkplaceColors.skip(1).take(2).map((color) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isMarked || isToday || isRedDay ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme, List<Workplace> workplaces) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            // 勤務先がある場合は勤務先別の色を表示
            if (workplaces.isNotEmpty)
              ...workplaces.map((wp) => _legendItem(Color(wp.colorValue), wp.name))
            else
              _legendItem(colorScheme.primary, '出勤済み'),
            _legendItem(colorScheme.secondary.withValues(alpha: 0.2), '予定', borderColor: colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {Color? borderColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  int _getScheduledDaysInMonth(
    int year,
    int month,
    Set<DateTime> scheduledDates,
    List<int> scheduledWeekdays,
  ) {
    int count = 0;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    for (var day = firstDay;
        day.isBefore(lastDay) || day.isAtSameMomentAs(lastDay);
        day = day.add(const Duration(days: 1))) {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final isWeekdayScheduled = scheduledWeekdays.contains(day.weekday);
      final isDateOverridden = scheduledDates.contains(normalizedDay);
      // XOR logic
      if (isWeekdayScheduled != isDateOverridden) {
        count++;
      }
    }
    return count;
  }

  void _showScheduleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ScheduleSettingsSheet(),
    );
  }
}

class _MonthlyDataPoint {
  final int year;
  final int month;
  final int days;

  _MonthlyDataPoint({
    required this.year,
    required this.month,
    required this.days,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

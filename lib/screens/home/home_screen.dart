import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/japanese_holidays.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/progress_provider.dart';
import 'widgets/progress_card.dart';
import 'widgets/monthly_status_card.dart';
import 'widgets/schedule_settings_sheet.dart';

enum EditMode { attendance, schedule }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  EditMode _editMode = EditMode.attendance;

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider.notifier);
    final schedule = ref.watch(scheduleProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final markedDates = attendance.getMarkedDates();
    final scheduledDates = schedule.getScheduledDates();
    final colorScheme = Theme.of(context).colorScheme;

    final scheduledWeekdays = settings?.scheduledWeekdays ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('出勤カウント'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: '予定設定',
            onPressed: () => _showScheduleSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (progress != null) ...[
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
            _buildEditModeSelector(colorScheme),
            const SizedBox(height: 8),
            Card(
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
                      await ref.read(attendanceProvider.notifier).toggleDate(selectedDay);
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
            const SizedBox(height: 8),
            _buildLegend(colorScheme),
          ],
        ),
      ),
    );
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
    List<int> scheduledWeekdays,
    {required bool isToday}
  ) {
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
            ? colorScheme.primary
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
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isMarked || isToday || isRedDay ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
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

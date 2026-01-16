import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/sync_provider.dart';
import '../../services/firestore_sync_service.dart';

class PartnerViewScreen extends ConsumerStatefulWidget {
  final String shareCode;

  const PartnerViewScreen({super.key, required this.shareCode});

  @override
  ConsumerState<PartnerViewScreen> createState() => _PartnerViewScreenState();
}

class _PartnerViewScreenState extends ConsumerState<PartnerViewScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final partnerData = ref.watch(partnerDataProvider(widget.shareCode));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('パートナーの進捗'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.orange.shade900,
      ),
      body: partnerData.when(
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text('データが見つかりませんでした'),
            );
          }
          return _buildContent(context, data, colorScheme);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(partnerDataProvider(widget.shareCode)),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SharedData data, ColorScheme colorScheme) {
    final markedDates = data.attendanceDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final scheduledDates = data.scheduledDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final scheduledWeekdays = data.scheduledWeekdays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 進捗カード
          Card(
            elevation: 4,
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.orange.shade700, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        '${data.qualifyingMonths}/12ヶ月達成',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: data.qualifyingMonths / 12,
                    backgroundColor: Colors.orange.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  if (data.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '最終更新: ${DateFormat('yyyy/MM/dd HH:mm').format(data.updatedAt!)}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 今月の状況
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${_focusedDay.year}年${_focusedDay.month}月',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        context,
                        '出勤日数',
                        _getDaysWorkedInMonth(
                          _focusedDay.year,
                          _focusedDay.month,
                          markedDates,
                        ).toString(),
                        colorScheme.primary,
                      ),
                      _buildStatItem(
                        context,
                        '予定日数',
                        _getScheduledDaysInMonth(
                          _focusedDay.year,
                          _focusedDay.month,
                          scheduledDates,
                          scheduledWeekdays,
                        ).toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // カレンダー
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
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildDayCell(
                      context,
                      day,
                      markedDates,
                      scheduledDates,
                      scheduledWeekdays,
                      colorScheme,
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
                      colorScheme,
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

          // 凡例
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _legendItem(colorScheme.primary, '出勤済み'),
                  _legendItem(Colors.orange.withValues(alpha: 0.2), '予定',
                      borderColor: Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 閲覧専用の注意書き
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '閲覧専用モードです。パートナーがデータを更新すると自動で反映されます。',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    Set<DateTime> markedDates,
    Set<DateTime> scheduledDates,
    List<int> scheduledWeekdays,
    ColorScheme colorScheme, {
    required bool isToday,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final isMarked = markedDates.contains(normalizedDay);
    final isWeekdayScheduled = scheduledWeekdays.contains(day.weekday);
    final isDateOverridden = scheduledDates.contains(normalizedDay);
    final isScheduled = isWeekdayScheduled != isDateOverridden;
    final isSunday = day.weekday == DateTime.sunday;
    final isSaturday = day.weekday == DateTime.saturday;

    Color? textColor;
    if (isMarked) {
      textColor = Colors.white;
    } else if (isSunday) {
      textColor = Colors.red;
    } else if (isSaturday) {
      textColor = Colors.blue;
    } else if (isScheduled) {
      textColor = Colors.orange.shade800;
    } else if (isToday) {
      textColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isMarked
            ? colorScheme.primary
            : isScheduled && !isMarked
                ? Colors.orange.withValues(alpha: 0.2)
                : isToday
                    ? colorScheme.primaryContainer
                    : null,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: colorScheme.primary, width: 2)
            : isScheduled && !isMarked
                ? Border.all(color: Colors.orange, width: 2)
                : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isMarked || isToday || isSunday ? FontWeight.bold : null,
          ),
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
            border:
                borderColor != null ? Border.all(color: borderColor, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  int _getDaysWorkedInMonth(int year, int month, Set<DateTime> markedDates) {
    return markedDates.where((d) => d.year == year && d.month == month).length;
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
      if (isWeekdayScheduled != isDateOverridden) {
        count++;
      }
    }
    return count;
  }
}

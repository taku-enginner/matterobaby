import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/workplace.dart';
import '../../../providers/weekly_hours_provider.dart';
import '../../../providers/workplace_provider.dart';

class Step1ProgressCard extends ConsumerWidget {
  final WeeklyHoursData currentWeek;
  final List<WeeklyHoursData> recentWeeks;

  const Step1ProgressCard({
    super.key,
    required this.currentWeek,
    required this.recentWeeks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final workplaces = ref.watch(workplaceProvider);
    final isGoalMet = currentWeek.isGoalMet;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isGoalMet ? Icons.check_circle : Icons.schedule,
                  color: isGoalMet ? colorScheme.tertiary : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '今週の勤務時間',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current week progress - centered circular progress
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: currentWeek.progressRatio,
                        strokeWidth: 12,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          isGoalMet ? colorScheme.tertiary : colorScheme.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(currentWeek.progressRatio * 100).toInt()}%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isGoalMet
                                    ? colorScheme.tertiary
                                    : colorScheme.primary,
                              ),
                        ),
                        Text(
                          '${currentWeek.totalHours.toStringAsFixed(1)} / ${currentWeek.goalHours.toStringAsFixed(0)}h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status text
            Center(
              child: Text(
                isGoalMet
                    ? '今週の目標達成！'
                    : 'あと${(currentWeek.goalHours - currentWeek.totalHours).toStringAsFixed(1)}時間',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isGoalMet
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily breakdown
            _buildDailyBreakdown(context, currentWeek, workplaces),

            // Workplace breakdown (only show if there are workplaces)
            if (workplaces.isNotEmpty &&
                currentWeek.hoursByWorkplace.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWorkplaceBreakdown(context, currentWeek, workplaces),
            ],

            const Divider(height: 24),

            // Weekly chart
            Text(
              '過去の週間勤務時間',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _buildWeeklyChart(context, workplaces),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown(
    BuildContext context,
    WeeklyHoursData week,
    List<Workplace> workplaces,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const dayNames = ['月', '火', '水', '木', '金', '土', '日'];

    // Build a map for quick workplace color lookup
    final workplaceColors = <String?, Color>{};
    for (final wp in workplaces) {
      workplaceColors[wp.id] = Color(wp.colorValue);
    }

    return Row(
      children: List.generate(7, (index) {
        final day = week.dailyRecords[index];
        final hasWork = day.totalHours > 0;
        final isToday = _isSameDay(day.date, DateTime.now());

        // Get colors for this day's entries
        final dayColors = <Color>[];
        for (final entry in day.entries) {
          final color = workplaceColors[entry.workplaceId] ?? colorScheme.primary;
          dayColors.add(color);
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: hasWork
                  ? (dayColors.isNotEmpty
                      ? dayColors.first.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.1))
                  : isToday
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null,
              borderRadius: BorderRadius.circular(4),
              border: isToday
                  ? Border.all(color: colorScheme.primary, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayNames[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: hasWork
                        ? (dayColors.isNotEmpty ? dayColors.first : colorScheme.primary)
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(height: 2),
                // Color indicator bar for multiple workplaces
                if (hasWork && dayColors.length > 1) ...[
                  SizedBox(
                    height: 4,
                    child: Row(
                      children: dayColors.map((color) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  hasWork ? '${day.totalHours.toStringAsFixed(0)}h' : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasWork ? FontWeight.bold : null,
                    color: hasWork
                        ? (dayColors.isNotEmpty ? dayColors.first : colorScheme.primary)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWorkplaceBreakdown(
    BuildContext context,
    WeeklyHoursData week,
    List<Workplace> workplaces,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Sort workplaces by hours (descending)
    final sortedEntries = week.hoursByWorkplace.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Filter out entries with 0 hours
    final nonZeroEntries = sortedEntries.where((e) => e.value > 0).toList();

    if (nonZeroEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今週の内訳',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ...nonZeroEntries.map((entry) {
            final workplace = workplaces.where((w) => w.id == entry.key).firstOrNull;
            final color = workplace != null
                ? Color(workplace.colorValue)
                : colorScheme.primary;
            final name = workplace?.name ?? '未分類';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}時間',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<Workplace> workplaces) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayWeeks = recentWeeks.take(8).toList().reversed.toList();

    if (displayWeeks.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    // Build workplace color map
    final workplaceColors = <String?, Color>{};
    final workplaceNames = <String?, String>{};
    for (final wp in workplaces) {
      workplaceColors[wp.id] = Color(wp.colorValue);
      workplaceNames[wp.id] = wp.name;
    }

    // Collect all workplace IDs that appear in the data
    final allWorkplaceIds = <String?>{};
    for (final week in displayWeeks) {
      allWorkplaceIds.addAll(week.hoursByWorkplace.keys);
    }
    final sortedWorkplaceIds = allWorkplaceIds.toList();

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 30,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final week = displayWeeks[groupIndex];
                    // Show breakdown in tooltip
                    final lines = <String>['合計: ${week.totalHours.toStringAsFixed(1)}h'];
                    for (final entry in week.hoursByWorkplace.entries) {
                      if (entry.value > 0) {
                        final name = workplaceNames[entry.key] ?? '未分類';
                        lines.add('$name: ${entry.value.toStringAsFixed(1)}h');
                      }
                    }
                    return BarTooltipItem(
                      lines.join('\n'),
                      const TextStyle(color: Colors.white, fontSize: 10),
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
                      if (value.toInt() < displayWeeks.length) {
                        final week = displayWeeks[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('M/d').format(week.weekStart),
                                style: const TextStyle(fontSize: 8),
                              ),
                              Text(
                                '${week.totalHours.toStringAsFixed(0)}h',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: week.isGoalMet
                                      ? colorScheme.tertiary
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  if (value == 20) {
                    return FlLine(
                      color: colorScheme.tertiary.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  }
                  return FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: displayWeeks.asMap().entries.map((weekEntry) {
                final week = weekEntry.value;

                // Build stacked rod data for each workplace
                final rodStackItems = <BarChartRodStackItem>[];
                double currentY = 0;

                for (final wpId in sortedWorkplaceIds) {
                  final hours = week.hoursByWorkplace[wpId] ?? 0;
                  if (hours > 0) {
                    final color = workplaceColors[wpId] ?? colorScheme.primary;
                    rodStackItems.add(BarChartRodStackItem(
                      currentY,
                      currentY + hours,
                      color,
                    ));
                    currentY += hours;
                  }
                }

                // If no workplace data, use single color
                if (rodStackItems.isEmpty && week.totalHours > 0) {
                  rodStackItems.add(BarChartRodStackItem(
                    0,
                    week.totalHours,
                    week.isGoalMet ? colorScheme.tertiary : colorScheme.primary,
                  ));
                }

                return BarChartGroupData(
                  x: weekEntry.key,
                  barRods: [
                    BarChartRodData(
                      toY: week.totalHours,
                      rodStackItems: rodStackItems,
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
        // Legend for workplaces
        if (workplaces.isNotEmpty && allWorkplaceIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: workplaces
                .where((wp) => allWorkplaceIds.contains(wp.id))
                .map((wp) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(wp.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          wp.name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

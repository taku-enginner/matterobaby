import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/settings_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final monthlyData = _getMonthlyData(attendance, settings?.periodStartDate);
    final totalDays = attendance.length;
    final qualifyingMonths = monthlyData.where((m) => m.days >= AppConstants.requiredDaysPerMonth).length;
    final averageDays = monthlyData.isNotEmpty
        ? (monthlyData.map((m) => m.days).reduce((a, b) => a + b) / monthlyData.length)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                    color: Colors.green,
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
            Card(
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
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
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
                                    color: Colors.red.withOpacity(0.5),
                                    strokeWidth: 2,
                                    dashArray: [5, 5],
                                  );
                                }
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: monthlyData.asMap().entries.map((entry) {
                              final isQualified = entry.value.days >= AppConstants.requiredDaysPerMonth;
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.days.toDouble(),
                                    color: isQualified ? Colors.green : colorScheme.primary,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppConstants.requiredDaysPerMonth}日ライン（達成基準）',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '達成月一覧',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: monthlyData.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = monthlyData[monthlyData.length - 1 - index];
                  final isQualified = data.days >= AppConstants.requiredDaysPerMonth;
                  return ListTile(
                    leading: Icon(
                      isQualified ? Icons.check_circle : Icons.circle_outlined,
                      color: isQualified ? Colors.green : Colors.grey,
                    ),
                    title: Text('${data.year}年${data.month}月'),
                    trailing: Text(
                      '${data.days}日',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isQualified ? Colors.green : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MonthlyDataPoint> _getMonthlyData(List attendance, DateTime? startDate) {
    if (startDate == null) return [];

    final now = DateTime.now();
    final List<_MonthlyDataPoint> data = [];
    DateTime current = DateTime(startDate.year, startDate.month, 1);

    while (current.isBefore(now) || (current.year == now.year && current.month == now.month)) {
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

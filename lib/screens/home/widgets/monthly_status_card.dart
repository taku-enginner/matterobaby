import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';

class MonthlyStatusCard extends StatelessWidget {
  final int year;
  final int month;
  final int daysWorked;
  final int daysScheduled;

  const MonthlyStatusCard({
    super.key,
    required this.year,
    required this.month,
    required this.daysWorked,
    this.daysScheduled = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isQualified = daysWorked >= AppConstants.requiredDaysPerMonth;
    final progress = daysWorked / AppConstants.requiredDaysPerMonth;
    final monthName = DateFormat.MMMM('ja_JP').format(DateTime(year, month));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$year年$monthName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isQualified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '達成!',
                      style: TextStyle(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (daysScheduled / AppConstants.requiredDaysPerMonth).clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isQualified ? colorScheme.tertiary : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$daysWorked / ${AppConstants.requiredDaysPerMonth}日',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isQualified ? colorScheme.tertiary : colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isQualified)
                  Text(
                    'あと${AppConstants.requiredDaysPerMonth - daysWorked}日で達成',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  const SizedBox.shrink(),
                if (daysScheduled > 0)
                  Text(
                    '予定: $daysScheduled日',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

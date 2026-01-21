import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep; // 1 or 2
  final VoidCallback? onStep1Tap;
  final VoidCallback? onStep2Tap;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.onStep1Tap,
    this.onStep2Tap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // STEP 1
            Expanded(
              child: _StepItem(
                step: 1,
                title: '雇用保険加入',
                subtitle: '週20時間以上',
                isActive: currentStep == 1,
                isCompleted: currentStep > 1,
                onTap: onStep1Tap,
              ),
            ),
            // Connector line
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentStep > 1
                        ? [colorScheme.tertiary, colorScheme.tertiary]
                        : [colorScheme.primary, colorScheme.outline],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // STEP 2
            Expanded(
              child: _StepItem(
                step: 2,
                title: '育休取得',
                subtitle: '月11日×12ヶ月',
                isActive: currentStep == 2,
                isCompleted: false,
                onTap: onStep2Tap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepItem({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;
    Color numberColor;

    if (isCompleted) {
      backgroundColor = colorScheme.tertiary;
      textColor = colorScheme.onSurface;
      numberColor = Colors.white;
    } else if (isActive) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onSurface;
      numberColor = Colors.white;
    } else {
      backgroundColor = colorScheme.outline;
      textColor = colorScheme.onSurfaceVariant;
      numberColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: numberColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: isActive ? FontWeight.bold : null,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/settings_provider.dart';

class ScheduleSettingsSheet extends ConsumerStatefulWidget {
  const ScheduleSettingsSheet({super.key});

  @override
  ConsumerState<ScheduleSettingsSheet> createState() =>
      _ScheduleSettingsSheetState();
}

class _ScheduleSettingsSheetState extends ConsumerState<ScheduleSettingsSheet> {
  late List<int> _selectedWeekdays;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedWeekdays = List.from(settings?.scheduledWeekdays ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '定期出勤曜日',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '毎週出勤する曜日を選択すると、カレンダーに自動で予定が表示されます',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildWeekdayChip(1, '月'),
                  _buildWeekdayChip(2, '火'),
                  _buildWeekdayChip(3, '水'),
                  _buildWeekdayChip(4, '木'),
                  _buildWeekdayChip(5, '金'),
                  _buildWeekdayChip(6, '土'),
                  _buildWeekdayChip(7, '日'),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedWeekdays.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '週${_selectedWeekdays.length}日出勤 → 月約${(_selectedWeekdays.length * 4.3).round()}日',
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('保存'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedWeekdays.clear();
                    });
                  },
                  child: const Text('クリア'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayChip(int weekday, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? colorScheme.onSecondary : null,
        ),
      ),
      selected: isSelected,
      selectedColor: colorScheme.secondary,
      checkmarkColor: colorScheme.onSecondary,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
          _selectedWeekdays.sort();
        });
      },
    );
  }

  Future<void> _saveSettings() async {
    await ref.read(settingsProvider.notifier).setScheduledWeekdays(_selectedWeekdays);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定期出勤曜日を保存しました')),
      );
    }
  }
}

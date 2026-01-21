import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/workplace.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/workplace_provider.dart';

/// 勤務入力シートの結果
class WorkEntryResult {
  final String? workplaceId;
  final double workHours;

  WorkEntryResult({
    this.workplaceId,
    required this.workHours,
  });
}

/// 勤務入力シートを表示
Future<WorkEntryResult?> showWorkEntrySheet(
  BuildContext context, {
  required DateTime date,
  String? initialWorkplaceId,
  double? initialHours,
}) async {
  return showModalBottomSheet<WorkEntryResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => WorkEntrySheet(
      date: date,
      initialWorkplaceId: initialWorkplaceId,
      initialHours: initialHours,
    ),
  );
}

class WorkEntrySheet extends ConsumerStatefulWidget {
  final DateTime date;
  final String? initialWorkplaceId;
  final double? initialHours;

  const WorkEntrySheet({
    super.key,
    required this.date,
    this.initialWorkplaceId,
    this.initialHours,
  });

  @override
  ConsumerState<WorkEntrySheet> createState() => _WorkEntrySheetState();
}

class _WorkEntrySheetState extends ConsumerState<WorkEntrySheet> {
  String? _selectedWorkplaceId;
  late double _workHours;

  @override
  void initState() {
    super.initState();
    _selectedWorkplaceId = widget.initialWorkplaceId;
    _workHours = widget.initialHours ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_workHours == 0) {
      final settings = ref.read(settingsProvider);
      _workHours = settings?.defaultWorkHours ?? 8.0;
    }
    if (_selectedWorkplaceId == null) {
      final defaultWorkplace = ref.read(workplaceProvider.notifier).defaultWorkplace;
      _selectedWorkplaceId = defaultWorkplace?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final workplaces = ref.watch(workplaceProvider);
    final existingRecords = ref.watch(attendanceProvider)
        .where((r) => r.dateKey == _formatDateKey(widget.date))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.work, color: colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '勤務を記録',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      DateFormat.yMMMd('ja_JP').format(widget.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 既存の記録がある場合は表示
            if (existingRecords.isNotEmpty) ...[
              Text(
                'この日の記録',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...existingRecords.map((record) {
                final workplace = workplaces.firstWhere(
                  (w) => w.id == record.workplaceId,
                  orElse: () => Workplace(
                    id: '',
                    name: '未設定',
                    colorValue: Colors.grey.toARGB32(),
                    createdAt: DateTime.now(),
                  ),
                );
                final hours = record.workHours ?? ref.read(settingsProvider)?.defaultWorkHours ?? 8.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(workplace.colorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(workplace.colorValue).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(workplace.colorValue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(workplace.name),
                        ),
                        Text('${hours.toStringAsFixed(1)}時間'),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 24),
              Text(
                '追加の勤務を記録',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
            ],

            // 勤務先選択
            if (workplaces.isNotEmpty) ...[
              Text(
                '勤務先',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workplaces.map((workplace) {
                  final isSelected = _selectedWorkplaceId == workplace.id;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(workplace.name),
                    avatar: CircleAvatar(
                      backgroundColor: Color(workplace.colorValue),
                      radius: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedWorkplaceId = selected ? workplace.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 勤務時間
            Text(
              '勤務時間',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _workHours,
                    min: 0.5,
                    max: 12,
                    divisions: 23,
                    label: '${_workHours.toStringAsFixed(1)}時間',
                    onChanged: (value) {
                      setState(() {
                        _workHours = (value * 2).round() / 2; // 0.5時間刻み
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${_workHours.toStringAsFixed(1)}時間',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        WorkEntryResult(
                          workplaceId: _selectedWorkplaceId,
                          workHours: _workHours,
                        ),
                      );
                    },
                    child: const Text('記録する'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

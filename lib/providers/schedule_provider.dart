import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/schedule_datasource.dart';
import '../data/models/scheduled_work.dart';

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduledWork>>((ref) {
  return ScheduleNotifier();
});

class ScheduleNotifier extends StateNotifier<List<ScheduledWork>> {
  ScheduleNotifier() : super([]);

  final _datasource = ScheduleDatasource();

  Future<void> init() async {
    final data = await _datasource.getAll();
    state = data.map((e) => ScheduledWork.fromJson(e)).toList();
  }

  bool isDateScheduled(DateTime date) {
    final dateKey = _formatDateKey(date);
    return state.any((record) => record.dateKey == dateKey);
  }

  Future<void> toggleDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final existing = state.where((r) => r.dateKey == dateKey).toList();

    if (existing.isNotEmpty) {
      for (final record in existing) {
        await _datasource.delete(record.id);
      }
    } else {
      await _datasource.create(DateTime(date.year, date.month, date.day));
    }
    await init();
  }

  Future<void> addDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final existing = state.where((r) => r.dateKey == dateKey).toList();

    if (existing.isEmpty) {
      await _datasource.create(DateTime(date.year, date.month, date.day));
      await init();
    }
  }

  Future<void> removeDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final existing = state.where((r) => r.dateKey == dateKey).toList();

    for (final record in existing) {
      await _datasource.delete(record.id);
    }
    await init();
  }

  Set<DateTime> getScheduledDates() {
    return state.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();
  }

  int getScheduledDaysInMonth(int year, int month) {
    return state
        .where((r) => r.date.year == year && r.date.month == month)
        .length;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

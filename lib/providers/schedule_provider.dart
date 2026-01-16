import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/scheduled_work.dart';

const _boxName = 'scheduled_work';

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduledWork>>((ref) {
  return ScheduleNotifier();
});

class ScheduleNotifier extends StateNotifier<List<ScheduledWork>> {
  ScheduleNotifier() : super([]);

  Box<ScheduledWork>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<ScheduledWork>(_boxName);
    state = _box!.values.toList();
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
        await _box?.delete(record.key);
      }
      state = _box!.values.toList();
    } else {
      final record = ScheduledWork(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        createdAt: DateTime.now(),
      );
      await _box?.add(record);
      state = _box!.values.toList();
    }
  }

  Future<void> addDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final existing = state.where((r) => r.dateKey == dateKey).toList();

    if (existing.isEmpty) {
      final record = ScheduledWork(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        createdAt: DateTime.now(),
      );
      await _box?.add(record);
      state = _box!.values.toList();
    }
  }

  Future<void> removeDate(DateTime date) async {
    final dateKey = _formatDateKey(date);
    final existing = state.where((r) => r.dateKey == dateKey).toList();

    for (final record in existing) {
      await _box?.delete(record.key);
    }
    state = _box!.values.toList();
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

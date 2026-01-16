import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/attendance_record.dart';

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
  return AttendanceNotifier();
});

class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  AttendanceNotifier() : super([]);

  Box<AttendanceRecord>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<AttendanceRecord>(AppConstants.attendanceBoxName);
    state = _box!.values.toList();
  }

  bool isDateMarked(DateTime date) {
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
      final record = AttendanceRecord(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        createdAt: DateTime.now(),
      );
      await _box?.add(record);
      state = _box!.values.toList();
    }
  }

  int getDaysWorkedInMonth(int year, int month) {
    return state
        .where((r) => r.date.year == year && r.date.month == month)
        .length;
  }

  Set<DateTime> getMarkedDates() {
    return state.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

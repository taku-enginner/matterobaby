import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/attendance_datasource.dart';
import '../data/models/attendance_record.dart';

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
  return AttendanceNotifier();
});

class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  AttendanceNotifier() : super([]);

  final _datasource = AttendanceDatasource();

  Future<void> init() async {
    final data = await _datasource.getAll();
    state = data.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Future<void> reload() async {
    await init();
  }

  Future<void> clearAll() async {
    for (final record in state) {
      await _datasource.delete(record.id);
    }
    state = [];
  }

  Future<void> markStampsAsUsed(String spinId, int count) async {
    final unusedData = await _datasource.getUnusedForSpin(limit: count);
    if (unusedData.isEmpty) return;

    final ids = unusedData.map((e) => e['id'] as String).toList();
    await _datasource.markAsUsedForSpin(ids, spinId);
    await reload();
  }

  int get unusedStampCount => state.where((r) => !r.isUsed).length;

  bool isDateMarked(DateTime date) {
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
      await _datasource.create(
        date: DateTime(date.year, date.month, date.day),
      );
    }
    await reload();
  }

  Future<AttendanceRecord> addWorkEntry({
    required DateTime date,
    String? workplaceId,
    double? workHours,
  }) async {
    final data = await _datasource.create(
      date: DateTime(date.year, date.month, date.day),
      workplaceId: workplaceId,
      workHours: workHours,
    );
    final record = AttendanceRecord.fromJson(data);
    await reload();
    return record;
  }

  Future<void> updateWorkEntry({
    required AttendanceRecord record,
    String? workplaceId,
    double? workHours,
  }) async {
    await _datasource.update(record.id, {
      'workplace_id': workplaceId,
      'work_hours': workHours,
    });
    await reload();
  }

  Future<void> deleteWorkEntry(AttendanceRecord record) async {
    await _datasource.delete(record.id);
    await reload();
  }

  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return state.where((r) => r.dateKey == dateKey).toList();
  }

  List<AttendanceRecord> getRecordsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return state.where((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList();
  }

  int getDaysWorkedInMonth(int year, int month) {
    final uniqueDates = state
        .where((r) => r.date.year == year && r.date.month == month)
        .map((r) => r.dateKey)
        .toSet();
    return uniqueDates.length;
  }

  Set<DateTime> getMarkedDates() {
    return state.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();
  }

  List<DateTime> getRecentRecords(int count) {
    final sorted = List<AttendanceRecord>.from(state)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted
        .take(count)
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toList();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

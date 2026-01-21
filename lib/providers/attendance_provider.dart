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
    await _migrateExistingStamps();
  }

  /// 既存のスタンプデータを移行（一度だけ実行）
  Future<void> _migrateExistingStamps() async {
    final pointBox = await Hive.openBox(AppConstants.pointBoxName);
    final spinsUsed = (pointBox.get('spinsUsed', defaultValue: 0) ?? 0) as int;
    final migrated = (pointBox.get('stampsMigrated', defaultValue: false) ?? false) as bool;

    if (migrated || spinsUsed == 0) return;

    // 古い順にスタンプをソート
    final sortedRecords = List<AttendanceRecord>.from(state)
      ..sort((a, b) => a.date.compareTo(b.date));

    // spinsUsed * 3 個の最古のスタンプを使用済みにマーク
    final stampsToMark = spinsUsed * AppConstants.stampsPerSpin;
    for (var i = 0; i < stampsToMark && i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      if (!record.isUsed) {
        // マイグレーション用のプレースホルダーIDでマーク
        final migrationSpinId = 'migration-${i ~/ AppConstants.stampsPerSpin}';
        await _updateRecordSpinId(record, migrationSpinId);
      }
    }

    await pointBox.put('stampsMigrated', true);
    state = _box!.values.toList();
  }

  /// スタンプを使用済みにマーク
  Future<void> markStampsAsUsed(String spinId, int count) async {
    // 未使用スタンプを取得（古い順）
    final unusedStamps = state
        .where((r) => !r.isUsed)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 指定された数だけマーク
    final toMark = unusedStamps.take(count);
    for (final record in toMark) {
      await _updateRecordSpinId(record, spinId);
    }

    state = _box!.values.toList();
  }

  /// レコードのusedForSpinIdを更新
  Future<void> _updateRecordSpinId(AttendanceRecord record, String spinId) async {
    final updatedRecord = record.copyWith(usedForSpinId: spinId);
    // Hiveでは同じキーに上書きする
    final key = record.key;
    if (key != null) {
      await _box?.put(key, updatedRecord);
    }
  }

  /// 未使用スタンプの数を取得
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

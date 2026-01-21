import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 0)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3, defaultValue: null)
  final String? usedForSpinId;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.createdAt,
    this.usedForSpinId,
  });

  bool get isUsed => usedForSpinId != null;

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? createdAt,
    String? usedForSpinId,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      usedForSpinId: usedForSpinId ?? this.usedForSpinId,
    );
  }

  String get monthKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}

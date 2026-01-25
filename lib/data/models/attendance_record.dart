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

  @HiveField(4, defaultValue: null)
  final String? workplaceId;

  @HiveField(5, defaultValue: null)
  final double? workHours;

  @HiveField(6, defaultValue: 0.0)
  final double stampRotation;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.createdAt,
    this.usedForSpinId,
    this.workplaceId,
    this.workHours,
    this.stampRotation = 0.0,
  });

  bool get isUsed => usedForSpinId != null;

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? createdAt,
    String? usedForSpinId,
    String? workplaceId,
    double? workHours,
    double? stampRotation,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      usedForSpinId: usedForSpinId ?? this.usedForSpinId,
      workplaceId: workplaceId ?? this.workplaceId,
      workHours: workHours ?? this.workHours,
      stampRotation: stampRotation ?? this.stampRotation,
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

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
      usedForSpinId: json['used_for_spin_id'],
      workplaceId: json['workplace_id'],
      workHours: (json['work_hours'] as num?)?.toDouble(),
      stampRotation: (json['stamp_rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'used_for_spin_id': usedForSpinId,
      'workplace_id': workplaceId,
      'work_hours': workHours,
      'stamp_rotation': stampRotation,
    };
  }
}

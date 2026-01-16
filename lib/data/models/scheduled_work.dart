import 'package:hive/hive.dart';

part 'scheduled_work.g.dart';

@HiveType(typeId: 2)
class ScheduledWork extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final DateTime createdAt;

  ScheduledWork({
    required this.id,
    required this.date,
    required this.createdAt,
  });

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledWork &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}

import 'package:hive/hive.dart';

part 'reward.g.dart';

@HiveType(typeId: 3)
class Reward extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? memo;

  @HiveField(3)
  final String? imagePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  Reward({
    required this.id,
    required this.name,
    this.memo,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Reward copyWith({
    String? name,
    String? memo,
    String? imagePath,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reward && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      memo: json['memo'],
      imagePath: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'memo': memo,
      'image_url': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

import 'package:hive/hive.dart';

part 'workplace.g.dart';

@HiveType(typeId: 5)
class Workplace extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4, defaultValue: false)
  final bool isDefault;

  Workplace({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.isDefault = false,
  });

  Workplace copyWith({
    String? name,
    int? colorValue,
    bool? isDefault,
  }) {
    return Workplace(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workplace && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Workplace.fromJson(Map<String, dynamic> json) {
    return Workplace(
      id: json['id'],
      name: json['name'],
      colorValue: json['color_value'],
      createdAt: DateTime.parse(json['created_at']),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault,
    };
  }
}

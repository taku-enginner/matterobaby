import 'package:hive/hive.dart';

part 'gacha_history.g.dart';

@HiveType(typeId: 4)
class GachaHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rewardId;

  @HiveField(2)
  final String rewardName;

  @HiveField(3)
  final DateTime spunAt;

  @HiveField(4, defaultValue: false)
  final bool isTestMode;

  GachaHistory({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.spunAt,
    this.isTestMode = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GachaHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory GachaHistory.fromJson(Map<String, dynamic> json) {
    return GachaHistory(
      id: json['id'],
      rewardId: json['reward_id'] ?? '',
      rewardName: json['reward_name'],
      spunAt: DateTime.parse(json['spun_at']),
      isTestMode: json['is_test_mode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reward_id': rewardId,
      'reward_name': rewardName,
      'spun_at': spunAt.toIso8601String(),
      'is_test_mode': isTestMode,
    };
  }
}

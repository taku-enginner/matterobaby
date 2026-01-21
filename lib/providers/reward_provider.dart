import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/reward.dart';
import '../services/image_storage_service.dart';

final rewardProvider =
    StateNotifierProvider<RewardNotifier, List<Reward>>((ref) {
  return RewardNotifier();
});

class RewardNotifier extends StateNotifier<List<Reward>> {
  RewardNotifier() : super([]);

  Box<Reward>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Reward>(AppConstants.rewardBoxName);
    state = _box!.values.toList();
  }

  Future<void> addReward({
    required String name,
    String? memo,
    String? imagePath,
  }) async {
    final reward = Reward(
      id: _uuid.v4(),
      name: name,
      memo: memo,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _box?.add(reward);
    state = _box!.values.toList();
  }

  Future<void> updateReward({
    required Reward reward,
    required String name,
    String? memo,
    String? imagePath,
  }) async {
    final oldImagePath = reward.imagePath;
    final updated = Reward(
      id: reward.id,
      name: name,
      memo: memo,
      imagePath: imagePath ?? oldImagePath,
      createdAt: reward.createdAt,
      updatedAt: DateTime.now(),
    );

    final index = _box!.values.toList().indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      await _box!.putAt(index, updated);

      if (imagePath != null && oldImagePath != null && imagePath != oldImagePath) {
        await ImageStorageService.deleteImage(oldImagePath);
      }
    }

    state = _box!.values.toList();
  }

  Future<void> deleteReward(Reward reward) async {
    if (reward.imagePath != null) {
      await ImageStorageService.deleteImage(reward.imagePath);
    }

    final index = _box!.values.toList().indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      await _box!.deleteAt(index);
    }

    state = _box!.values.toList();
  }

  Reward? getRewardById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

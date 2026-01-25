import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/reward_datasource.dart';
import '../data/models/reward.dart';

final rewardProvider =
    StateNotifierProvider<RewardNotifier, List<Reward>>((ref) {
  return RewardNotifier();
});

class RewardNotifier extends StateNotifier<List<Reward>> {
  RewardNotifier() : super([]);

  final _datasource = RewardDatasource();
  final _uuid = const Uuid();

  Future<void> init() async {
    final data = await _datasource.getAll();
    state = data.map((e) => Reward.fromJson(e)).toList();
  }

  Future<void> addReward({
    required String name,
    String? memo,
    String? imagePath,
  }) async {
    String? imageUrl;
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = imagePath.split('.').last;
        final fileName = '${_uuid.v4()}.$ext';
        imageUrl = await _datasource.uploadImage(fileName, bytes);
      }
    }

    await _datasource.create(
      name: name,
      memo: memo,
      imageUrl: imageUrl,
    );
    await init();
  }

  Future<void> updateReward({
    required Reward reward,
    required String name,
    String? memo,
    String? imagePath,
  }) async {
    String? imageUrl = reward.imagePath;

    if (imagePath != null && imagePath != reward.imagePath) {
      // New image selected
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = imagePath.split('.').last;
        final fileName = '${_uuid.v4()}.$ext';
        imageUrl = await _datasource.uploadImage(fileName, bytes);

        // Delete old image
        if (reward.imagePath != null) {
          await _datasource.deleteImage(reward.imagePath!);
        }
      }
    }

    await _datasource.update(reward.id, {
      'name': name,
      'memo': memo,
      'image_url': imageUrl,
    });
    await init();
  }

  Future<void> deleteReward(Reward reward) async {
    if (reward.imagePath != null) {
      await _datasource.deleteImage(reward.imagePath!);
    }
    await _datasource.delete(reward.id);
    await init();
  }

  Reward? getRewardById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

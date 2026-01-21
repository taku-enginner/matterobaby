import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/gacha_history.dart';
import '../data/models/reward.dart';
import 'attendance_provider.dart';
import 'reward_provider.dart';
import 'point_provider.dart';

final gachaHistoryProvider =
    StateNotifierProvider<GachaHistoryNotifier, List<GachaHistory>>((ref) {
  return GachaHistoryNotifier();
});

class GachaHistoryNotifier extends StateNotifier<List<GachaHistory>> {
  GachaHistoryNotifier() : super([]);

  Box<GachaHistory>? _box;
  final _uuid = const Uuid();
  final _random = Random();

  Future<void> init() async {
    _box = await Hive.openBox<GachaHistory>(AppConstants.gachaHistoryBoxName);
    state = _box!.values.toList()..sort((a, b) => b.spunAt.compareTo(a.spunAt));
  }

  Reward? spinGacha(List<Reward> rewards) {
    if (rewards.isEmpty) return null;

    final index = _random.nextInt(rewards.length);
    return rewards[index];
  }

  Future<void> recordSpin(Reward reward, {bool isTestMode = false, String? spinId}) async {
    final history = GachaHistory(
      id: spinId ?? _uuid.v4(),
      rewardId: reward.id,
      rewardName: reward.name,
      spunAt: DateTime.now(),
      isTestMode: isTestMode,
    );
    await _box?.add(history);
    state = _box!.values.toList()..sort((a, b) => b.spunAt.compareTo(a.spunAt));
  }

  /// 新しいスピンIDを生成
  String generateSpinId() => _uuid.v4();

  List<GachaHistory> getRecentHistory(int count) {
    return state.take(count).toList();
  }
}

final gachaServiceProvider = Provider((ref) {
  return GachaService(ref);
});

class GachaService {
  final Ref _ref;

  GachaService(this._ref);

  Future<Reward?> spin({bool testMode = false}) async {
    final rewards = _ref.read(rewardProvider);
    if (rewards.isEmpty) return null;

    final historyNotifier = _ref.read(gachaHistoryProvider.notifier);
    String? spinId;

    if (!testMode) {
      final success = await _ref.read(pointProvider.notifier).useSpin();
      if (!success) return null;

      // スピンIDを生成してスタンプを使用済みにマーク
      spinId = historyNotifier.generateSpinId();
      await _ref.read(attendanceProvider.notifier).markStampsAsUsed(
        spinId,
        AppConstants.stampsPerSpin,
      );
    }

    final winner = historyNotifier.spinGacha(rewards);

    if (winner != null) {
      await historyNotifier.recordSpin(winner, isTestMode: testMode, spinId: spinId);
    }

    return winner;
  }

  bool get canSpin {
    final pointState = _ref.read(pointProvider);
    final rewards = _ref.read(rewardProvider);
    return pointState.availableSpins > 0 && rewards.isNotEmpty;
  }
}

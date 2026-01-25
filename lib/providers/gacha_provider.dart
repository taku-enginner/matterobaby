import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/datasources/gacha_datasource.dart';
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

  final _datasource = GachaDatasource();
  final _uuid = const Uuid();
  final _random = Random();

  Future<void> init() async {
    final data = await _datasource.getAll();
    state = data.map((e) => GachaHistory.fromJson(e)).toList()
      ..sort((a, b) => b.spunAt.compareTo(a.spunAt));
  }

  Future<void> clearAll() async {
    await _datasource.deleteAll();
    state = [];
  }

  Reward? spinGacha(List<Reward> rewards) {
    if (rewards.isEmpty) return null;

    final index = _random.nextInt(rewards.length);
    return rewards[index];
  }

  Future<String> recordSpin(Reward reward, {bool isTestMode = false, String? spinId}) async {
    final id = spinId ?? _uuid.v4();
    await _datasource.create(
      rewardId: reward.id,
      rewardName: reward.name,
      isTestMode: isTestMode,
    );
    await init();
    return id;
  }

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

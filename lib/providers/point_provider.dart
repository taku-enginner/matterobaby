import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import 'attendance_provider.dart';

class PointState {
  final int totalPoints;
  final int availablePoints;
  final int spinsUsed;

  PointState({
    required this.totalPoints,
    required this.availablePoints,
    required this.spinsUsed,
  });

  int get currentStamps => availablePoints % AppConstants.stampsPerSpin;
  int get availableSpins => availablePoints ~/ AppConstants.stampsPerSpin;

  PointState copyWith({
    int? totalPoints,
    int? availablePoints,
    int? spinsUsed,
  }) {
    return PointState(
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      spinsUsed: spinsUsed ?? this.spinsUsed,
    );
  }
}

final pointProvider =
    StateNotifierProvider<PointNotifier, PointState>((ref) {
  return PointNotifier(ref);
});

class PointNotifier extends StateNotifier<PointState> {
  final Ref _ref;
  Box? _box;

  PointNotifier(this._ref)
      : super(PointState(
          totalPoints: 0,
          availablePoints: 0,
          spinsUsed: 0,
        ));

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.pointBoxName);
    syncWithAttendance();
  }

  void syncWithAttendance() {
    final attendance = _ref.read(attendanceProvider);
    final attendanceCount = attendance.length;
    // 未使用のスタンプ数をカウント
    final unusedCount = attendance.where((r) => !r.isUsed).length;

    state = PointState(
      totalPoints: attendanceCount,
      availablePoints: unusedCount,
      spinsUsed: attendanceCount - unusedCount,
    );
  }

  Future<bool> useSpin() async {
    if (state.availableSpins < 1) return false;

    final newSpinsUsed = state.spinsUsed + 1;
    await _box?.put('spinsUsed', newSpinsUsed);

    state = state.copyWith(
      spinsUsed: newSpinsUsed,
      availablePoints: state.availablePoints - AppConstants.stampsPerSpin,
    );
    return true;
  }
}

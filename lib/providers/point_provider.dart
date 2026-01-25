import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  PointNotifier(this._ref)
      : super(PointState(
          totalPoints: 0,
          availablePoints: 0,
          spinsUsed: 0,
        ));

  Future<void> init() async {
    syncWithAttendance();
  }

  void syncWithAttendance() {
    final attendance = _ref.read(attendanceProvider);
    final attendanceCount = attendance.length;
    final unusedCount = attendance.where((r) => !r.isUsed).length;

    state = PointState(
      totalPoints: attendanceCount,
      availablePoints: unusedCount,
      spinsUsed: attendanceCount - unusedCount,
    );
  }

  Future<bool> useSpin() async {
    if (state.availableSpins < 1) return false;

    state = state.copyWith(
      spinsUsed: state.spinsUsed + 1,
      availablePoints: state.availablePoints - AppConstants.stampsPerSpin,
    );
    return true;
  }
}

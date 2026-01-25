import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tutorial/tutorial_keys.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/point_provider.dart';
import '../../providers/workplace_provider.dart';
import '../rewards/widgets/stamp_overlay.dart';
import 'widgets/checkin_button.dart';
import 'widgets/ripple_effect.dart';
import 'widgets/work_entry_sheet.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  late ConfettiController _confettiController;
  final GlobalKey<RippleEffectState> _rippleKey = GlobalKey();
  double? _lastStampRotation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleCheckin() async {
    final today = DateTime.now();
    final workplaces = ref.read(workplaceProvider);

    // 勤務先が登録されている場合はシートを表示
    if (workplaces.isNotEmpty) {
      final result = await showWorkEntrySheet(context, date: today);
      if (result == null) return; // キャンセルされた

      final record = await ref.read(attendanceProvider.notifier).addWorkEntry(
            date: today,
            workplaceId: result.workplaceId,
            workHours: result.workHours,
          );
      _lastStampRotation = record.stampRotation;
    } else {
      // 勤務先がない場合は従来の動作
      final record = await ref.read(attendanceProvider.notifier).addWorkEntry(
            date: today,
          );
      _lastStampRotation = record.stampRotation;
    }

    // Sync points with attendance
    ref.read(pointProvider.notifier).syncWithAttendance();

    // Trigger celebration effects
    _rippleKey.currentState?.startRipple();
    _confettiController.play();

    // スタンプオーバーレイを表示
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _showStampOverlay();
      }
    });
  }

  void _showStampOverlay() {
    final pointState = ref.read(pointProvider);
    showStampOverlay(
      context,
      currentStamps: pointState.currentStamps,
      totalStamps: AppConstants.stampsPerSpin,
      stampRotation: _lastStampRotation,
      onComplete: () {
        // オーバーレイ完了後にごほうびタブに移動
        ref.read(tabIndexProvider.notifier).state = 2;
      },
    );
  }

  // デバッグ用：スタンプアニメーションをテスト
  void _testStampAnimation() {
    showStampOverlay(
      context,
      currentStamps: 3, // テスト用の値
      totalStamps: AppConstants.stampsPerSpin,
      onComplete: () {
        // テスト時は遷移しない
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 状態を監視して変更時に再ビルド
    ref.watch(attendanceProvider);
    final attendance = ref.read(attendanceProvider.notifier);
    final today = DateTime.now();
    final isCheckedIn = attendance.isDateMarked(today);
    final daysThisMonth = attendance.getDaysWorkedInMonth(today.year, today.month);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // デバッグモードでのみスタンプアニメーションテストボタンを表示
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              onPressed: _testStampAnimation,
              tooltip: 'Test Stamp Animation',
              child: const Icon(Icons.bug_report),
            )
          : null,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Progress header
                _buildProgressHeader(context, daysThisMonth),
                const Spacer(),
                // Checkin button
                Center(
                  child: KeyedSubtree(
                    key: TutorialKeys.checkinButton,
                    child: CheckinButton(
                      isCheckedIn: isCheckedIn,
                      onPressed: _handleCheckin,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Hint text
                Text(
                  isCheckedIn
                      ? '今日の出勤は記録済みです'
                      : 'ボタンをタップして出勤を記録',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Recent records
                _buildRecentRecords(context, attendance),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Ripple effect overlay
          Positioned.fill(
            child: RippleEffect(key: _rippleKey),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.pink,
                Colors.orange,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, int daysThisMonth) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthName = DateFormat.MMMM('ja_JP').format(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            monthName,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$daysThisMonth',
                  style: TextStyle(
                    color: daysThisMonth >= 11
                        ? colorScheme.tertiary
                        : colorScheme.primary,
                  ),
                ),
                const TextSpan(text: ' / 11日'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (daysThisMonth / 11).clamp(0.0, 1.0),
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              daysThisMonth >= 11 ? colorScheme.tertiary : colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords(BuildContext context, AttendanceNotifier attendance) {
    final colorScheme = Theme.of(context).colorScheme;
    final records = attendance.getRecentRecords(5);

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '出勤記録はまだありません',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近の出勤',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: records.map((date) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

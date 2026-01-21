import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tutorial/tutorial_keys.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/gacha_provider.dart';
import '../../providers/point_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/stamp_page_provider.dart';
import '../rewards/widgets/gacha_flow_overlay.dart';
import '../rewards/widgets/stamp_card.dart';

class StampCardScreen extends ConsumerStatefulWidget {
  const StampCardScreen({super.key});

  @override
  ConsumerState<StampCardScreen> createState() => _StampCardScreenState();
}

class _StampCardScreenState extends ConsumerState<StampCardScreen> {
  bool _testMode = false;
  int _testModeTapCount = 0;
  DateTime? _lastTapTime;

  static const _enableTestMode = bool.fromEnvironment('ENABLE_TEST_MODE');

  void _handleTitleTap() {
    if (!_enableTestMode && kReleaseMode) return;

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      _testModeTapCount++;
      if (_testModeTapCount >= 5) {
        setState(() {
          _testMode = !_testMode;
          _testModeTapCount = 0;
        });
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_testMode ? 'テストモード ON' : 'テストモード OFF'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      _testModeTapCount = 1;
    }
    _lastTapTime = now;
  }

  Future<void> _addTestStamp() async {
    final attendanceNotifier = ref.read(attendanceProvider.notifier);
    final existingDates = attendanceNotifier.getMarkedDates();

    DateTime testDate;
    var attempts = 0;
    do {
      final randomDays =
          (DateTime.now().millisecondsSinceEpoch + attempts * 17) % 365;
      testDate = DateTime.now().subtract(Duration(days: randomDays));
      testDate = DateTime(testDate.year, testDate.month, testDate.day);
      attempts++;
    } while (existingDates.contains(testDate) && attempts < 365);

    await attendanceNotifier.toggleDate(testDate);
    ref.read(pointProvider.notifier).syncWithAttendance();

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('テストスタンプ追加 (${testDate.month}/${testDate.day})'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _handleStartGacha() async {
    final rewards = ref.read(rewardProvider);

    if (rewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ごほうびを先に登録してください')),
      );
      return;
    }

    if (!mounted) return;

    await showGachaFlowOverlay(
      context,
      testMode: false,
      onComplete: () {},
    );
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データリセット'),
        content: const Text(
            'すべてのデータ（出勤記録、ガチャ履歴、ポイント）を削除します。\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(attendanceProvider.notifier).clearAll();
    await ref.read(gachaHistoryProvider.notifier).clearAll();

    final pointBox = await Hive.openBox(AppConstants.pointBoxName);
    await pointBox.clear();

    ref.read(pointProvider.notifier).syncWithAttendance();

    if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データをリセットしました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pointState = ref.watch(pointProvider);
    final rewards = ref.watch(rewardProvider);
    final pages = ref.watch(stampPagesProvider);

    final currentPage = pages.isNotEmpty ? pages.last : null;
    final currentStamps =
        currentPage?.slots.where((s) => s.isStamped).length ?? 0;

    final canSpin =
        _testMode || (pointState.availableSpins > 0 && rewards.isNotEmpty);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // テストモード用タップエリア（画面上部を5回連続タップで有効化）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTitleTap,
                child: Container(
                  width: double.infinity,
                  height: _testMode ? null : 24,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: _testMode ? colorScheme.error : Colors.transparent,
                  child: _testMode
                      ? Text(
                          'TEST MODE（タップで解除）',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              KeyedSubtree(
                key: TutorialKeys.stampCard,
                child: StampCard(testMode: _testMode),
              ),
            const SizedBox(height: 16),
            // ガラガラポンを回すボタン
            KeyedSubtree(
              key: TutorialKeys.gachaButton,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: canSpin ? _handleStartGacha : null,
                    icon: const Icon(Icons.casino, size: 28),
                    label: Text(
                      canSpin
                          ? 'ガラガラポンを回す（${pointState.availableSpins}回）'
                          : rewards.isEmpty
                              ? 'ごほうびを登録してください'
                              : 'あと${math.max(0, AppConstants.stampsPerSpin - currentStamps)}個スタンプを貯めよう',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: colorScheme.onTertiary,
                      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            if (_testMode) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addTestStamp,
                        icon: const Icon(Icons.add),
                        label: const Text('テストスタンプ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final rewards = ref.read(rewardProvider);
                          if (rewards.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ごほうびを先に登録してください')),
                            );
                            return;
                          }
                          await showGachaFlowOverlay(
                            context,
                            testMode: true,
                            onComplete: () {},
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('フローテスト'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetAllData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('データをリセット'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

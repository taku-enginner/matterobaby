import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/point_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/stamp_page_provider.dart';
import 'widgets/gacha_flow_overlay.dart';
import 'widgets/reward_list_section.dart';
import 'widgets/stamp_card.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _testMode = false;
  int _testModeTapCount = 0;
  DateTime? _lastTapTime;

  // ビルド時に --dart-define=ENABLE_TEST_MODE=true で有効化
  static const _enableTestMode = bool.fromEnvironment('ENABLE_TEST_MODE');

  void _handleTitleTap() {
    // テストモードが無効化されている場合はスキップ
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
      testMode: _testMode,
      onComplete: () {
        // 完了後の処理
      },
    );
  }

  void _addTestStamp() {
    // テスト用のスタンプを追加（実際の出勤記録を追加）
    final attendanceNotifier = ref.read(attendanceProvider.notifier);
    // ランダムな過去の日付を追加
    final randomDays = DateTime.now().millisecondsSinceEpoch % 100;
    final testDate = DateTime.now().subtract(Duration(days: randomDays));
    attendanceNotifier.toggleDate(testDate);

    // ポイントを同期
    ref.read(pointProvider.notifier).syncWithAttendance();

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('テストスタンプ追加 (${testDate.month}/${testDate.day})'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pointState = ref.watch(pointProvider);
    final rewards = ref.watch(rewardProvider);
    final pages = ref.watch(stampPagesProvider);

    // 現在のページ（最後のページ）のスタンプ数
    final currentPage = pages.isNotEmpty ? pages.last : null;
    final currentStamps = currentPage?.slots.where((s) => s.isStamped).length ?? 0;

    // テストモードでは常にボタンを活性化（ご褒美がない場合はメッセージ表示）
    final canSpin = _testMode ||
        (pointState.availableSpins > 0 && rewards.isNotEmpty);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ごほうび'),
              if (_testMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TEST',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StampCard(testMode: _testMode),
            const SizedBox(height: 16),

            // ガラガラポンを回すボタン
            Padding(
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
                        : currentStamps < 3
                            ? 'あと${3 - currentStamps}個スタンプを貯めよう'
                            : 'ごほうびを登録してください',
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

            // テストモード時のテストボタン
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
                        label: const Text('テストスタンプ追加'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // テストフローを実行（スタンプが足りなくても）
                          final rewards = ref.read(rewardProvider);
                          if (rewards.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ごほうびを先に登録してください')),
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
            ],

            const SizedBox(height: 24),
            const RewardListSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

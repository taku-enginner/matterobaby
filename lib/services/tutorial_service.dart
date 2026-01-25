import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/tutorial/tutorial_keys.dart';

/// Scroll the target widget into view if it's inside a scrollable
Future<void> _scrollToTarget(GlobalKey key) async {
  final context = key.currentContext;
  if (context != null) {
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3, // Show target at 30% from top
    );
  }
}

class TutorialStep {
  final GlobalKey key;
  final String title;
  final String description;
  final int tabIndex;
  final ContentAlign align;

  TutorialStep({
    required this.key,
    required this.title,
    required this.description,
    required this.tabIndex,
    this.align = ContentAlign.bottom,
  });
}

class TutorialService {
  TutorialCoachMark? _tutorialCoachMark;

  final List<TutorialStep> _steps = [
    // Tab 0: 記録
    TutorialStep(
      key: TutorialKeys.checkinButton,
      title: '出勤記録',
      description: 'タップして今日の出勤を記録します。\n勤務先と勤務時間を選択できます。',
      tabIndex: 0,
    ),

    // Tab 1: 進捗
    TutorialStep(
      key: TutorialKeys.progressCard,
      title: 'ステップ表示',
      description: 'STEP1: 雇用保険加入（週20時間以上）\nSTEP2: 育休取得（月11日×12ヶ月）\n現在のステップと進捗を確認できます。',
      tabIndex: 1,
    ),
    TutorialStep(
      key: TutorialKeys.editModeSelector,
      title: 'モード切替',
      description: '「出勤実績」: 記録を確認できます\n「出勤予定」: 予定を追加・削除できます',
      tabIndex: 1,
    ),
    TutorialStep(
      key: TutorialKeys.calendar,
      title: 'カレンダー',
      description: '出勤した日をタップすると\n詳細（勤務先・時間）を確認できます。\n予定モードでは予定の追加・削除ができます。',
      tabIndex: 1,
      align: ContentAlign.bottom,
    ),
    TutorialStep(
      key: TutorialKeys.scheduleSettingsButton,
      title: '予定設定',
      description: '毎週の出勤曜日を設定できます。\n固定シフトがある場合に便利です。',
      tabIndex: 1,
    ),
    TutorialStep(
      key: TutorialKeys.barChart,
      title: '月別グラフ',
      description: '月ごとの出勤日数を表示。\n11日以上で1ヶ月達成としてカウントされます。',
      tabIndex: 1,
      align: ContentAlign.top,
    ),

    // Tab 2: スタンプ
    TutorialStep(
      key: TutorialKeys.stampCard,
      title: 'スタンプカード',
      description: '出勤するとスタンプが貯まります。\n3個貯めるとガラガラポンが回せます！',
      tabIndex: 2,
    ),
    TutorialStep(
      key: TutorialKeys.gachaButton,
      title: 'ガラガラポン',
      description: 'スタンプが3個貯まったら\nここをタップしてガラガラポンを回せます。',
      tabIndex: 2,
      align: ContentAlign.top,
    ),

    // Tab 3: ごほうび
    TutorialStep(
      key: TutorialKeys.rewardList,
      title: 'ごほうびリスト',
      description: 'ガチャで当たるごほうびを登録します。\n自分へのご褒美を設定しましょう！',
      tabIndex: 3,
    ),

    // Tab 4: 設定
    TutorialStep(
      key: TutorialKeys.workplaceSettings,
      title: '勤務先設定',
      description: '複数の勤務先（掛け持ち）を\n登録できます。色分けで見やすく管理。',
      tabIndex: 4,
    ),
    TutorialStep(
      key: TutorialKeys.periodStartDate,
      title: '開始日設定',
      description: '育休取得の基準となる\n2年間の開始日を設定します。',
      tabIndex: 4,
    ),
  ];

  void showTutorial({
    required BuildContext context,
    required void Function(int tabIndex) onTabChange,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    final targets = <TargetFocus>[];
    final colorScheme = Theme.of(context).colorScheme;

    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final isLast = i == _steps.length - 1;

      targets.add(
        TargetFocus(
          identify: 'target_$i',
          keyTarget: step.key,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: step.align,
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${i + 1} / ${_steps.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          Row(
                            children: [
                              if (!isLast)
                                TextButton(
                                  onPressed: () {
                                    controller.skip();
                                  },
                                  child: Text(
                                    'スキップ',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  // Check if next step needs tab change
                                  if (i < _steps.length - 1) {
                                    final nextStep = _steps[i + 1];
                                    if (nextStep.tabIndex != step.tabIndex) {
                                      onTabChange(nextStep.tabIndex);
                                      // Delay to let the tab switch complete
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      await _scrollToTarget(nextStep.key);
                                      await Future.delayed(const Duration(milliseconds: 100));
                                      controller.next();
                                      return;
                                    }
                                    // Same tab, scroll to next target
                                    await _scrollToTarget(nextStep.key);
                                    await Future.delayed(const Duration(milliseconds: 100));
                                  }
                                  controller.next();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                ),
                                child: Text(isLast ? '完了' : '次へ'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 8,
        ),
      );
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: colorScheme.primary.withValues(alpha: 0.8),
      textSkip: 'スキップ',
      paddingFocus: 8,
      opacityShadow: 0.9,
      onClickTarget: (target) async {
        final index = int.parse(target.identify.toString().split('_').last);
        if (index < _steps.length - 1) {
          final nextStep = _steps[index + 1];
          if (nextStep.tabIndex != _steps[index].tabIndex) {
            onTabChange(nextStep.tabIndex);
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await _scrollToTarget(nextStep.key);
        }
      },
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
      onSkip: () {
        onSkip();
        return true;
      },
      onFinish: () {
        onFinish();
      },
    );

    // Start on checkin tab
    onTabChange(0);

    // Show the tutorial
    _tutorialCoachMark?.show(context: context);
  }

  void dispose() {
    _tutorialCoachMark?.finish();
  }
}

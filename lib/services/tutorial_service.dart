import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/tutorial/tutorial_keys.dart';

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
    TutorialStep(
      key: TutorialKeys.progressCard,
      title: '進捗表示',
      description: '育休取得に必要な12ヶ月のうち、\n達成した月数を表示します',
      tabIndex: 0,
    ),
    TutorialStep(
      key: TutorialKeys.editModeSelector,
      title: '編集モード切替',
      description: '「出勤実績」で実際の出勤日を、\n「出勤予定」で予定を記録できます',
      tabIndex: 0,
    ),
    TutorialStep(
      key: TutorialKeys.calendar,
      title: 'カレンダー',
      description: '日付をタップして出勤日を記録。\nもう一度タップで取り消し',
      tabIndex: 0,
      align: ContentAlign.top,
    ),
    TutorialStep(
      key: TutorialKeys.scheduleSettingsButton,
      title: '予定設定',
      description: '毎週の出勤曜日を設定できます',
      tabIndex: 0,
    ),
    TutorialStep(
      key: TutorialKeys.barChart,
      title: '月別グラフ',
      description: '月ごとの出勤日数を表示。\n11日以上で1ヶ月達成としてカウント',
      tabIndex: 1,
    ),
    TutorialStep(
      key: TutorialKeys.periodStartDate,
      title: '開始日設定',
      description: '育休取得の基準となる\n2年間の開始日を設定',
      tabIndex: 2,
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
                                onPressed: () {
                                  // Check if next step needs tab change
                                  if (i < _steps.length - 1) {
                                    final nextStep = _steps[i + 1];
                                    if (nextStep.tabIndex != step.tabIndex) {
                                      onTabChange(nextStep.tabIndex);
                                      // Delay to let the tab switch complete
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        controller.next();
                                      });
                                      return;
                                    }
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
      onClickTarget: (target) {
        final index = int.parse(target.identify.toString().split('_').last);
        if (index < _steps.length - 1) {
          final nextStep = _steps[index + 1];
          if (nextStep.tabIndex != _steps[index].tabIndex) {
            onTabChange(nextStep.tabIndex);
          }
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

    // Start on home tab
    onTabChange(0);

    // Show the tutorial
    _tutorialCoachMark?.show(context: context);
  }

  void dispose() {
    _tutorialCoachMark?.finish();
  }
}

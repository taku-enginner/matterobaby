import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/point_provider.dart';
import '../../../providers/stamp_page_provider.dart';

class StampCard extends ConsumerStatefulWidget {
  final bool testMode;

  const StampCard({
    super.key,
    this.testMode = false,
  });

  @override
  ConsumerState<StampCard> createState() => _StampCardState();
}

class _StampCardState extends ConsumerState<StampCard> {
  bool _animateStamp = false;
  final PageController _pageController = PageController();
  int _currentCardIndex = 0;
  int _previousCardCount = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pointState = ref.watch(pointProvider);
    final pages = ref.watch(stampPagesProvider);

    // スタンプアニメーションのトリガーを監視
    ref.listen<bool>(stampAnimationTriggerProvider, (previous, next) {
      if (next && !widget.testMode) {
        setState(() {
          _animateStamp = true;
        });
        HapticFeedback.heavyImpact();
        ref.read(stampAnimationTriggerProvider.notifier).state = false;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _animateStamp = false;
            });
          }
        });
      }
    });

    final spins = pointState.availableSpins;

    // 全スタンプを収集（使用済み・未使用両方）
    final allStampsList = <_StampInfo>[];
    for (final page in pages) {
      for (final slot in page.slots) {
        if (slot.isStamped) {
          allStampsList.add(_StampInfo(slot: slot, isUsed: page.isUsed));
        }
      }
    }
    // 日付でソート（古い順）
    allStampsList.sort((a, b) =>
        (a.slot.stampDate ?? DateTime(2000)).compareTo(b.slot.stampDate ?? DateTime(2000)));

    // 未使用スタンプ数をカウント
    final unusedStamps = allStampsList.where((s) => !s.isUsed).length;

    // カードに分割（30スタンプごと）
    final cards = <List<_StampInfo>>[];
    final slotsPerCard = AppConstants.stampCardSlots;

    for (var i = 0; i < allStampsList.length; i += slotsPerCard) {
      final end = (i + slotsPerCard).clamp(0, allStampsList.length);
      cards.add(allStampsList.sublist(i, end));
    }

    // 最低1枚のカードを表示
    if (cards.isEmpty) {
      cards.add([]);
    }

    final totalCards = cards.length;

    // 新しいカードが追加された時のみ最新カードに自動移動
    if (totalCards > _previousCardCount && _previousCardCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            totalCards - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
    _previousCardCount = totalCards;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'スタンプカード',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (totalCards > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_currentCardIndex + 1}/$totalCards',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$spins回',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // カードページビュー（矢印ボタン付き）
          SizedBox(
            height: _calculateCardHeight(),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: totalCards,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCardIndex = index;
                    });
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, cardIndex) {
                    final cardStamps = cards[cardIndex];
                    final isLastCard = cardIndex == totalCards - 1;
                    return _buildCardPage(
                      context,
                      cardStamps,
                      cardIndex,
                      isLastCard,
                    );
                  },
                ),
                // 左矢印
                if (totalCards > 1 && _currentCardIndex > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 40,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_left,
                          size: 32,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                // 右矢印
                if (totalCards > 1 && _currentCardIndex < totalCards - 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 40,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right,
                          size: 32,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ページインジケーター（タップ可能）
          if (totalCards > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalCards, (index) {
                final isActive = index == _currentCardIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          // ステータステキスト
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              _getStatusText(unusedStamps),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCardHeight() {
    const rows = 6;
    const spacing = 8.0;
    const maxStampSize = 55.0;
    // おおよその高さを計算
    return (maxStampSize * rows) + (spacing * (rows - 1));
  }

  Widget _buildCardPage(
    BuildContext context,
    List<_StampInfo> cardStamps,
    int cardIndex,
    bool isLastCard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 3;
          const spacing = 8.0;
          const maxStampSize = 55.0;
          final calculatedSize = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
          final stampSize = calculatedSize.clamp(0.0, maxStampSize);
          const rows = 6;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(rows, (rowIndex) {
              final startIdx = rowIndex * columns;

              // この行のスタンプを取得
              final rowStamps = <_StampInfo?>[];
              for (var i = 0; i < columns; i++) {
                final idx = startIdx + i;
                if (idx < cardStamps.length) {
                  rowStamps.add(cardStamps[idx]);
                } else {
                  rowStamps.add(null);
                }
              }

              // この行の使用済みスタンプ数をカウント
              final usedCount = rowStamps
                  .where((s) => s != null && s.isUsed)
                  .length;
              final stampedCount = rowStamps
                  .where((s) => s != null)
                  .length;
              final isRowUsed = usedCount == columns && stampedCount == columns;

              final rowWidth = stampSize * columns + spacing * (columns - 1);

              return Padding(
                padding: EdgeInsets.only(top: rowIndex > 0 ? spacing : 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(columns, (colIndex) {
                        final stampInfo = rowStamps[colIndex];
                        final shouldAnimate = _animateStamp &&
                            isLastCard &&
                            stampInfo != null &&
                            colIndex == (cardStamps.length - 1) % columns &&
                            rowIndex == (cardStamps.length - 1) ~/ columns;

                        return Padding(
                          padding: EdgeInsets.only(left: colIndex > 0 ? spacing : 0),
                          child: _MiniStamp(
                            isStamped: stampInfo != null,
                            animate: shouldAnimate,
                            size: stampSize,
                            stampDate: stampInfo?.slot.stampDate,
                          ),
                        );
                      }),
                    ),
                    // 3スタンプ使用済みなら行全体に取消線
                    if (isRowUsed)
                      SizedBox(
                        width: rowWidth,
                        height: stampSize,
                        child: CustomPaint(
                          painter: _RowStrikethroughPainter(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  String _getStatusText(int currentStamps) {
    final spinsAvailable = currentStamps ~/ AppConstants.stampsPerSpin;
    final remaining = currentStamps % AppConstants.stampsPerSpin;
    final needed = AppConstants.stampsPerSpin - remaining;

    if (spinsAvailable > 0) {
      if (remaining == 0) {
        return 'くじを$spinsAvailable回回せます！';
      }
      return 'くじ$spinsAvailable回可能！あと$needed回で+1回';
    }
    return 'あと$needed回出勤でくじ1回！';
  }
}

class _StampInfo {
  final StampSlotData slot;
  final bool isUsed;

  _StampInfo({required this.slot, required this.isUsed});
}

/// 小さいスタンプ
class _MiniStamp extends StatelessWidget {
  final bool isStamped;
  final bool animate;
  final double size;
  final DateTime? stampDate;

  const _MiniStamp({
    required this.isStamped,
    required this.animate,
    required this.size,
    this.stampDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isStamped) {
      // 空のスロット
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      );
    }

    // スタンプ済み
    return AnimatedScale(
      scale: animate ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFCC3333),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            stampDate != null
                ? '${stampDate!.month}/${stampDate!.day}'
                : '✓',
            maxLines: 1,
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFCC3333),
            ),
          ),
        ),
      ),
    );
  }
}

/// 行全体の取り消し線を描画するPainter
class _RowStrikethroughPainter extends CustomPainter {
  final Color color;

  _RowStrikethroughPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 行全体に横線
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

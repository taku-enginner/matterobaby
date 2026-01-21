import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/point_provider.dart';
import '../../../providers/stamp_page_provider.dart';
import 'stamp_item.dart';

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
  int _currentPageIndex = 0;
  bool _animateStamp = false;
  bool _initialPageSet = false;
  int _lastPageCount = 0;

  void _jumpToLastPage(int pageCount) {
    if (pageCount > 0) {
      final lastPage = pageCount - 1;
      if (_currentPageIndex != lastPage) {
        setState(() {
          _currentPageIndex = lastPage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pointState = ref.watch(pointProvider);
    final pages = ref.watch(stampPagesProvider);
    final pageCount = pages.length;

    // 初回またはページ数が増えたら最後のページに移動
    if (!_initialPageSet || pageCount > _lastPageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initialPageSet = true;
          _lastPageCount = pageCount;
          _jumpToLastPage(pageCount);
        }
      });
    }

    // スタンプアニメーションのトリガーを監視
    ref.listen<bool>(stampAnimationTriggerProvider, (previous, next) {
      if (next && !widget.testMode) {
        // 最後のページに移動してからアニメーション
        _jumpToLastPage(pageCount);
        setState(() {
          _animateStamp = true;
        });
        HapticFeedback.heavyImpact();
        // フラグをリセット
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

    // 現在のページのスタンプ数を計算
    final currentPage = pages.isNotEmpty && _currentPageIndex < pages.length
        ? pages[_currentPageIndex]
        : null;
    final currentStamps = currentPage?.slots.where((s) => s.isStamped).length ?? 0;
    final isCurrentPageUsed = currentPage?.isUsed ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        children: [
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'スタンプカード',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
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
          const SizedBox(height: 20),
          // ナビゲーションボタン（上部）
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左矢印ボタン
                Material(
                  color: _currentPageIndex > 0
                      ? colorScheme.surface.withValues(alpha: 0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _currentPageIndex > 0
                        ? () {
                            setState(() {
                              _currentPageIndex--;
                            });
                            HapticFeedback.selectionClick();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: _currentPageIndex > 0
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                          ),
                          if (_currentPageIndex > 0)
                            Text(
                              '前',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ページ番号
                Text(
                  '${_currentPageIndex + 1} / $pageCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                // 右矢印ボタン
                Material(
                  color: _currentPageIndex < pageCount - 1
                      ? colorScheme.surface.withValues(alpha: 0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _currentPageIndex < pageCount - 1
                        ? () {
                            setState(() {
                              _currentPageIndex++;
                            });
                            HapticFeedback.selectionClick();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentPageIndex < pageCount - 1)
                            Text(
                              '次',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: _currentPageIndex < pageCount - 1
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (pageCount > 1) const SizedBox(height: 12),
          // スタンプ表示
          SizedBox(
            height: 90,
            child: Builder(
              builder: (context) {
                final page = pages.isNotEmpty && _currentPageIndex < pages.length
                    ? pages[_currentPageIndex]
                    : null;
                if (page == null) {
                  return const SizedBox();
                }
                final isLastPage = _currentPageIndex == pageCount - 1;
                final isUsedPage = page.isUsed;

                return Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: page.slots.map((slot) {
                        final lastStampedIndex = page.slots
                            .lastIndexWhere((s) => s.isStamped);
                        final shouldAnimate = _animateStamp &&
                            isLastPage &&
                            slot.slotIndex == lastStampedIndex;

                        return StampItem(
                          isStamped: slot.isStamped,
                          isUsed: slot.isUsed,
                          animate: shouldAnimate,
                          index: slot.slotIndex,
                          stampDate: slot.stampDate,
                        );
                      }).toList(),
                    ),
                    // 使用済みページには横線を1本引く
                    if (isUsedPage)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _StrikethroughLinePainter(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // ステータステキスト
          Text(
            _getStatusText(currentStamps, isCurrentPageUsed, _currentPageIndex == pageCount - 1),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(int stamps, bool isUsed, bool isCurrentPage) {
    if (isUsed) {
      return '使用済み';
    }
    if (!isCurrentPage) {
      return '$stamps個のスタンプ';
    }
    if (stamps >= AppConstants.stampsPerSpin) {
      return 'くじを回せます！';
    }
    return 'あと${AppConstants.stampsPerSpin - stamps}回出勤でくじ1回！';
  }
}

/// 横一本の取り消し線を描画するPainter
class _StrikethroughLinePainter extends CustomPainter {
  final Color color;

  _StrikethroughLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // 横一本線（スタンプの中心を通る）
    final y = size.height * 0.44;
    final margin = 20.0;
    canvas.drawLine(
      Offset(margin, y),
      Offset(size.width - margin, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

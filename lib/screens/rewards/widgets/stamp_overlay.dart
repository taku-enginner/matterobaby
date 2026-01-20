import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StampOverlay extends StatefulWidget {
  final int currentStamps; // 現在のスタンプ数（押した後）
  final int totalStamps; // 合計スタンプ数
  final VoidCallback onComplete;

  const StampOverlay({
    super.key,
    required this.currentStamps,
    required this.totalStamps,
    required this.onComplete,
  });

  @override
  State<StampOverlay> createState() => _StampOverlayState();
}

class _StampOverlayState extends State<StampOverlay>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _stampController;
  late AnimationController _impactController;
  late AnimationController _textController;
  late AnimationController _blinkController;
  late ConfettiController _confettiController;

  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardOpacityAnimation;
  // Z軸アニメーション（奥から手前へ）
  late Animation<double> _stampZScaleAnimation;
  late Animation<double> _stampOpacityAnimation;
  late Animation<double> _stampRotationXAnimation;
  late Animation<double> _impactAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _blinkAnimation;

  bool _isReadyToTap = false;

  @override
  void initState() {
    super.initState();

    // カード表示アニメーション
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // スタンプZ軸アニメーション（奥から手前へ）- ゆっくり
    _stampController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // インパクトアニメーション
    _impactController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // テキストアニメーション
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 点滅アニメーション（ループ）
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 紙吹雪
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // カードのスケール
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _cardOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    // Z軸スケール（遠く小さい → 近く大きい → 着地で通常サイズ）
    _stampZScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 1.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_stampController);

    // 透明度（遠くで薄い → 近くで濃い）
    _stampOpacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // X軸回転（手前に傾いている → 正面）
    _stampRotationXAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeOut),
    );

    // インパクト（着地のバウンス）
    _impactAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.92),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0),
        weight: 35,
      ),
    ]).animate(CurvedAnimation(
      parent: _impactController,
      curve: Curves.easeOut,
    ));

    // テキスト
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    // 滑らかな点滅アニメーション（sin波のような滑らかさ）
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // アニメーションシーケンス開始
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // 紙を表示
    await _cardController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // スタンプを表示してインパクト（ドン！）
    _stampController.value = 1.0;
    HapticFeedback.heavyImpact();
    _impactController.forward();
    _confettiController.play();

    await Future.delayed(const Duration(milliseconds: 100));

    // テキスト表示
    await _textController.forward();

    // 少し待ってからタップ待機状態に
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isReadyToTap = true;
      });
      // 点滅アニメーションをループ開始
      _blinkController.repeat(reverse: true);
    }
  }

  void _handleTap() {
    if (_isReadyToTap) {
      HapticFeedback.lightImpact();
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _stampController.dispose();
    _impactController.dispose();
    _textController.dispose();
    _blinkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final stampSize = size.width * 0.7; // 画面幅の70%

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black54,
        child: Stack(
        children: [
          // 背景の紙（フェードイン）
          Center(
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                return Opacity(
                  opacity: _cardOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _cardScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: stampSize + 60,
                height: stampSize + 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 紙のテクスチャ風の線
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PaperLinesPainter(
                          lineColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 大きなスタンプ（Z軸から押される）
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_stampController, _impactController]),
              builder: (context, child) {
                final isImpacting = _impactController.isAnimating;
                final zScale = isImpacting
                    ? _impactAnimation.value
                    : _stampZScaleAnimation.value;

                return Transform.scale(
                  scale: zScale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(_stampRotationXAnimation.value),
                    child: Opacity(
                      opacity: _stampOpacityAnimation.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // スタンプ本体（朱肉風）
                          Container(
                              width: stampSize,
                              height: stampSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFCC3333),
                                  width: 8,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        // 太くする用のストローク
                                        Text(
                                          DateFormat('M/d').format(DateTime.now()),
                                          style: GoogleFonts.kleeOne(
                                            fontSize: stampSize * 0.32,
                                            fontWeight: FontWeight.w700,
                                            height: 1.0,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 12
                                              ..color = const Color(0xFFCC3333),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('M/d').format(DateTime.now()),
                                          style: GoogleFonts.kleeOne(
                                            fontSize: stampSize * 0.32,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFCC3333),
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Stack(
                                      children: [
                                        Text(
                                          '出勤',
                                          style: GoogleFonts.kleeOne(
                                            fontSize: stampSize * 0.18,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 8
                                              ..color = const Color(0xFFCC3333),
                                          ),
                                        ),
                                        Text(
                                          '出勤',
                                          style: GoogleFonts.kleeOne(
                                            fontSize: stampSize * 0.18,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFCC3333),
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // メッセージ（下部）
          Positioned(
            bottom: size.height * 0.15,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _textScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Text(
                '${widget.currentStamps} / ${widget.totalStamps}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 「ドン！」エフェクト
          Center(
            child: AnimatedBuilder(
              animation: _impactController,
              builder: (context, child) {
                if (_impactController.value == 0) {
                  return const SizedBox.shrink();
                }
                // インパクト時に大きく表示して素早くフェードアウト
                final progress = _impactController.value;
                final scale = 1.0 + (1.5 * (1 - progress)); // 2.5 → 1.0
                final opacity = (1.0 - progress).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      'ドン！',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        shadows: [
                          Shadow(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                          const Shadow(
                            color: Colors.white,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 紙吹雪
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 30,
              minBlastForce: 10,
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
          // Tap here テキスト（滑らか点滅）
          if (_isReadyToTap)
            Positioned(
              bottom: size.height * 0.08,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _blinkController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _blinkAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

}

// 紙の横線を描くPainter
class _PaperLinesPainter extends CustomPainter {
  final Color lineColor;

  _PaperLinesPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const lineSpacing = 24.0;
    final startY = 40.0;

    for (double y = startY; y < size.height - 20; y += lineSpacing) {
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// オーバーレイを表示するヘルパー関数
Future<void> showStampOverlay(
  BuildContext context, {
  required int currentStamps,
  required int totalStamps,
  required VoidCallback onComplete,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return StampOverlay(
        currentStamps: currentStamps,
        totalStamps: totalStamps,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete();
        },
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StampItem extends StatefulWidget {
  final bool isStamped;
  final bool animate;
  final int index;
  final DateTime? stampDate;

  const StampItem({
    super.key,
    required this.isStamped,
    this.animate = false,
    required this.index,
    this.stampDate,
  });

  @override
  State<StampItem> createState() => _StampItemState();
}

class _StampItemState extends State<StampItem>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late AnimationController _impactController;

  late Animation<double> _dropAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // 落下アニメーション
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 着地時のインパクトアニメーション
    _impactController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 上から落ちてくる（-150 → 0）
    _dropAnimation = Tween<double>(begin: -150, end: 0).animate(
      CurvedAnimation(
        parent: _dropController,
        curve: Curves.easeIn,
      ),
    );

    // 落下中は少し小さく、着地で大きくなる
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropController,
        curve: Curves.easeIn,
      ),
    );

    // 着地時のバウンス
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_impactController);

    // 落下中に少し回転
    _rotationAnimation = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _dropController,
        curve: Curves.easeOut,
      ),
    );

    // 落下完了後にインパクトアニメーション
    _dropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _impactController.forward(from: 0);
      }
    });

    if (widget.isStamped && !widget.animate) {
      _dropController.value = 1.0;
      _impactController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(StampItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStamped && !oldWidget.isStamped && widget.animate) {
      // アニメーション開始
      _dropController.forward(from: 0);
    } else if (widget.isStamped && !_dropController.isCompleted) {
      _dropController.value = 1.0;
      _impactController.value = 1.0;
    } else if (!widget.isStamped && oldWidget.isStamped) {
      // リセット
      _dropController.reset();
      _impactController.reset();
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景の円（スタンプ台）
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: !widget.isStamped
                ? Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : null,
          ),
          // スタンプ（上から落ちてくる）
          if (widget.isStamped)
            AnimatedBuilder(
              animation: Listenable.merge([_dropController, _impactController]),
              builder: (context, child) {
                final bounce = _impactController.isAnimating || _impactController.isCompleted
                    ? _bounceAnimation.value
                    : _scaleAnimation.value;

                return Transform.translate(
                  offset: Offset(0, _dropAnimation.value),
                  child: Transform.scale(
                    scale: bounce,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFCC3333),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Text(
                              widget.stampDate != null
                                  ? DateFormat('M/d').format(widget.stampDate!)
                                  : '${widget.index + 1}',
                              style: GoogleFonts.kleeOne(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 3
                                  ..color = const Color(0xFFCC3333),
                              ),
                            ),
                            Text(
                              widget.stampDate != null
                                  ? DateFormat('M/d').format(widget.stampDate!)
                                  : '${widget.index + 1}',
                              style: GoogleFonts.kleeOne(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCC3333),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        if (widget.stampDate != null)
                          Stack(
                            children: [
                              Text(
                                '出勤',
                                style: GoogleFonts.kleeOne(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..color = const Color(0xFFCC3333),
                                ),
                              ),
                              Text(
                                '出勤',
                                style: GoogleFonts.kleeOne(
                                  fontSize: 11,
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
              ),
            ),
        ],
      ),
    );
  }
}

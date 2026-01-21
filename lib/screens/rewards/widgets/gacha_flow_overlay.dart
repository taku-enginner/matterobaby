import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/gacha_provider.dart';
import '../../../providers/stamp_page_provider.dart';
import 'gacha_result_dialog.dart';

/// ガチャフロー全体を管理するオーバーレイ
/// 1. スタンプカード表示（取り消し線アニメーション）
/// 2. ガラガラポン表示
class GachaFlowOverlay extends ConsumerStatefulWidget {
  final bool testMode;
  final VoidCallback onComplete;

  const GachaFlowOverlay({
    super.key,
    this.testMode = false,
    required this.onComplete,
  });

  @override
  ConsumerState<GachaFlowOverlay> createState() => _GachaFlowOverlayState();
}

enum _FlowPhase {
  stampCard,
  strikethrough,
  gachaMachine,
}

class _GachaFlowOverlayState extends ConsumerState<GachaFlowOverlay>
    with TickerProviderStateMixin {
  _FlowPhase _currentPhase = _FlowPhase.stampCard;

  // スタンプ取り消し線アニメーション
  late AnimationController _strikethroughController;

  // フェード遷移
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ガラガラポン
  double _drumRotation = 0;
  double _totalRotation = 0;
  bool _isSpinning = false;
  bool _ballDropping = false;
  double _handleAngle = 0;
  Offset? _lastPanPosition;
  AnimationController? _ballDropController;
  AnimationController? _autoSpinController;
  double _baseRotation = 0;

  static const double _requiredRotation = 4 * pi;

  // テスト用のスタンプデータ
  List<StampSlotData>? _testStampSlots;

  @override
  void initState() {
    super.initState();

    _strikethroughController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _ballDropController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ballDropController!.addListener(() {
      setState(() {});
    });

    _autoSpinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _autoSpinController!.addListener(() {
      setState(() {
        _drumRotation = _baseRotation + _autoSpinController!.value * 6 * pi;
        _handleAngle = _baseRotation + _autoSpinController!.value * 6 * pi;
      });
    });
    _autoSpinController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dropBall();
      }
    });

    // テストモードの場合はテスト用スタンプデータを生成
    if (widget.testMode) {
      _testStampSlots = List.generate(3, (i) => StampSlotData(
        slotIndex: i,
        stampDate: DateTime.now().subtract(Duration(days: 2 - i)),
        isStamped: true,
        isUsed: false,
      ));
    }

    // スタンプカード表示後、少し待ってから取り消し線アニメーション開始
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _startStrikethroughAnimation();
      }
    });
  }

  void _startStrikethroughAnimation() {
    setState(() {
      _currentPhase = _FlowPhase.strikethrough;
    });
    _strikethroughController.forward().then((_) {
      // 取り消し線完了後、ガラガラポンに遷移
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _transitionToGacha();
        }
      });
    });
  }

  void _transitionToGacha() {
    _fadeController.forward().then((_) {
      setState(() {
        _currentPhase = _FlowPhase.gachaMachine;
      });
      _fadeController.reverse();
    });
  }

  // ガラガラポンのハンドル操作
  void _onPanStart(DragStartDetails details) {
    if (_isSpinning) return;
    _lastPanPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSpinning || _lastPanPosition == null) return;

    final center = Offset(150, 140);
    final previous = _lastPanPosition! - center;
    final current = details.localPosition - center;

    final previousAngle = atan2(previous.dy, previous.dx);
    final currentAngle = atan2(current.dy, current.dx);
    var delta = currentAngle - previousAngle;

    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    if (delta > 0) {
      setState(() {
        _handleAngle += delta;
        _drumRotation += delta;
        _totalRotation += delta;
      });

      if ((_totalRotation * 10).floor() % 3 == 0) {
        HapticFeedback.selectionClick();
      }

      if (_totalRotation >= _requiredRotation && !_isSpinning) {
        _triggerSpin();
      }
    }

    _lastPanPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _triggerSpin() {
    setState(() {
      _isSpinning = true;
      _baseRotation = _drumRotation;
    });
    HapticFeedback.heavyImpact();
    _autoSpinController?.forward(from: 0);
  }

  void _dropBall() {
    setState(() {
      _ballDropping = true;
    });
    HapticFeedback.mediumImpact();
    _ballDropController?.forward(from: 0).then((_) async {
      // ガチャを実行
      final gacha = ref.read(gachaServiceProvider);
      final result = await gacha.spin(testMode: widget.testMode);

      if (result != null && mounted) {
        // 結果ダイアログを表示
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => GachaResultDialog(reward: result),
        );
      }

      // 完了
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _strikethroughController.dispose();
    _fadeController.dispose();
    _ballDropController?.dispose();
    _autoSpinController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // フェード用のオーバーレイ
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Container(
                color: Colors.black.withValues(alpha: _fadeAnimation.value),
              );
            },
          ),
          // コンテンツ
          if (_currentPhase == _FlowPhase.stampCard ||
              _currentPhase == _FlowPhase.strikethrough)
            _buildStampCardPhase(colorScheme),
          if (_currentPhase == _FlowPhase.gachaMachine)
            _buildGachaPhase(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStampCardPhase(ColorScheme colorScheme) {
    final pages = ref.watch(stampPagesProvider);
    // 全スタンプを収集し、未使用で古い順に stampsPerSpin 個を取得
    final allUnusedSlots = <StampSlotData>[];
    for (final page in pages) {
      if (!page.isUsed) {
        for (final slot in page.slots) {
          if (slot.isStamped) {
            allUnusedSlots.add(slot);
          }
        }
      }
    }
    allUnusedSlots.sort((a, b) =>
        (a.stampDate ?? DateTime(2000)).compareTo(b.stampDate ?? DateTime(2000)));
    final slots = widget.testMode
        ? _testStampSlots!
        : allUnusedSlots.take(AppConstants.stampsPerSpin).toList();

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'スタンプを使用',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            // スタンプ + 取り消し線
            SizedBox(
              height: 80,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: slots.asMap().entries.map((entry) {
                      final index = entry.key;
                      final slot = entry.value;
                      return _buildStamp(slot, index);
                    }).toList(),
                  ),
                  // 横一本の取り消し線アニメーション
                  if (_currentPhase == _FlowPhase.strikethrough)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _strikethroughController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _AnimatedHorizontalLinePainter(
                              progress: _strikethroughController.value,
                              color: Colors.grey.shade700,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _currentPhase == _FlowPhase.stampCard
                  ? 'ガラガラポンに使用します'
                  : '使用済み！',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStamp(StampSlotData slot, int index) {
    return SizedBox(
      width: 80,
      height: 80,
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
              Text(
                slot.stampDate != null
                    ? DateFormat('M/d').format(slot.stampDate!)
                    : '${index + 1}',
                style: GoogleFonts.kleeOne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFCC3333),
                  height: 1.0,
                ),
              ),
              if (slot.stampDate != null)
                Text(
                  '出勤',
                  style: GoogleFonts.kleeOne(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFCC3333),
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGachaPhase(ColorScheme colorScheme) {
    final progress = (_totalRotation / _requiredRotation).clamp(0.0, 1.0);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.tertiaryContainer,
              colorScheme.tertiaryContainer.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ガラガラポン',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            // ガラガラポン本体
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: 300,
                height: 280,
                child: CustomPaint(
                  painter: _GachaPonPainter(
                    drumRotation: _drumRotation,
                    handleAngle: _handleAngle,
                    ballDropProgress: Curves.bounceOut.transform(
                      _ballDropController?.value ?? 0,
                    ),
                    showBall: _ballDropping,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isSpinning) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 20,
                    color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ハンドルを回してね！',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(colorScheme.tertiary),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
            if (_isSpinning)
              Text(
                '回転中...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// アニメーション付き横線ペインター
class _AnimatedHorizontalLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedHorizontalLinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // 横一本線（スタンプの中心を通る）
    final y = size.height * 0.44;
    final margin = 20.0;
    final startX = margin;
    final endX = size.width - margin;

    // 左から右へ線を伸ばすアニメーション
    canvas.drawLine(
      Offset(startX, y),
      Offset(startX + (endX - startX) * progress, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedHorizontalLinePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// ガラガラポンのペインター（gacha_machine.dartからコピー）
class _GachaPonPainter extends CustomPainter {
  final double drumRotation;
  final double handleAngle;
  final double ballDropProgress;
  final bool showBall;
  final ColorScheme colorScheme;

  _GachaPonPainter({
    required this.drumRotation,
    required this.handleAngle,
    required this.ballDropProgress,
    required this.showBall,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final drumCenterY = 100.0;

    _drawBase(canvas, size);
    _drawStand(canvas, centerX, drumCenterY, size);
    _drawDrum(canvas, centerX, drumCenterY);
    _drawHandle(canvas, centerX, drumCenterY);
    _drawTray(canvas, centerX, size);

    if (showBall) {
      _drawBall(canvas, centerX, drumCenterY, size);
    }
  }

  void _drawBase(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.fill;

    final basePath = Path();
    basePath.moveTo(30, size.height - 20);
    basePath.lineTo(size.width - 30, size.height - 20);
    basePath.lineTo(size.width - 40, size.height);
    basePath.lineTo(40, size.height);
    basePath.close();

    canvas.drawPath(basePath, paint);

    paint.color = const Color(0xFFE8C89E);
    canvas.drawRect(
      Rect.fromLTWH(50, size.height - 18, size.width - 100, 4),
      paint,
    );
  }

  void _drawStand(Canvas canvas, double centerX, double drumCenterY, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B8B8B)
      ..style = PaintingStyle.fill;

    final leftStand = Path();
    leftStand.moveTo(centerX - 60, drumCenterY + 50);
    leftStand.lineTo(centerX - 50, drumCenterY + 50);
    leftStand.lineTo(centerX - 45, size.height - 20);
    leftStand.lineTo(centerX - 65, size.height - 20);
    leftStand.close();
    canvas.drawPath(leftStand, paint);

    final rightStand = Path();
    rightStand.moveTo(centerX + 60, drumCenterY + 50);
    rightStand.lineTo(centerX + 50, drumCenterY + 50);
    rightStand.lineTo(centerX + 45, size.height - 20);
    rightStand.lineTo(centerX + 65, size.height - 20);
    rightStand.close();
    canvas.drawPath(rightStand, paint);

    paint.color = const Color(0xFFAAAAAA);
    canvas.drawRect(
      Rect.fromLTWH(centerX - 58, drumCenterY + 52, 3, 60),
      paint,
    );
  }

  void _drawDrum(Canvas canvas, double centerX, double drumCenterY) {
    canvas.save();
    canvas.translate(centerX, drumCenterY);
    canvas.rotate(drumRotation);

    final drumRadius = 70.0;

    final paint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi - pi / 8;
      final x = cos(angle) * drumRadius;
      final y = sin(angle) * drumRadius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFE8C89E),
        const Color(0xFFD4A574),
        const Color(0xFFC49A6C),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: drumRadius));

    canvas.drawPath(path, paint);

    paint
      ..shader = null
      ..color = const Color(0xFFB8956E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4A4A4A);
    canvas.drawCircle(const Offset(0, 50), 12, paint);

    paint.color = const Color(0xFF8B8B8B);
    canvas.drawCircle(Offset.zero, 15, paint);
    paint.color = const Color(0xFFAAAAAA);
    canvas.drawCircle(Offset.zero, 8, paint);

    paint.color = const Color(0xFF5A4A3A);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final x = cos(angle) * 35;
      final y = sin(angle) * 35;
      canvas.drawCircle(Offset(x, y), 8, paint);
    }

    canvas.restore();
  }

  void _drawHandle(Canvas canvas, double centerX, double drumCenterY) {
    canvas.save();
    canvas.translate(centerX, drumCenterY);

    canvas.save();
    canvas.rotate(handleAngle);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, -3, 75, 14),
        const Radius.circular(3),
      ),
      shadowPaint,
    );

    final armPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB0B0B0),
          Color(0xFF808080),
          Color(0xFF606060),
        ],
      ).createShader(const Rect.fromLTWH(10, -6, 70, 12));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, -6, 70, 12),
        const Radius.circular(3),
      ),
      armPaint,
    );

    canvas.drawOval(
      const Rect.fromLTWH(72, 12, 30, 8),
      shadowPaint,
    );

    final gripPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5DFC5),
          Color(0xFFE8C89E),
          Color(0xFFD4A574),
        ],
      ).createShader(const Rect.fromLTWH(70, -18, 35, 36));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, -18, 35, 36),
        const Radius.circular(10),
      ),
      gripPaint,
    );

    final gripBorderPaint = Paint()
      ..color = const Color(0xFFC49A6C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, -18, 35, 36),
        const Radius.circular(10),
      ),
      gripBorderPaint,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, -14, 8, 20),
        const Radius.circular(4),
      ),
      highlightPaint,
    );

    if (!showBall) {
      _drawRotationArrow(canvas);
    }

    canvas.restore();
    canvas.restore();
  }

  void _drawRotationArrow(Canvas canvas) {
    final arrowPaint = Paint()
      ..color = colorScheme.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.addArc(
      const Rect.fromLTWH(95, -35, 30, 30),
      -pi / 2,
      pi * 0.7,
    );
    canvas.drawPath(path, arrowPaint);

    arrowPaint.style = PaintingStyle.fill;
    final arrowHead = Path();
    arrowHead.moveTo(118, -8);
    arrowHead.lineTo(125, -3);
    arrowHead.lineTo(115, 0);
    arrowHead.close();
    canvas.drawPath(arrowHead, arrowPaint);
  }

  void _drawTray(Canvas canvas, double centerX, Size size) {
    final trayPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;

    final trayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height - 55),
        width: 80,
        height: 30,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(trayRect, trayPaint);

    final feltPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    final feltRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height - 55),
        width: 70,
        height: 22,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(feltRect, feltPaint);
  }

  void _drawBall(Canvas canvas, double centerX, double drumCenterY, Size size) {
    final startY = drumCenterY + 50;
    final endY = size.height - 60;
    final currentY = startY + (endY - startY) * ballDropProgress;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(centerX + 2, currentY + 2),
      12,
      shadowPaint,
    );

    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700),
          const Color(0xFFDAA520),
          const Color(0xFFB8860B),
        ],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, currentY), radius: 12),
      );

    canvas.drawCircle(Offset(centerX, currentY), 12, ballPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(centerX - 4, currentY - 4), 4, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _GachaPonPainter oldDelegate) {
    return drumRotation != oldDelegate.drumRotation ||
        handleAngle != oldDelegate.handleAngle ||
        ballDropProgress != oldDelegate.ballDropProgress ||
        showBall != oldDelegate.showBall;
  }
}

/// オーバーレイを表示するヘルパー関数
Future<void> showGachaFlowOverlay(
  BuildContext context, {
  bool testMode = false,
  required VoidCallback onComplete,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return GachaFlowOverlay(
        testMode: testMode,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete();
        },
      );
    },
  );
}

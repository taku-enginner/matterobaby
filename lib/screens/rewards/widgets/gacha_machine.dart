import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GachaMachine extends StatefulWidget {
  final bool canSpin;
  final int availableSpins;
  final VoidCallback onSpin;

  const GachaMachine({
    super.key,
    required this.canSpin,
    required this.availableSpins,
    required this.onSpin,
  });

  @override
  State<GachaMachine> createState() => GachaMachineState();
}

class GachaMachineState extends State<GachaMachine>
    with TickerProviderStateMixin {
  // ドラム回転
  double _drumRotation = 0;
  double _totalRotation = 0;
  bool _isSpinning = false;
  bool _ballDropping = false;

  // ハンドル回転
  double _handleAngle = 0;
  Offset? _lastPanPosition;

  // アニメーション
  AnimationController? _ballDropController;
  AnimationController? _autoSpinController;

  // 必要な回転数（ラジアン）
  static const double _requiredRotation = 4 * pi; // 2回転

  double _baseRotation = 0; // 自動回転開始時の回転量

  @override
  void initState() {
    super.initState();

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
        // 手動回転からの続きで追加回転
        _drumRotation = _baseRotation + _autoSpinController!.value * 6 * pi;
        _handleAngle = _baseRotation + _autoSpinController!.value * 6 * pi;
      });
    });
    _autoSpinController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dropBall();
      }
    });
  }

  @override
  void dispose() {
    _ballDropController?.dispose();
    _autoSpinController?.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.canSpin || _isSpinning) return;
    _lastPanPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.canSpin || _isSpinning || _lastPanPosition == null) return;

    final center = Offset(150, 120); // ハンドルの中心位置
    final previous = _lastPanPosition! - center;
    final current = details.localPosition - center;

    // 角度の変化を計算
    final previousAngle = atan2(previous.dy, previous.dx);
    final currentAngle = atan2(current.dy, current.dx);
    var delta = currentAngle - previousAngle;

    // -π から π の範囲に正規化
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    // 時計回りのみ許可（正の方向）
    if (delta > 0) {
      setState(() {
        _handleAngle += delta;
        _drumRotation += delta;
        _totalRotation += delta;
      });

      // ハプティックフィードバック
      if ((_totalRotation * 10).floor() % 3 == 0) {
        HapticFeedback.selectionClick();
      }

      // 必要な回転数に達したらくじを実行
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
      _baseRotation = _drumRotation; // 現在の回転量を保存
    });
    HapticFeedback.heavyImpact();

    // 自動で追加回転してから玉を落とす
    _autoSpinController?.forward(from: 0);
  }

  void _dropBall() {
    setState(() {
      _ballDropping = true;
    });
    HapticFeedback.mediumImpact();
    _ballDropController?.forward(from: 0).then((_) {
      // 結果を表示
      widget.onSpin();

      // リセット
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSpinning = false;
            _ballDropping = false;
            _totalRotation = 0;
            _drumRotation = 0;
            _handleAngle = 0;
            _baseRotation = 0;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_totalRotation / _requiredRotation).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.tertiaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ガラガラポン',
            style: TextStyle(
              fontSize: 18,
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

          // 進捗バー
          if (!_isSpinning && widget.canSpin) ...[
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

          if (!widget.canSpin && widget.availableSpins == 0) ...[
            const SizedBox(height: 8),
            Text(
              'スタンプを貯めてくじを回そう！',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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

    // 台座
    _drawBase(canvas, size);

    // 支柱
    _drawStand(canvas, centerX, drumCenterY, size);

    // ドラム（八角形）
    _drawDrum(canvas, centerX, drumCenterY);

    // ハンドル
    _drawHandle(canvas, centerX, drumCenterY);

    // 玉受けトレイ
    _drawTray(canvas, centerX, size);

    // 落ちる玉
    if (showBall) {
      _drawBall(canvas, centerX, drumCenterY, size);
    }
  }

  void _drawBase(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A574) // 木の色
      ..style = PaintingStyle.fill;

    final basePath = Path();
    basePath.moveTo(30, size.height - 20);
    basePath.lineTo(size.width - 30, size.height - 20);
    basePath.lineTo(size.width - 40, size.height);
    basePath.lineTo(40, size.height);
    basePath.close();

    canvas.drawPath(basePath, paint);

    // 木目のハイライト
    paint.color = const Color(0xFFE8C89E);
    canvas.drawRect(
      Rect.fromLTWH(50, size.height - 18, size.width - 100, 4),
      paint,
    );
  }

  void _drawStand(Canvas canvas, double centerX, double drumCenterY, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B8B8B) // 金属色
      ..style = PaintingStyle.fill;

    // 左支柱
    final leftStand = Path();
    leftStand.moveTo(centerX - 60, drumCenterY + 50);
    leftStand.lineTo(centerX - 50, drumCenterY + 50);
    leftStand.lineTo(centerX - 45, size.height - 20);
    leftStand.lineTo(centerX - 65, size.height - 20);
    leftStand.close();
    canvas.drawPath(leftStand, paint);

    // 右支柱
    final rightStand = Path();
    rightStand.moveTo(centerX + 60, drumCenterY + 50);
    rightStand.lineTo(centerX + 50, drumCenterY + 50);
    rightStand.lineTo(centerX + 45, size.height - 20);
    rightStand.lineTo(centerX + 65, size.height - 20);
    rightStand.close();
    canvas.drawPath(rightStand, paint);

    // ハイライト
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

    // 八角形のドラム
    final paint = Paint()
      ..style = PaintingStyle.fill;

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

    // グラデーション（木目調）
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFE8C89E),
        const Color(0xFFD4A574),
        const Color(0xFFC49A6C),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: drumRadius));

    canvas.drawPath(path, paint);

    // 枠線
    paint
      ..shader = null
      ..color = const Color(0xFFB8956E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, paint);

    // 中央の穴（玉が出る穴）
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4A4A4A);
    canvas.drawCircle(const Offset(0, 50), 12, paint);

    // 中央の軸
    paint.color = const Color(0xFF8B8B8B);
    canvas.drawCircle(Offset.zero, 15, paint);
    paint.color = const Color(0xFFAAAAAA);
    canvas.drawCircle(Offset.zero, 8, paint);

    // 装飾の穴
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

    // ハンドルアーム（回転する）
    canvas.save();
    canvas.rotate(handleAngle);

    // アームの影
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

    // アーム（金属部分）
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

    // グリップの影
    canvas.drawOval(
      const Rect.fromLTWH(72, 12, 30, 8),
      shadowPaint,
    );

    // グリップ（木製・大きめ）
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

    // グリップ本体（縦長の楕円形）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, -18, 35, 36),
        const Radius.circular(10),
      ),
      gripPaint,
    );

    // グリップの枠線
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

    // グリップのハイライト
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

    // 回転を示す矢印（グリップの近くに）
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

    // 円弧の矢印
    final path = Path();
    path.addArc(
      const Rect.fromLTWH(95, -35, 30, 30),
      -pi / 2,
      pi * 0.7,
    );
    canvas.drawPath(path, arrowPaint);

    // 矢印の先端
    arrowPaint.style = PaintingStyle.fill;
    final arrowHead = Path();
    arrowHead.moveTo(118, -8);
    arrowHead.lineTo(125, -3);
    arrowHead.lineTo(115, 0);
    arrowHead.close();
    canvas.drawPath(arrowHead, arrowPaint);
  }

  void _drawTray(Canvas canvas, double centerX, Size size) {
    // トレイの外枠
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

    // 赤いフェルト部分
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
    // 玉の落下アニメーション
    final startY = drumCenterY + 50;
    final endY = size.height - 60;
    final currentY = startY + (endY - startY) * ballDropProgress;

    // 影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(centerX + 2, currentY + 2),
      12,
      shadowPaint,
    );

    // 玉（金色）
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

    // ハイライト
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

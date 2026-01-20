import 'package:flutter/material.dart';

class RippleEffect extends StatefulWidget {
  final VoidCallback? onComplete;

  const RippleEffect({super.key, this.onComplete});

  @override
  State<RippleEffect> createState() => RippleEffectState();
}

class RippleEffectState extends State<RippleEffect>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  bool _isAnimating = false;

  void startRipple() {
    if (_isAnimating) return;
    _isAnimating = true;

    // Create 3 ripple waves
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (!mounted) return;
        _addRipple();
      });
    }

    // Reset after animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _isAnimating = false;
      widget.onComplete?.call();
    });
  }

  void _addRipple() {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    _controllers.add(controller);
    _animations.add(animation);

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          final index = _controllers.indexOf(controller);
          if (index != -1) {
            _controllers.removeAt(index);
            _animations.removeAt(index);
          }
        });
        controller.dispose();
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: _animations.asMap().entries.map((entry) {
          final animation = entry.value;
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: RipplePainter(
                  progress: animation.value,
                  color: colorScheme.primary,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

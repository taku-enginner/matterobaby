import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckinButton extends StatefulWidget {
  final bool isCheckedIn;
  final VoidCallback onPressed;

  const CheckinButton({
    super.key,
    required this.isCheckedIn,
    required this.onPressed,
  });

  @override
  State<CheckinButton> createState() => _CheckinButtonState();
}

class _CheckinButtonState extends State<CheckinButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse().then((_) {
      _bounceController.forward(from: 0);
    });

    if (!widget.isCheckedIn) {
      HapticFeedback.heavyImpact();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = widget.isCheckedIn
        ? colorScheme.tertiary
        : colorScheme.primary;
    final textColor = widget.isCheckedIn
        ? colorScheme.onTertiary
        : colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _bounceController]),
        builder: (context, child) {
          double scale = 1.0;
          if (_scaleController.isAnimating || _scaleController.value > 0) {
            scale = _scaleAnimation.value;
          } else if (_bounceController.isAnimating) {
            scale = _bounceAnimation.value;
          }

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonColor,
            boxShadow: [
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isCheckedIn ? Icons.check : Icons.touch_app,
                  size: 64,
                  color: textColor,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isCheckedIn ? '記録済み' : '出勤を記録',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

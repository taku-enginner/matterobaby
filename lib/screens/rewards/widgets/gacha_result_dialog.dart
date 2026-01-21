import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../data/models/reward.dart';

class GachaResultDialog extends StatefulWidget {
  final Reward reward;

  const GachaResultDialog({
    super.key,
    required this.reward,
  });

  @override
  State<GachaResultDialog> createState() => _GachaResultDialogState();
}

class _GachaResultDialogState extends State<GachaResultDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AlertDialog(
          contentPadding: const EdgeInsets.all(24),
          content: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration,
                  size: 48,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'おめでとう！',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildRewardDisplay(colorScheme),
                const SizedBox(height: 24),
                Text(
                  '今日のごほうび',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('やったー！'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
              Colors.pink,
              Colors.orange,
              Colors.yellow,
              Colors.green,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardDisplay(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (widget.reward.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.reward.imagePath!),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 60,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            widget.reward.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.reward.memo != null && widget.reward.memo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.reward.memo!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

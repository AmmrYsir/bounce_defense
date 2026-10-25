import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';

/// Floating combat number and popup text (`Canvas_DamagePointIndicator`).
class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;
  double _elapsed = 0.0;
  static const double _duration = 0.65;

  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 12.0,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: GameConstants.zIndexVfx,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= 28.0 * dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final alpha = (1.0 - (_elapsed / _duration)).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

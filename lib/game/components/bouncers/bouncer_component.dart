import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';

/// A static bumper pin that deflects balls and powers up their bounce count.
class BouncerComponent extends CircleComponent with CollisionCallbacks {
  BouncerComponent({
    required Vector2 position,
    double radius = GameConstants.defaultBouncerRadius,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          priority: GameConstants.zIndexBouncers,
        );

  late final CircleHitbox _hitbox;
  double _flashTimer = 0.0;
  static const double _flashDuration = 0.15;

  late final Paint _idlePaint;
  late final Paint _activePaint;

  int _hitCount = 0;
  int get hitCount => _hitCount;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _idlePaint = Paint()
      ..color = GameConstants.bouncerColor
      ..style = PaintingStyle.fill;

    _activePaint = Paint()
      ..color = GameConstants.bouncerActiveColor
      ..style = PaintingStyle.fill;

    paint = _idlePaint;

    _hitbox = CircleHitbox(
      radius: radius,
      anchor: Anchor.center,
      position: Vector2.all(radius),
    );
    add(_hitbox);
  }

  /// Trigger bounce visual reaction
  void registerHit() {
    _hitCount++;
    _flashTimer = _flashDuration;
    paint = _activePaint;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        paint = _idlePaint;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw outer glow/ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(radius, radius), radius + 2, ringPaint);
  }
}

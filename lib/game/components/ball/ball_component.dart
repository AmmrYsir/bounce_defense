import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../bouncers/bouncer_component.dart';
import '../bouncers/wall_boundary.dart';

/// The active projectile ball bounced across the pinball defense board.
class BallComponent extends CircleComponent with CollisionCallbacks {
  Vector2 velocity;
  final double baseDamage;

  int _bounceCount = 0;
  int get bounceCount => _bounceCount;

  /// Current DPS Multiplier based on the reference APK formula:
  /// `BounceCountAddDPS` -> Base + (Bounces * Bonus)
  double get dpsMultiplier =>
      1.0 + (_bounceCount * GameConstants.dpsBonusPerBounce);

  double get currentDamage => baseDamage * dpsMultiplier;

  BallComponent({
    required Vector2 position,
    required this.velocity,
    double radius = GameConstants.defaultBallRadius,
    this.baseDamage = 10.0,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          priority: GameConstants.zIndexBalls,
          paint: Paint()..color = GameConstants.ballColor,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      CircleHitbox(
        radius: radius,
        anchor: Anchor.center,
        position: Vector2.all(radius),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    // Keep speed within boundaries
    if (velocity.length > GameConstants.maxBallSpeed) {
      velocity.scaleTo(GameConstants.maxBallSpeed);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BouncerComponent) {
      // Calculate collision normal from bouncer center to ball center
      final normal = (position - other.position);
      if (normal.length2 > 0) {
        normal.normalize();
        // Reflect velocity across normal: v' = v - 2(v . n)n
        velocity.reflect(normal);
        // Apply slight elastic boost
        velocity.scale(GameConstants.bouncerRestitution);
        // Position push-out to avoid clipping
        position = other.position + normal * (radius + other.radius + 1.0);
      }
      other.registerHit();
      _bounceCount++;
    } else if (other is WallBoundary) {
      switch (other.orientation) {
        case WallOrientation.left:
          velocity.x = velocity.x.abs();
          position.x = other.position.x + other.size.x + radius;
          break;
        case WallOrientation.right:
          velocity.x = -velocity.x.abs();
          position.x = other.position.x - radius;
          break;
        case WallOrientation.top:
          velocity.y = velocity.y.abs();
          position.y = other.position.y + other.size.y + radius;
          break;
        case WallOrientation.bottom:
          velocity.y = -velocity.y.abs();
          position.y = other.position.y - radius;
          break;
      }
      _bounceCount++;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render ball center glow
    final glowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius * 0.4, glowPaint);
  }
}

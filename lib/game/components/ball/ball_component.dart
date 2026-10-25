import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../bouncers/bouncer_component.dart';
import '../bouncers/wall_boundary.dart';

/// The active kinetic ball bouncing across the Tactical Grid (`Ball Holder`).
class BallComponent extends CircleComponent with CollisionCallbacks {
  Vector2 velocity;
  final double baseDamage;
  double speedMultiplier;

  int _bounceCount = 0;
  int get bounceCount => _bounceCount;

  final List<Vector2> _trailPoints = [];
  static const int _maxTrailPoints = 9;

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
    this.speedMultiplier = 1.0,
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

    _trailPoints.add(position.clone());
    if (_trailPoints.length > _maxTrailPoints) {
      _trailPoints.removeAt(0);
    }

    position.add(velocity * speedMultiplier * dt);

    // Keep ball strictly inside the Tactical Grid Arena bounds
    const leftBound = GameConstants.gridAreaLeftX + 10.0;
    const rightBound = GameConstants.gridAreaRightX - 10.0;
    const topBound = GameConstants.gridAreaTopY + 10.0;
    const bottomBound = GameConstants.gridAreaBottomY - 10.0;

    if (position.x < leftBound) {
      position.x = leftBound;
      velocity.x = velocity.x.abs();
      _bounceCount++;
    } else if (position.x > rightBound) {
      position.x = rightBound;
      velocity.x = -velocity.x.abs();
      _bounceCount++;
    }

    if (position.y < topBound) {
      position.y = topBound;
      velocity.y = velocity.y.abs();
      _bounceCount++;
    } else if (position.y > bottomBound) {
      position.y = bottomBound;
      velocity.y = -velocity.y.abs();
      _bounceCount++;
    }

    // Clamp speed
    if (velocity.length > GameConstants.maxBallSpeed) {
      velocity.scaleTo(GameConstants.maxBallSpeed);
    } else if (velocity.length < GameConstants.defaultBallSpeed * 0.75) {
      velocity.scaleTo(GameConstants.defaultBallSpeed);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is BouncerComponent) {
      final normal = (position - other.position);
      final speed = velocity.length;

      if (normal.length2 > 0) {
        normal.normalize();
        // Blend natural reflection with unit's directional bounce tail (`UnitIdWithTailDirection`)
        final tailDir = other.tailDirectionVector;
        final combinedDir = (normal * 0.35 + tailDir * 0.65);
        if (combinedDir.length2 > 0.01) {
          combinedDir.normalize();
          velocity = combinedDir * (speed * GameConstants.bouncerRestitution);
        } else {
          velocity.reflect(normal);
          velocity.scale(GameConstants.bouncerRestitution);
        }
        position = other.position + normal * (radius + other.radius + 1.5);
      }

      _bounceCount++;
      other.registerHit(ballDpsMultiplier: dpsMultiplier);
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
    // Draw kinetic neon trail
    for (int i = 0; i < _trailPoints.length; i++) {
      final pt = _trailPoints[i] - position + Vector2.all(radius);
      final ratio = (i + 1) / _trailPoints.length;
      canvas.drawCircle(
        Offset(pt.x, pt.y),
        radius * ratio * 0.72,
        Paint()
          ..color = GameConstants.ballColor.withValues(alpha: ratio * 0.32),
      );
    }

    super.render(canvas);

    // Hot white center core
    canvas.drawCircle(
      Offset(radius, radius),
      radius * 0.45,
      Paint()..color = Colors.white,
    );
  }
}

import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../bounce_defense_game.dart';
import '../enemies/enemy_component.dart';

/// Projectile fired upward from a charged Tactical Grid Unit toward enemies.
class WeaponBulletComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<BounceDefenseGame> {
  Vector2 velocity;
  final double damage;
  final bool isCrit;
  final bool canRicochet;
  final bool canSplit;
  final bool isSplashAoE;
  final bool appliesFreeze;
  final Color bulletColor;

  final Set<EnemyComponent> _hitEnemies = {};
  int _remainingRicochets;
  bool _hasSplit = false;

  WeaponBulletComponent({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    this.isCrit = false,
    this.canRicochet = false,
    this.canSplit = false,
    this.isSplashAoE = false,
    this.appliesFreeze = false,
    this.bulletColor = const Color(0xFFFFEA00),
    int remainingRicochets = 1,
  })  : _remainingRicochets = canRicochet ? remainingRicochets : 0,
        super(
          position: position,
          size: Vector2.all(isSplashAoE ? 13.0 : 9.0),
          anchor: Anchor.center,
          priority: GameConstants.zIndexProjectiles,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      CircleHitbox(
        radius: size.x * 0.5,
        anchor: Anchor.center,
        position: size / 2,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    // Gently steer toward nearest active enemy if moving upward in battlefield
    final enemies = game.activeEnemies;
    if (enemies.isNotEmpty) {
      EnemyComponent? closest;
      double bestDist2 = double.infinity;
      for (final e in enemies) {
        if (e.isDead || _hitEnemies.contains(e)) continue;
        final d2 = position.distanceToSquared(e.position);
        if (d2 < bestDist2) {
          bestDist2 = d2;
          closest = e;
        }
      }
      if (closest != null && bestDist2 < 24000) {
        final desired = (closest.position - position).normalized() * velocity.length;
        velocity.lerp(desired, (dt * 6.5).clamp(0.0, 1.0));
      }
    }

    // Despawn if out of battlefield bounds
    if (position.y < 30 ||
        position.y > GameConstants.gridAreaBottomY ||
        position.x < 0 ||
        position.x > GameConstants.gameWidth) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyComponent && !other.isDead && !_hitEnemies.contains(other)) {
      _hitEnemies.add(other);

      other.takeDamage(
        damage,
        isCrit: isCrit,
        applyFreeze: appliesFreeze,
      );

      // Splash AoE damage for Bomb / Molotov / ExplodingRock / BlackHole
      if (isSplashAoE) {
        for (final neighbor in game.activeEnemies) {
          if (neighbor != other &&
              !neighbor.isDead &&
              neighbor.position.distanceTo(other.position) <= 58.0) {
            neighbor.takeDamage(
              damage * 0.65,
              isCrit: false,
              applyFreeze: appliesFreeze,
            );
          }
        }
      }

      // Split into 2 forked bullets if enabled (`BulletSplitChancePercent`)
      if (canSplit && !_hasSplit) {
        _hasSplit = true;
        final baseAngle = math.atan2(velocity.y, velocity.x);
        final speed = velocity.length;
        for (final delta in [-0.38, 0.38]) {
          final childVel = Vector2(
            math.cos(baseAngle + delta) * speed,
            math.sin(baseAngle + delta) * speed,
          );
          final child = WeaponBulletComponent(
            position: position.clone(),
            velocity: childVel,
            damage: damage * 0.55,
            isCrit: isCrit,
            canRicochet: false,
            canSplit: false,
            appliesFreeze: appliesFreeze,
            bulletColor: bulletColor,
          );
          child._hitEnemies.add(other);
          game.world.add(child);
        }
      }

      // Ricochet to another enemy if available (`BulletRicochetChancePercent`)
      if (_remainingRicochets > 0) {
        _remainingRicochets--;
        EnemyComponent? nextTarget;
        double minDist = double.infinity;
        for (final candidate in game.activeEnemies) {
          if (!candidate.isDead && !_hitEnemies.contains(candidate)) {
            final d = candidate.position.distanceTo(position);
            if (d < minDist && d <= 160.0) {
              minDist = d;
              nextTarget = candidate;
            }
          }
        }
        if (nextTarget != null) {
          velocity =
              (nextTarget.position - position).normalized() * velocity.length;
          return;
        }
      }

      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);

    // Outer neon glow
    canvas.drawCircle(
      center,
      size.x * 0.65,
      Paint()..color = bulletColor.withValues(alpha: 0.35),
    );

    // Core projectile
    canvas.drawCircle(
      center,
      size.x * 0.42,
      Paint()..color = bulletColor,
    );

    // Hot white center
    canvas.drawCircle(
      center,
      size.x * 0.2,
      Paint()..color = Colors.white,
    );
  }
}

import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../../models/enemy_config.dart';
import '../../bounce_defense_game.dart';

/// Enemy entity marching down the top battlefield lane toward the RPG Wall barricade.
class EnemyComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<BounceDefenseGame> {
  final EnemyConfig config;
  final double maxHp;
  double currentHp;
  final double attackDamage;
  final double moveSpeed;

  Sprite? _enemySprite;
  double _attackCooldown = 0.0;
  double _hitFlashTimer = 0.0;
  double _freezeTimer = 0.0;

  bool get isDead => currentHp <= 0;

  EnemyComponent({
    required this.config,
    required Vector2 position,
    required double hpMultiplier,
    required double atkMultiplier,
  })  : maxHp = (config.baseHp * 28.0 * hpMultiplier).clamp(10.0, 999999.0),
        currentHp = (config.baseHp * 28.0 * hpMultiplier).clamp(10.0, 999999.0),
        attackDamage = (config.baseAtk * 4.0 * atkMultiplier).clamp(1.0, 5000.0),
        moveSpeed = config.isBoss
            ? 14.0
            : (config.prefabName.contains('Fast') ? 28.0 : 19.0),
        super(
          position: position,
          size: config.isBoss ? Vector2.all(48.0) : Vector2.all(34.0),
          anchor: Anchor.center,
          priority: GameConstants.zIndexEnemies,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      CircleHitbox(
        radius: size.x * 0.44,
        anchor: Anchor.center,
        position: size / 2,
      ),
    );

    // Load authentic extracted enemy sprite
    try {
      final image = await game.images.load(config.spriteAssetPath);
      _enemySprite = Sprite(image);
    } catch (_) {
      _enemySprite = null;
    }
  }

  /// Apply damage from a triggered weapon projectile or Commander ability
  void takeDamage(double amount, {bool isCrit = false, bool applyFreeze = false}) {
    if (isDead) return;
    currentHp = math.max(0.0, currentHp - amount);
    _hitFlashTimer = 0.12;
    if (applyFreeze) {
      _freezeTimer = 2.0;
    }

    game.recordDamageDealt(amount, position: position.clone(), isCrit: isCrit);

    if (currentHp <= 0) {
      game.onEnemyKilled(this);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;

    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }
    if (_freezeTimer > 0) {
      _freezeTimer -= dt;
    }

    final effectiveSpeed = _freezeTimer > 0 ? moveSpeed * 0.4 : moveSpeed;
    final stopY = GameConstants.barricadeWallY - (size.y * 0.55);

    if (position.y < stopY) {
      position.y = math.min(stopY, position.y + effectiveSpeed * dt);
    } else {
      // Reached the Barricade Wall -> Attack on interval
      _attackCooldown -= dt;
      if (_attackCooldown <= 0) {
        _attackCooldown = 1.25;
        game.damageBarricade(attackDamage);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    // Ground drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.88),
        width: size.x * 0.75,
        height: size.y * 0.28,
      ),
      shadowPaint,
    );

    // Render authentic enemy sprite or stylized fallback
    if (_enemySprite != null) {
      final overridePaint = Paint();
      if (_hitFlashTimer > 0) {
        overridePaint.colorFilter = const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        );
      } else if (_freezeTimer > 0) {
        overridePaint.colorFilter = const ColorFilter.mode(
          Color(0x8800E5FF),
          BlendMode.srcATop,
        );
      }
      _enemySprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        overridePaint: overridePaint,
      );
    } else {
      final bodyPaint = Paint()
        ..color = _hitFlashTimer > 0
            ? Colors.white
            : (config.isBoss
                ? const Color(0xFFFF3D00)
                : const Color(0xFFE040FB));
      canvas.drawCircle(center, size.x * 0.4, bodyPaint);
    }

    // Boss crown / aura indicator
    if (config.isBoss) {
      final bossRing = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, size.x * 0.48, bossRing);
    }

    // HealthBar2D Red Variant above enemy
    final barWidth = size.x * 0.95;
    const barHeight = 5.0;
    final barLeft = (size.x - barWidth) / 2;
    const barTop = -7.0;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = const Color(0xFF1A0F14).withValues(alpha: 0.9),
    );

    final hpPercent = (currentHp / maxHp).clamp(0.0, 1.0);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth * hpPercent, barHeight),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      fillRect,
      Paint()
        ..color = config.isBoss
            ? const Color(0xFFFF9100)
            : const Color(0xFFFF1744),
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}

import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../../models/hero_unit_config.dart';
import '../../bounce_defense_game.dart';

/// A Tactical Grid Unit placed on the 5x4 board (`Placed Unit Holder`).
/// Deflects balls along its tail direction, charges its `FillCount` gauge on each bounce,
/// and fires weapon projectiles upward at advancing enemies when full.
class BouncerComponent extends CircleComponent
    with CollisionCallbacks, HasGameReference<BounceDefenseGame> {
  HeroUnitConfig unitConfig;
  int gridCol;
  int gridRow;
  int starLevel;

  /// Tail deflection direction (0: Right, 1: Down-Right, 2: Down, 3: Down-Left, 4: Left, 5: Up-Left, 6: Up, 7: Up-Right)
  int tailDirectionIndex;

  int _currentFill = 0;
  int get currentFill => _currentFill;

  int _hitCount = 0;
  int get hitCount => _hitCount;

  double _flashTimer = 0.0;
  static const double _flashDuration = 0.16;

  Sprite? _tileBgSprite;
  Sprite? _iconSprite;

  BouncerComponent({
    required Vector2 position,
    required this.unitConfig,
    this.gridCol = 0,
    this.gridRow = 0,
    this.starLevel = 1,
    this.tailDirectionIndex = 0,
    double radius = GameConstants.defaultBouncerRadius,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          priority: GameConstants.zIndexBouncers,
          paint: Paint()..color = Colors.transparent,
        );

  /// Required hits before weapon triggers, reduced by `FillNumberReduce` skill card.
  int get requiredFillCount {
    final reduction = game.fillCountReduction;
    return math.max(1, unitConfig.fillCount - reduction);
  }

  /// Normalized 0.0..1.0 fill progress for `FillMask` radial ring.
  double get fillProgress =>
      (_currentFill / requiredFillCount).clamp(0.0, 1.0);

  /// Unit vector representing the directional bounce tail (`UnitIdWithTailDirection`).
  Vector2 get tailDirectionVector {
    final angle = tailDirectionIndex * (math.pi / 4.0);
    return Vector2(math.cos(angle), math.sin(angle));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      CircleHitbox(
        radius: radius * 0.92,
        anchor: Anchor.center,
        position: Vector2.all(radius),
      ),
    );

    await _reloadSprites();
  }

  Future<void> _reloadSprites() async {
    try {
      final bgImg = await game.images
          .load(HeroUnitConfig.tileBgAssetForStar(starLevel));
      _tileBgSprite = Sprite(bgImg);
    } catch (_) {
      _tileBgSprite = null;
    }

    try {
      final iconImg = await game.images.load(unitConfig.iconAssetPath);
      _iconSprite = Sprite(iconImg);
    } catch (_) {
      _iconSprite = null;
    }
  }

  /// Rotate the unit's bounce tail direction by 45 degrees when tapped
  void rotateTailDirection() {
    tailDirectionIndex = (tailDirectionIndex + 1) % 8;
    _flashTimer = 0.1;
  }

  /// Upgrade star rank when merged with an identical unit
  void upgradeStarLevel() {
    starLevel = (starLevel + 1).clamp(1, 5);
    _flashTimer = 0.25;
    _reloadSprites();
  }

  /// Triggered when a ball bounces off this unit
  void registerHit({double ballDpsMultiplier = 1.0}) {
    _hitCount++;
    _currentFill++;
    _flashTimer = _flashDuration;

    if (_currentFill >= requiredFillCount) {
      _currentFill = 0;
      game.triggerUnitAttack(this, ballDpsMultiplier: ballDpsMultiplier);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(radius, radius);
    final tileSize = Vector2.all(radius * 2.15);
    final tileTopLeft = Vector2(-radius * 0.075, -radius * 0.075);

    // 1. Render authentic rarity tile background (`Unit_bg_*.png`)
    if (_tileBgSprite != null) {
      _tileBgSprite!.render(
        canvas,
        position: tileTopLeft,
        size: tileSize,
      );
    } else {
      final fallbackRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 2.0,
          height: radius * 2.0,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        fallbackRect,
        Paint()..color = _fallbackStarColor(starLevel),
      );
    }

    // 2. Render authentic weapon icon (`01.png`..`12.png`, etc.)
    if (_iconSprite != null) {
      final iconSize = Vector2.all(radius * 1.48);
      final iconPos = Vector2(
        radius - iconSize.x / 2,
        radius - iconSize.y / 2,
      );
      _iconSprite!.render(
        canvas,
        position: iconPos,
        size: iconSize,
      );
    }

    // 3. Render Radial Charge Fill Gauge (`FillMask`)
    final progress = fillProgress;
    final ringPaint = Paint()
      ..color = _flashTimer > 0
          ? Colors.amberAccent
          : const Color(0xFF00E5FF).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.96),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      ringPaint,
    );

    // 4. Render Directional Bounce Tail Arrow (`Tail Right/Down/Left/Up`)
    final tailVec = tailDirectionVector;
    final arrowDist = radius * 1.12;
    final arrowCenter = Offset(
      center.dx + tailVec.x * arrowDist,
      center.dy + tailVec.y * arrowDist,
    );
    final arrowAngle = math.atan2(tailVec.y, tailVec.x);

    canvas.save();
    canvas.translate(arrowCenter.dx, arrowCenter.dy);
    canvas.rotate(arrowAngle);
    final arrowPath = Path()
      ..moveTo(6.0, 0.0)
      ..lineTo(-4.0, -5.0)
      ..lineTo(-4.0, 5.0)
      ..close();
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFFFFEA00)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // 5. Render Star Rank dots at top-left
    for (int i = 0; i < starLevel; i++) {
      canvas.drawCircle(
        Offset(5.0 + i * 7.0, 5.0),
        2.8,
        Paint()..color = const Color(0xFFFFD700),
      );
    }

    // 6. Render Remaining Fill Count badge at bottom-right
    final rem = math.max(1, requiredFillCount - _currentFill);
    final badgeCenter = Offset(radius * 1.68, radius * 1.68);
    canvas.drawCircle(
      badgeCenter,
      7.5,
      Paint()..color = const Color(0xDD101622),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$rem',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(badgeCenter.dx - tp.width / 2, badgeCenter.dy - tp.height / 2),
    );
  }

  Color _fallbackStarColor(int star) {
    switch (star) {
      case 1:
        return const Color(0xFF2ECC71);
      case 2:
        return const Color(0xFF3498DB);
      case 3:
        return const Color(0xFF9B59B6);
      case 4:
        return const Color(0xFFF1C40F);
      default:
        return const Color(0xFFE74C3C);
    }
  }
}

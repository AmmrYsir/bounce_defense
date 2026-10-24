import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';

enum WallOrientation { left, right, top, bottom }

/// Boundary walls of the game arena.
class WallBoundary extends RectangleComponent with CollisionCallbacks {
  final WallOrientation orientation;

  WallBoundary({
    required Vector2 position,
    required Vector2 size,
    required this.orientation,
  }) : super(
          position: position,
          size: size,
          priority: GameConstants.zIndexBackground,
          paint: Paint()..color = GameConstants.wallColor,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
  }
}

import 'package:flutter/material.dart';

/// Core gameplay and physics configuration constants.
class GameConstants {
  GameConstants._();

  // Virtual Game Resolution (Logical canvas size)
  static const double gameWidth = 400.0;
  static const double gameHeight = 700.0;

  // Ball physics configuration
  static const double defaultBallRadius = 8.0;
  static const double defaultBallSpeed = 350.0;
  static const double maxBallSpeed = 700.0;

  /// DPS added per bounce against pins, walls, and bouncers
  /// Directly mirrors the reference APK `BounceCountAddDPS` mechanic.
  static const double dpsBonusPerBounce = 0.15; // +15% damage per bounce

  // Bouncer (Pin/Bumper) defaults
  static const double defaultBouncerRadius = 18.0;
  static const double bouncerRestitution = 1.05; // Slightly elastic bounce kick

  // Layer Z-indexes
  static const int zIndexBackground = 0;
  static const int zIndexBouncers = 10;
  static const int zIndexBricks = 20;
  static const int zIndexEnemies = 30;
  static const int zIndexBalls = 40;
  static const int zIndexProjectiles = 50;
  static const int zIndexVfx = 60;

  // Visual Theme Colors
  static const Color backgroundColor = Color(0xFF10141E);
  static const Color wallColor = Color(0xFF2C3E50);
  static const Color ballColor = Color(0xFF00E5FF);
  static const Color bouncerColor = Color(0xFFFF5252);
  static const Color bouncerActiveColor = Color(0xFFFFD700);
}

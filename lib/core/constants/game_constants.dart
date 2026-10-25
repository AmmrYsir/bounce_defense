import 'package:flutter/material.dart';

/// Core gameplay, layout coordinates, and physics configuration constants
/// matching `level3` of Bounce Defense (`com.minigamelab.bouncedefense`).
class GameConstants {
  GameConstants._();

  // Virtual Game Resolution (Logical canvas size)
  static const double gameWidth = 400.0;
  static const double gameHeight = 700.0;

  // Zone Y-Coordinates (Matching level3 scene hierarchy)
  static const double enemySpawnTopY = 72.0;
  static const double barricadeWallY = 264.0;
  static const double gridAreaTopY = 282.0;
  static const double gridAreaBottomY = 546.0;
  static const double gridAreaLeftX = 16.0;
  static const double gridAreaRightX = 384.0;

  // Tactical Grid Dimensions (5 cols x 4 rows)
  static const int gridCols = 5;
  static const int gridRows = 4;
  static const double cellWidth = 66.0;
  static const double cellHeight = 58.0;
  static const double gridStartX = 35.0;
  static const double gridStartY = 294.0;

  // Ball physics configuration
  static const double defaultBallRadius = 8.5;
  static const double defaultBallSpeed = 290.0;
  static const double maxBallSpeed = 560.0;

  /// DPS added per bounce against units and walls (`BounceCountAddDPS`)
  static const double dpsBonusPerBounce = 0.15;

  // Bouncer / Unit Hitbox Radius
  static const double defaultBouncerRadius = 24.0;
  static const double bouncerRestitution = 1.04;

  // Base / Barricade HP
  static const double defaultBaseMaxHp = 500.0;

  // Starting Economy
  static const int startingGold = 75;
  static const int baseExtraBallCost = 20;

  // Layer Z-indexes
  static const int zIndexBackground = 0;
  static const int zIndexGridCells = 5;
  static const int zIndexBouncers = 10;
  static const int zIndexWall = 20;
  static const int zIndexEnemies = 30;
  static const int zIndexBalls = 40;
  static const int zIndexProjectiles = 50;
  static const int zIndexVfx = 60;

  // Visual Theme Colors
  static const Color backgroundColor = Color(0xFF0E131F);
  static const Color battlefieldColor = Color(0xFF131B2E);
  static const Color gridBoardColor = Color(0xFF0A0F1A);
  static const Color wallColor = Color(0xFF283747);
  static const Color ballColor = Color(0xFF00E5FF);
  static const Color bouncerColor = Color(0xFFFF5252);
  static const Color bouncerActiveColor = Color(0xFFFFD700);
}

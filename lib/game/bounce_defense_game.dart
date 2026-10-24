import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import 'components/ball/ball_component.dart';
import 'components/bouncers/bouncer_component.dart';
import 'components/bouncers/wall_boundary.dart';

/// Main Flame Game orchestrating the Bounce Defense simulation.
class BounceDefenseGame extends FlameGame
    with HasCollisionDetection, TapCallbacks {
  // Reactive notifiers for the Flutter UI HUD overlay
  final ValueNotifier<int> ballCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> totalBouncesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> peakDpsMultiplierNotifier =
      ValueNotifier<double>(1.0);

  final math.Random _random = math.Random();

  @override
  Color backgroundColor() => GameConstants.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Use a fixed virtual viewport matching GameConstants
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(
        GameConstants.gameWidth,
        GameConstants.gameHeight,
      ),
    );

    // Setup arena boundary walls
    _createBoundaries();

    // Setup initial pinball defense layout
    _createBouncerGrid();

    // Spawn the first initial defender ball
    spawnBall();
  }

  void _createBoundaries() {
    const wallThickness = 12.0;
    const w = GameConstants.gameWidth;
    const h = GameConstants.gameHeight;

    world.addAll([
      // Left Wall
      WallBoundary(
        position: Vector2(0, 0),
        size: Vector2(wallThickness, h),
        orientation: WallOrientation.left,
      ),
      // Right Wall
      WallBoundary(
        position: Vector2(w - wallThickness, 0),
        size: Vector2(wallThickness, h),
        orientation: WallOrientation.right,
      ),
      // Top Wall
      WallBoundary(
        position: Vector2(0, 0),
        size: Vector2(w, wallThickness),
        orientation: WallOrientation.top,
      ),
      // Bottom Wall / Floor
      WallBoundary(
        position: Vector2(0, h - wallThickness),
        size: Vector2(w, wallThickness),
        orientation: WallOrientation.bottom,
      ),
    ]);
  }

  void _createBouncerGrid() {
    // Generate a triangular/honeycomb staggered grid of bouncers
    const rows = 4;
    const cols = 5;
    const startY = 180.0;
    const spacingY = 70.0;
    const spacingX = 65.0;

    for (int r = 0; r < rows; r++) {
      final offsetX = (r % 2 == 0) ? 65.0 : 97.5;
      final count = (r % 2 == 0) ? cols : cols - 1;

      for (int c = 0; c < count; c++) {
        final pos = Vector2(offsetX + (c * spacingX), startY + (r * spacingY));
        world.add(BouncerComponent(position: pos));
      }
    }
  }

  /// Spawn a new ball launching from the top/bottom into the board
  void spawnBall() {
    final startX = GameConstants.gameWidth / 2 + (_random.nextDouble() * 40 - 20);
    const startY = 60.0;

    // Launch with a randomized downward angle
    final angle = (math.pi / 4) + (_random.nextDouble() * (math.pi / 2));
    final velocity = Vector2(
      math.cos(angle) * GameConstants.defaultBallSpeed,
      math.sin(angle) * GameConstants.defaultBallSpeed,
    );

    final ball = BallComponent(
      position: Vector2(startX, startY),
      velocity: velocity,
    );

    world.add(ball);
    ballCountNotifier.value++;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update aggregate metrics from all active balls for HUD
    int totalBounces = 0;
    double maxMultiplier = 1.0;

    final balls = world.children.whereType<BallComponent>();
    for (final b in balls) {
      totalBounces += b.bounceCount;
      if (b.dpsMultiplier > maxMultiplier) {
        maxMultiplier = b.dpsMultiplier;
      }
    }

    totalBouncesNotifier.value = totalBounces;
    peakDpsMultiplierNotifier.value = maxMultiplier;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Tap anywhere on the game field to launch another ball
    spawnBall();
  }
}

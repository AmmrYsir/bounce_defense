import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/config/game_config_loader.dart';
import '../core/constants/game_constants.dart';
import '../models/enemy_config.dart';
import '../models/hero_unit_config.dart';
import '../models/skill_config.dart';
import '../models/wave_config.dart';
import 'components/abilities/floating_text_component.dart';
import 'components/abilities/weapon_bullet_component.dart';
import 'components/ball/ball_component.dart';
import 'components/bouncers/bouncer_component.dart';
import 'components/bouncers/tactical_board_component.dart';
import 'components/bouncers/wall_boundary.dart';
import 'components/enemies/enemy_component.dart';

/// Main Flame Game orchestrating the Bounce Defense two-tier battlefield and tactical grid.
class BounceDefenseGame extends FlameGame
    with HasCollisionDetection, TapCallbacks {
  // Economy & Progression Notifiers for the Flutter UI
  final ValueNotifier<int> goldNotifier =
      ValueNotifier<int>(GameConstants.startingGold);
  final ValueNotifier<int> currentWaveNotifier = ValueNotifier<int>(1);
  final ValueNotifier<double> waveProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> baseHpNotifier =
      ValueNotifier<double>(GameConstants.defaultBaseMaxHp);
  final ValueNotifier<double> maxBaseHpNotifier =
      ValueNotifier<double>(GameConstants.defaultBaseMaxHp);

  // Kinetic & Combat Telemetry Notifiers
  final ValueNotifier<int> ballCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> totalBouncesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> peakDpsMultiplierNotifier =
      ValueNotifier<double>(1.0);
  final ValueNotifier<double> liveDpsNotifier = ValueNotifier<double>(0.0);

  // Tactical Grid & Shop Deck Notifiers
  final ValueNotifier<List<HeroUnitConfig>> shopOffersNotifier =
      ValueNotifier<List<HeroUnitConfig>>([]);
  final ValueNotifier<HeroUnitConfig?> pendingShopUnitNotifier =
      ValueNotifier<HeroUnitConfig?>(null);
  final ValueNotifier<BouncerComponent?> selectedPlacedUnitNotifier =
      ValueNotifier<BouncerComponent?>(null);

  // Wave Reward Card Drafting Modal Notifier (`RewardCardUI`)
  final ValueNotifier<List<SkillDataConfig>> pendingCardChoicesNotifier =
      ValueNotifier<List<SkillDataConfig>>([]);

  // Game Over / Victory state
  final ValueNotifier<bool> isDefeatNotifier = ValueNotifier<bool>(false);

  // Roguelike In-Run Skill Modifiers
  double globalDamageMultiplier = 1.0;
  double critChance = 0.12;
  double critDamageMultiplier = 2.0;
  double bonusRicochetChance = 0.15;
  double bonusSplitChance = 0.10;
  double ballSpeedMultiplier = 1.0;
  int fillCountReduction = 0;

  // Wave Spawner Tracking
  final List<_ScheduledEnemySpawn> _spawnQueue = [];
  int _totalEnemiesInWave = 0;
  int _enemiesKilledInWave = 0;
  double _waveElapsed = 0.0;
  bool _awaitingCardChoice = false;

  // Rolling DPS tracking window
  double _damageAccumulatedThisSecond = 0.0;
  double _dpsWindowTimer = 0.0;

  final math.Random _random = math.Random();
  final List<BouncerComponent> placedUnits = [];

  List<EnemyComponent> get activeEnemies =>
      world.children.whereType<EnemyComponent>().toList();

  int get extraBallCost =>
      GameConstants.baseExtraBallCost + (ballCountNotifier.value * 10);

  @override
  Color backgroundColor() => GameConstants.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Ensure images load directly from root asset paths (`assets/sprites/...`)
    images.prefix = '';

    await GameConfigLoader().loadAll();

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(
        GameConstants.gameWidth,
        GameConstants.gameHeight,
      ),
    );

    // Add Two-Tier Tactical Board & Barricade Renderer
    world.add(TacticalBoardComponent());

    // Add Kinetic Chamber Boundary Walls around the 5x4 Grid
    _createGridChamberBoundaries();

    // Place starter units on the 5x4 Tactical Grid
    _createStarterGridLayout();

    // Roll initial 3 shop unit cards
    rerollShopOffers();

    // Start Wave 1
    _startWave(1);

    // Launch the initial kinetic defender ball
    spawnBall(free: true);
  }

  void _createGridChamberBoundaries() {
    const thickness = 8.0;
    const left = GameConstants.gridAreaLeftX;
    const right = GameConstants.gridAreaRightX;
    const top = GameConstants.gridAreaTopY;
    const bottom = GameConstants.gridAreaBottomY;
    const width = right - left;
    const height = bottom - top;

    world.addAll([
      WallBoundary(
        position: Vector2(left, top),
        size: Vector2(thickness, height),
        orientation: WallOrientation.left,
      ),
      WallBoundary(
        position: Vector2(right - thickness, top),
        size: Vector2(thickness, height),
        orientation: WallOrientation.right,
      ),
      WallBoundary(
        position: Vector2(left, top),
        size: Vector2(width, thickness),
        orientation: WallOrientation.top,
      ),
      WallBoundary(
        position: Vector2(left, bottom - thickness),
        size: Vector2(width, thickness),
        orientation: WallOrientation.bottom,
      ),
    ]);
  }

  void _createStarterGridLayout() {
    final loader = GameConfigLoader();
    // Place 4 starter tactical units in a kinetic loop
    _placeUnitAt(loader.getHeroUnit(1), 1, 1, tailIndex: 0); // PewPewPod -> Right
    _placeUnitAt(loader.getHeroUnit(4), 3, 1, tailIndex: 2); // TwinBlaster -> Down
    _placeUnitAt(loader.getHeroUnit(14), 3, 2, tailIndex: 4); // Rebounder -> Left
    _placeUnitAt(loader.getHeroUnit(3), 1, 2, tailIndex: 6); // Boomerang -> Up
  }

  /// Compute center coordinates for a cell on the 5x4 Tactical Grid
  Vector2 cellCenterFor(int col, int row) {
    final x = GameConstants.gridStartX +
        (col * GameConstants.cellWidth) +
        (GameConstants.cellWidth / 2);
    final y = GameConstants.gridStartY +
        (row * GameConstants.cellHeight) +
        (GameConstants.cellHeight / 2);
    return Vector2(x, y);
  }

  /// Find which placed unit occupies `(col, row)`, or null if empty
  BouncerComponent? unitAtCell(int col, int row) {
    for (final u in placedUnits) {
      if (u.gridCol == col && u.gridRow == row) {
        return u;
      }
    }
    return null;
  }

  BouncerComponent _placeUnitAt(
    HeroUnitConfig config,
    int col,
    int row, {
    int starLevel = 1,
    int? tailIndex,
  }) {
    final pos = cellCenterFor(col, row);
    final dir = tailIndex ?? ((col < 2) ? 0 : 4);
    final unit = BouncerComponent(
      position: pos,
      unitConfig: config,
      gridCol: col,
      gridRow: row,
      starLevel: starLevel,
      tailDirectionIndex: dir,
    );
    placedUnits.add(unit);
    world.add(unit);
    return unit;
  }

  /// Purchase or select a unit from the Bottom Shop Deck
  void buyOrPlaceShopUnit(HeroUnitConfig unitConfig) {
    if (goldNotifier.value < unitConfig.price) {
      _spawnPopupText(
        Vector2(GameConstants.gameWidth / 2, GameConstants.gridAreaTopY + 20),
        'NOT ENOUGH GOLD!',
        color: Colors.redAccent,
      );
      return;
    }

    // 1. Check if there is an empty cell on the 5x4 grid
    for (int r = 0; r < GameConstants.gridRows; r++) {
      for (int c = 0; c < GameConstants.gridCols; c++) {
        if (unitAtCell(c, r) == null) {
          goldNotifier.value -= unitConfig.price;
          final placed = _placeUnitAt(
            unitConfig,
            c,
            r,
            tailIndex: _random.nextInt(8),
          );
          selectedPlacedUnitNotifier.value = placed;
          _spawnPopupText(
            placed.position.clone(),
            '+${unitConfig.displayName}',
            color: Colors.cyanAccent,
          );
          _replaceShopOffer(unitConfig);
          return;
        }
      }
    }

    // 2. If grid is full, check if we can auto-merge with a 1-star matching unit
    for (final existing in placedUnits) {
      if (existing.unitConfig.id == unitConfig.id && existing.starLevel < 5) {
        goldNotifier.value -= unitConfig.price;
        existing.upgradeStarLevel();
        selectedPlacedUnitNotifier.value = existing;
        _spawnPopupText(
          existing.position.clone(),
          'MERGE ★${existing.starLevel}!',
          color: Colors.amberAccent,
        );
        _replaceShopOffer(unitConfig);
        return;
      }
    }
  }

  void _replaceShopOffer(HeroUnitConfig bought) {
    final current = List<HeroUnitConfig>.from(shopOffersNotifier.value);
    final idx = current.indexOf(bought);
    final replacement = GameConfigLoader().rollShopUnits(count: 1);
    if (idx != -1 && replacement.isNotEmpty) {
      current[idx] = replacement.first;
      shopOffersNotifier.value = current;
    }
  }

  /// Free shop reroll (All ADS/IAP blockers disabled!)
  void rerollShopOffers() {
    shopOffersNotifier.value = GameConfigLoader().rollShopUnits(count: 3);
  }

  /// Recycle / sell the currently selected unit on the grid for 70% gold refund
  void recycleSelectedUnit() {
    final unit = selectedPlacedUnitNotifier.value;
    if (unit == null || placedUnits.length <= 1) return;

    final refund = (unit.unitConfig.price * unit.starLevel * 0.7).round();
    goldNotifier.value += refund;
    _spawnPopupText(
      unit.position.clone(),
      '+${refund}g RECYCLED',
      color: Colors.amberAccent,
    );

    placedUnits.remove(unit);
    unit.removeFromParent();
    selectedPlacedUnitNotifier.value = null;
  }

  /// Spawn a new kinetic ball into the Tactical Grid Chamber
  void spawnBall({bool free = false}) {
    if (!free) {
      final cost = extraBallCost;
      if (goldNotifier.value < cost) {
        _spawnPopupText(
          Vector2(GameConstants.gameWidth / 2, GameConstants.gridAreaTopY + 20),
          'NEED ${cost}g FOR BALL!',
          color: Colors.orangeAccent,
        );
        return;
      }
      goldNotifier.value -= cost;
    }

    final startX =
        GameConstants.gameWidth / 2 + (_random.nextDouble() * 50 - 25);
    const startY = GameConstants.gridAreaTopY + 26.0;

    final angle = (math.pi / 6) + (_random.nextDouble() * (2 * math.pi / 3));
    final velocity = Vector2(
      math.cos(angle) * GameConstants.defaultBallSpeed,
      math.sin(angle) * GameConstants.defaultBallSpeed,
    );

    final ball = BallComponent(
      position: Vector2(startX, startY),
      velocity: velocity,
      speedMultiplier: ballSpeedMultiplier,
    );

    world.add(ball);
    ballCountNotifier.value++;
  }

  /// Fired when a placed unit's `FillCount` reaches full charge from ball bounces
  void triggerUnitAttack(
    BouncerComponent unit, {
    required double ballDpsMultiplier,
  }) {
    final cfg = unit.unitConfig;
    final baseDmg = cfg.damageForStar(unit.starLevel);
    final isCrit = _random.nextDouble() < critChance;
    final critMul = isCrit ? critDamageMultiplier : 1.0;

    final finalDamage =
        (baseDmg * 12.0 * ballDpsMultiplier * globalDamageMultiplier * critMul)
            .clamp(4.0, 999999.0);

    final canRicochet =
        cfg.ricochet || (_random.nextDouble() < bonusRicochetChance);
    final canSplit =
        cfg.splitBullet || (_random.nextDouble() < bonusSplitChance);
    final isAoE = cfg.attackPattern == 1 ||
        cfg.id == 2 ||
        cfg.id == 10 ||
        cfg.id == 15 ||
        cfg.id == 20;
    final appliesFreeze = cfg.id == 12 || cfg.id == 17;

    // Multi-shot count (TripleShooter fires 3, TwinBlaster/EchoShot fires 2)
    int shotCount = 1;
    if (cfg.id == 5) {
      shotCount = 3;
    } else if (cfg.id == 4 || (cfg.echoShot && _random.nextDouble() < 0.35)) {
      shotCount = 2;
    }

    // Aim toward target enemy in the top battlefield lane, or straight upward
    Vector2 targetDir = Vector2(0, -1);
    final enemies = activeEnemies;
    if (enemies.isNotEmpty) {
      final target = enemies[_random.nextInt(enemies.length)];
      targetDir = (target.position - unit.position).normalized();
    }

    final baseAngle = math.atan2(targetDir.y, targetDir.x);
    const bulletSpeed = 380.0;

    for (int i = 0; i < shotCount; i++) {
      final spread = (shotCount == 1)
          ? 0.0
          : ((i - (shotCount - 1) / 2.0) * 0.22);
      final vel = Vector2(
        math.cos(baseAngle + spread) * bulletSpeed,
        math.sin(baseAngle + spread) * bulletSpeed,
      );

      world.add(
        WeaponBulletComponent(
          position: unit.position.clone() + Vector2(0, -14),
          velocity: vel,
          damage: finalDamage,
          isCrit: isCrit,
          canRicochet: canRicochet,
          canSplit: canSplit,
          isSplashAoE: isAoE,
          appliesFreeze: appliesFreeze,
          bulletColor: _bulletColorForUnit(cfg.id),
        ),
      );
    }
  }

  Color _bulletColorForUnit(int unitId) {
    switch (unitId) {
      case 1: // PewPewPod
        return const Color(0xFF00E5FF);
      case 2: // Bomb
      case 10: // Flamethrower
        return const Color(0xFFFF6D00);
      case 3: // Boomerang
      case 7: // WoodMaster
        return const Color(0xFF76FF03);
      case 8: // ArcaneMissile
      case 20: // BlackHole
        return const Color(0xFFD500F9);
      case 11: // Poison
        return const Color(0xFF00E676);
      case 12: // Freeze
        return const Color(0xFF80D8FF);
      default:
        return const Color(0xFFFFEA00);
    }
  }

  /// Commander Active Skill: Meteor Shower (`CommanderAbilityMeteorShower`)
  void triggerCommanderMeteorShower() {
    _spawnPopupText(
      Vector2(GameConstants.gameWidth / 2, 160),
      '☄️ METEOR SHOWER!',
      color: Colors.deepOrangeAccent,
      fontSize: 15,
    );
    for (final e in List<EnemyComponent>.from(activeEnemies)) {
      if (!e.isDead) {
        e.takeDamage(85.0 * globalDamageMultiplier, isCrit: true);
      }
    }
  }

  /// Commander Active Skill: Barricade Repair (`CommanderAbilityBarricade`)
  void triggerCommanderWallRepair() {
    baseHpNotifier.value = math.min(
      maxBaseHpNotifier.value,
      baseHpNotifier.value + maxBaseHpNotifier.value * 0.35,
    );
    _spawnPopupText(
      Vector2(GameConstants.gameWidth / 2, GameConstants.barricadeWallY - 12),
      '🛡️ BARRICADE FORTIFIED!',
      color: Colors.greenAccent,
      fontSize: 13,
    );
  }

  void _startWave(int waveNumber) {
    currentWaveNotifier.value = waveNumber;
    waveProgressNotifier.value = 0.0;
    _waveElapsed = 0.0;
    _spawnQueue.clear();

    final WaveConfig waveCfg = GameConfigLoader().getWaveForStage(waveNumber);
    double cursorTime = 0.4;

    if (waveCfg.enemySpawns.isNotEmpty) {
      for (final batch in waveCfg.enemySpawns) {
        final enemyCfg = GameConfigLoader().getEnemy(batch.enemyConfigId);
        final count = batch.count.clamp(1, 25);
        final interval = batch.spawnInterval.clamp(0.45, 3.0);

        for (int i = 0; i < count; i++) {
          _spawnQueue.add(
            _ScheduledEnemySpawn(
              spawnTime: cursorTime,
              enemyConfig: enemyCfg,
              hpMultiplier: waveCfg.hpRatio,
              atkMultiplier: waveCfg.attackRatio,
            ),
          );
          cursorTime += interval * 0.65;
        }
      }
    } else {
      // Fallback wave batch
      final enemyCfg = GameConfigLoader().getEnemy(10001);
      for (int i = 0; i < 6 + waveNumber * 2; i++) {
        _spawnQueue.add(
          _ScheduledEnemySpawn(
            spawnTime: i * 1.4,
            enemyConfig: enemyCfg,
            hpMultiplier: 1.0 + waveNumber * 0.4,
            atkMultiplier: 1.0,
          ),
        );
      }
    }

    // Add a Boss at every 5th wave
    if (waveNumber % 5 == 0) {
      final bossCfg = GameConfigLoader().getEnemy(30007);
      _spawnQueue.add(
        _ScheduledEnemySpawn(
          spawnTime: cursorTime + 1.0,
          enemyConfig: bossCfg,
          hpMultiplier: waveCfg.hpRatio * 1.2,
          atkMultiplier: waveCfg.attackRatio,
        ),
      );
    }

    _totalEnemiesInWave = _spawnQueue.length;
    _enemiesKilledInWave = 0;
  }

  void recordDamageDealt(
    double amount, {
    required Vector2 position,
    bool isCrit = false,
  }) {
    _damageAccumulatedThisSecond += amount;
    _spawnPopupText(
      position + Vector2(0, -14),
      isCrit ? 'CRIT ${amount.toInt()}!' : '-${amount.toInt()}',
      color: isCrit ? Colors.amberAccent : Colors.white,
      fontSize: isCrit ? 13.0 : 10.5,
    );
  }

  void onEnemyKilled(EnemyComponent enemy) {
    _enemiesKilledInWave++;
    final goldReward = enemy.config.isBoss ? 35 : (6 + enemy.config.expReward);
    goldNotifier.value += goldReward;

    _spawnPopupText(
      enemy.position.clone(),
      '+${goldReward}g',
      color: const Color(0xFFFFD700),
      fontSize: 11.5,
    );

    if (_totalEnemiesInWave > 0) {
      waveProgressNotifier.value =
          (_enemiesKilledInWave / _totalEnemiesInWave).clamp(0.0, 1.0);
    }
  }

  void damageBarricade(double amount) {
    if (isDefeatNotifier.value) return;
    baseHpNotifier.value = math.max(0.0, baseHpNotifier.value - amount);
    _spawnPopupText(
      Vector2(
        GameConstants.gameWidth / 2 + (_random.nextDouble() * 60 - 30),
        GameConstants.barricadeWallY,
      ),
      '-${amount.toInt()} HP',
      color: Colors.redAccent,
    );

    if (baseHpNotifier.value <= 0) {
      isDefeatNotifier.value = true;
    }
  }

  /// Apply a drafted Roguelike Skill Card from the Wave Completion Modal (`RewardCardUI`)
  /// NOTE: All RV / Ad cards are 100% unlocked and free with zero blockers!
  void selectSkillCard(SkillDataConfig skill) {
    final name = skill.name.toLowerCase();

    if (name.contains('+1 ball') || skill.skillId == 1) {
      spawnBall(free: true);
    } else if (name.contains('ball speed') || skill.skillId == 3) {
      ballSpeedMultiplier += 0.22;
      for (final b in world.children.whereType<BallComponent>()) {
        b.speedMultiplier = ballSpeedMultiplier;
      }
    } else if (name.contains('heal') ||
        name.contains('wall shield') ||
        skill.skillId == 4 ||
        skill.skillId == 5 ||
        skill.skillId == 35) {
      maxBaseHpNotifier.value += 100;
      baseHpNotifier.value =
          math.min(maxBaseHpNotifier.value, baseHpNotifier.value + 200);
    } else if (name.contains('split') || skill.skillId == 8) {
      bonusSplitChance = (bonusSplitChance + 0.20).clamp(0.0, 0.95);
    } else if (name.contains('critical chance') || skill.skillId == 9) {
      critChance = (critChance + 0.12).clamp(0.0, 0.90);
    } else if (name.contains('critical damage') || skill.skillId == 10) {
      critDamageMultiplier += 0.55;
    } else if (name.contains('fill') || skill.skillId == 16) {
      fillCountReduction += 1;
    } else if (name.contains('ricochet') || skill.skillId == 31) {
      bonusRicochetChance = (bonusRicochetChance + 0.22).clamp(0.0, 0.95);
    } else if (name.contains('coin') || skill.skillId == 39) {
      goldNotifier.value += 60;
    } else {
      // Damage / Ball Boost RV / All other offensive buffs
      globalDamageMultiplier += 0.30;
    }

    pendingCardChoicesNotifier.value = [];
    _awaitingCardChoice = false;

    // Advance to next wave
    _startWave(currentWaveNotifier.value + 1);
  }

  /// Free Reroll of the 3 Wave Completion Skill Cards (No ads!)
  void rerollSkillCards() {
    pendingCardChoicesNotifier.value =
        GameConfigLoader().rollCardChoices(count: 3);
  }

  /// Restart game after defeat
  void restartGame() {
    isDefeatNotifier.value = false;
    baseHpNotifier.value = GameConstants.defaultBaseMaxHp;
    goldNotifier.value = GameConstants.startingGold;

    for (final e in activeEnemies) {
      e.removeFromParent();
    }
    for (final b in world.children.whereType<WeaponBulletComponent>().toList()) {
      b.removeFromParent();
    }

    _startWave(1);
  }

  void _spawnPopupText(
    Vector2 pos,
    String label, {
    Color color = Colors.white,
    double fontSize = 11.5,
  }) {
    world.add(
      FloatingTextComponent(
        position: pos,
        text: label,
        color: color,
        fontSize: fontSize,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDefeatNotifier.value || _awaitingCardChoice) return;

    // 1. Update rolling DPS meter
    _dpsWindowTimer += dt;
    if (_dpsWindowTimer >= 0.5) {
      liveDpsNotifier.value =
          (_damageAccumulatedThisSecond / _dpsWindowTimer).roundToDouble();
      _damageAccumulatedThisSecond = 0.0;
      _dpsWindowTimer = 0.0;
    }

    // 2. Process Wave Enemy Spawner Queue
    _waveElapsed += dt;
    while (_spawnQueue.isNotEmpty &&
        _spawnQueue.first.spawnTime <= _waveElapsed) {
      final item = _spawnQueue.removeAt(0);
      final laneX = 48.0 + _random.nextDouble() * (GameConstants.gameWidth - 96.0);
      final enemy = EnemyComponent(
        config: item.enemyConfig,
        position: Vector2(laneX, GameConstants.enemySpawnTopY),
        hpMultiplier: item.hpMultiplier,
        atkMultiplier: item.atkMultiplier,
      );
      world.add(enemy);
    }

    // 3. Check if Wave is Cleared -> Open 3-Card Reward Drafting Modal (`RewardCardUI`)
    if (_spawnQueue.isEmpty && activeEnemies.isEmpty && !_awaitingCardChoice) {
      _awaitingCardChoice = true;
      waveProgressNotifier.value = 1.0;
      pendingCardChoicesNotifier.value =
          GameConfigLoader().rollCardChoices(count: 3);
    }

    // 4. Update Aggregate Ball Bounce & Peak DPS Telemetry
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

    final tapPos = event.localPosition;
    // Convert screen coordinates to virtual viewport coordinates (400x700)
    final scaleX = GameConstants.gameWidth / size.x;
    final scaleY = GameConstants.gameHeight / size.y;
    final worldPos = Vector2(tapPos.x * scaleX, tapPos.y * scaleY);

    // Check if user tapped inside the 5x4 Tactical Grid
    if (worldPos.y >= GameConstants.gridAreaTopY &&
        worldPos.y <= GameConstants.gridAreaBottomY &&
        worldPos.x >= GameConstants.gridAreaLeftX &&
        worldPos.x <= GameConstants.gridAreaRightX) {
      final col = ((worldPos.x - GameConstants.gridStartX) /
              GameConstants.cellWidth)
          .floor()
          .clamp(0, GameConstants.gridCols - 1);
      final row = ((worldPos.y - GameConstants.gridStartY) /
              GameConstants.cellHeight)
          .floor()
          .clamp(0, GameConstants.gridRows - 1);

      final clickedUnit = unitAtCell(col, row);
      final currentlySelected = selectedPlacedUnitNotifier.value;

      if (clickedUnit != null) {
        // Check if player tapped a second matching unit to MERGE them!
        if (currentlySelected != null &&
            currentlySelected != clickedUnit &&
            currentlySelected.unitConfig.id == clickedUnit.unitConfig.id &&
            currentlySelected.starLevel == clickedUnit.starLevel &&
            clickedUnit.starLevel < 5) {
          clickedUnit.upgradeStarLevel();
          placedUnits.remove(currentlySelected);
          currentlySelected.removeFromParent();
          selectedPlacedUnitNotifier.value = clickedUnit;
          _spawnPopupText(
            clickedUnit.position.clone(),
            'MERGE ★${clickedUnit.starLevel}!',
            color: Colors.amberAccent,
            fontSize: 13.5,
          );
          return;
        }

        // Otherwise select and rotate its bounce tail direction by 45°
        clickedUnit.rotateTailDirection();
        selectedPlacedUnitNotifier.value = clickedUnit;
      } else if (currentlySelected != null) {
        // Move selected unit to the tapped empty cell (`ButtonSetboard`)
        currentlySelected.gridCol = col;
        currentlySelected.gridRow = row;
        currentlySelected.position = cellCenterFor(col, row);
        selectedPlacedUnitNotifier.value = null;
      }
    }
  }
}

class _ScheduledEnemySpawn {
  final double spawnTime;
  final EnemyConfig enemyConfig;
  final double hpMultiplier;
  final double atkMultiplier;

  const _ScheduledEnemySpawn({
    required this.spawnTime,
    required this.enemyConfig,
    required this.hpMultiplier,
    required this.atkMultiplier,
  });
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../../models/enemy_config.dart';
import '../../models/hero_unit_config.dart';
import '../../models/skill_config.dart';
import '../../models/wave_config.dart';

/// Central repository and loader for all reverse-engineered game configurations.
class GameConfigLoader {
  static final GameConfigLoader _instance = GameConfigLoader._internal();
  factory GameConfigLoader() => _instance;
  GameConfigLoader._internal() {
    _seedFallbackDefaults();
  }

  final Map<int, EnemyConfig> _enemies = {};
  final Map<int, WaveConfig> _waves = {};
  final Map<int, SkillDataConfig> _skills = {};
  final Map<int, HeroUnitConfig> _heroes = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Map<int, EnemyConfig> get enemies => _enemies;
  Map<int, WaveConfig> get waves => _waves;
  Map<int, SkillDataConfig> get skills => _skills;
  Map<int, HeroUnitConfig> get heroes => _heroes;

  final math.Random _random = math.Random();

  /// Seed baseline authentic rows synchronously so tests or immediate boot never fail.
  void _seedFallbackDefaults() {
    final defaultHeroes = [
      HeroUnitConfig.fromCsvRow([
        '1', 'PewPewPod', '0', '2', '0', '-1', '1', '1', 'true', 'true', 'true', 'true', 'true', '12', '2', '1|2|3|4.2|5.4'
      ]),
      HeroUnitConfig.fromCsvRow([
        '2', 'Bomb', '0', '2', '1', '-1', '1', '1', 'false', 'true', 'false', 'true', 'true', '20', '6', '2|3|4|5.2|6.4'
      ]),
      HeroUnitConfig.fromCsvRow([
        '3', 'Boomerang', '3', '0', '2', '1', '1', '1', 'false', 'true', 'false', 'true', 'true', '20', '4', '0.5|1|1.6|2.2'
      ]),
      HeroUnitConfig.fromCsvRow([
        '4', 'TwinBlaster', '0', '5', '0', '2', '1', '3', 'true', 'true', 'true', 'true', 'true', '25', '3', '1|2.1|3.2|4.5'
      ]),
      HeroUnitConfig.fromCsvRow([
        '5', 'TripleShooter', '0', '5', '0', '8', '1', '5', 'true', 'true', 'true', 'true', 'true', '30', '4', '1|2.2|3.4|4.9'
      ]),
      HeroUnitConfig.fromCsvRow([
        '8', 'ArcaneMissile', '0', '3', '0', '3', '1', '5', 'false', 'true', 'false', 'true', 'true', '35', '5', '3|4.2|5.4|6.9'
      ]),
      HeroUnitConfig.fromCsvRow([
        '10', 'Flamethrower', '3', '2', '0', '2', '1', '2', 'false', 'true', 'false', 'true', 'true', '30', '5', '5|6.9|8.9|11.3'
      ]),
      HeroUnitConfig.fromCsvRow([
        '12', 'Freeze', '3', '2', '0', '3', '1', '2', 'false', 'true', 'false', 'true', 'true', '30', '4', '2|2.2|2.4|2.7'
      ]),
      HeroUnitConfig.fromCsvRow([
        '14', 'Rebounder', '0', '0', '2', '11', '1', '3', 'false', 'false', 'false', 'true', 'true', '25', '3', '1|1.7|2.4|3.2'
      ]),
      HeroUnitConfig.fromCsvRow([
        '28', 'Katana', '0', '2', '0', '0', '2', '1', 'false', 'true', 'false', 'true', 'true', '25', '5', '3|5|7|9'
      ]),
    ];
    for (final h in defaultHeroes) {
      _heroes[h.id] = h;
    }

    final defaultEnemies = [
      EnemyConfig.fromCsvRow(['10001', 'Minion', 'Enemy 01', '0', '1', '1.5', '2']),
      EnemyConfig.fromCsvRow(['10002', 'Ferocious', 'Enemy 02', '0', '1.2', '2', '3']),
      EnemyConfig.fromCsvRow(['10005', 'Charger', 'Enemy 05 - Short Range - Fast', '0', '0.6', '0.5', '2']),
      EnemyConfig.fromCsvRow(['10101', 'Shield', 'Enemy 10 - Shield', '0', '0.5', '1', '5']),
      EnemyConfig.fromCsvRow(['10102', 'Giant', 'Enemy 11 - Giant', '0', '7', '1', '5']),
      EnemyConfig.fromCsvRow(['10103', 'Mage', 'Enemy 13 - Arcane Mage', '0', '0.8', '1', '5']),
      EnemyConfig.fromCsvRow(['30007', 'Boss', 'Boss 07 - Bouncing Durian', '1', '32', '10', '1']),
    ];
    for (final e in defaultEnemies) {
      _enemies[e.id] = e;
    }

    final defaultSkills = [
      SkillDataConfig.fromCsvRow([
        '1', '1', '0', '-1', '-1', 'Skill Data +1 Ball', 'Skill.PlusOneBall', '', '0', '3', '150', '1|50', '1|130', '1|20', '1|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '2', '2', '0', '-1', '-1', 'Skill Data Ball Boost RV', 'Skill.BallBoost', '', '-1', '-1', '120', '25|50', '35|130', '50|20', '75|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '3', '3', '0', '-1', '-1', 'Skill Data Ball Speed', 'Skill.BallSpeed', '', '-1', '-1', '130', '15|50', '25|130', '40|20', '60|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '4', '4', '0', '-1', '-1', 'Skill Data Base Heal', 'Skill.BaseHeal', '', '-1', '-1', '100', '30|50', '50|130', '80|20', '100|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '8', '8', '0', '-1', '-1', 'Skill Data Bullet Split Chance', 'Skill.Split', '', '-1', '-1', '130', '15|50', '25|130', '40|20', '60|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '9', '9', '0', '-1', '-1', 'Skill Data Critical Chance', 'Skill.CritChance', '', '-1', '-1', '130', '10|50', '20|130', '30|20', '50|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '10', '10', '0', '-1', '-1', 'Skill Data Critical Damage', 'Skill.CritDmg', '', '-1', '-1', '130', '25|50', '50|130', '75|20', '120|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '16', '16', '0', '-1', '-1', 'Skill Data Fill Number Reduce', 'Skill.FillReduce', '', '-1', '-1', '110', '1|50', '1|130', '2|20', '2|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '18', '18', '0', '-1', '-1', 'Skill Data Increase Damage', 'Skill.DmgUp', '', '-1', '-1', '140', '20|50', '35|130', '55|20', '85|10', '-1'
      ]),
      SkillDataConfig.fromCsvRow([
        '31', '31', '0', '-1', '-1', 'Skill Data Ricochet Chance', 'Skill.Ricochet', '', '-1', '-1', '130', '15|50', '25|130', '40|20', '60|10', '-1'
      ]),
    ];
    for (final s in defaultSkills) {
      _skills[s.id] = s;
    }

    final defaultWaves = [
      WaveConfig.fromCsvRow([
        '1', '0:0:0:6:2.2:Enemy 01:10001', 'false', 'Skill Data Ricochet Chance|Skill Data Critical Damage|Skill Data Critical Chance', '1', '1', '30', '35'
      ]),
      WaveConfig.fromCsvRow([
        '2', '0:0:0:8:1.8:Enemy 01:10001|30:0:0:4:2.5:Enemy 02:10002', 'false', '', '1.5', '1', '50', '45'
      ]),
      WaveConfig.fromCsvRow([
        '3', '0:0:0:10:1.5:Enemy 01:10001|25:0:0:5:2.0:Enemy 05 - Short Range - Fast:10005|50:0:0:3:3.0:Enemy 10 - Shield:10101', 'false', '', '2.2', '1.2', '65', '55'
      ]),
    ];
    for (final w in defaultWaves) {
      _waves[w.id] = w;
    }
  }

  /// Load and parse all authentic tables from Flutter bundle
  Future<void> loadAll() async {
    if (_isLoaded) return;

    try {
      await Future.wait([
        _loadEnemies(),
        _loadWaves(),
        _loadSkills(),
        _loadHeroes(),
      ]);
      _isLoaded = true;
    } catch (_) {
      // Fallback already seeded
      _isLoaded = true;
    }
  }

  Future<void> _loadEnemies() async {
    final raw = await rootBundle.loadString('assets/configs/EnemyConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty ||
          line.startsWith('#') ||
          line.startsWith('%') ||
          line.startsWith(r'$')) {
        continue;
      }
      final cols = _splitCsvLine(line);
      if (cols.isNotEmpty) {
        final enemy = EnemyConfig.fromCsvRow(cols);
        if (enemy.id > 0) {
          _enemies[enemy.id] = enemy;
        }
      }
    }
  }

  Future<void> _loadWaves() async {
    final raw = await rootBundle.loadString('assets/configs/WaveConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty ||
          line.startsWith('#') ||
          line.startsWith('%') ||
          line.startsWith(r'$')) {
        continue;
      }
      final cols = _splitCsvLine(line);
      if (cols.isNotEmpty) {
        final wave = WaveConfig.fromCsvRow(cols);
        if (wave.id > 0) {
          _waves[wave.id] = wave;
        }
      }
    }
  }

  Future<void> _loadSkills() async {
    final raw =
        await rootBundle.loadString('assets/configs/SkillDataConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty ||
          line.startsWith('#') ||
          line.startsWith('%') ||
          line.startsWith(r'$')) {
        continue;
      }
      final cols = _splitCsvLine(line);
      if (cols.isNotEmpty) {
        final skill = SkillDataConfig.fromCsvRow(cols);
        if (skill.id > 0) {
          _skills[skill.id] = skill;
        }
      }
    }
  }

  Future<void> _loadHeroes() async {
    final raw = await rootBundle.loadString('assets/configs/HeroConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty ||
          line.startsWith('#') ||
          line.startsWith('%') ||
          line.startsWith(r'$')) {
        continue;
      }
      final cols = _splitCsvLine(line);
      if (cols.isNotEmpty) {
        final hero = HeroUnitConfig.fromCsvRow(cols);
        if (hero.id > 0) {
          _heroes[hero.id] = hero;
        }
      }
    }
  }

  List<String> _splitCsvLine(String line) {
    return line.split(',');
  }

  /// Fetch wave by sequential wave number (1..10 maps to Chapter 1 waves in WaveConfig)
  WaveConfig getWaveForStage(int stageWaveIndex) {
    if (_waves.containsKey(stageWaveIndex)) {
      return _waves[stageWaveIndex]!;
    }
    final chapterKey = 10010100 + stageWaveIndex;
    if (_waves.containsKey(chapterKey)) {
      return _waves[chapterKey]!;
    }
    final allWaves = _waves.values.toList();
    if (allWaves.isNotEmpty) {
      return allWaves[(stageWaveIndex - 1) % allWaves.length];
    }
    return WaveConfig.fromCsvRow([
      '$stageWaveIndex',
      '0:0:0:8:1.5:Enemy 01:10001',
      'false',
      '',
      '${1.0 + stageWaveIndex * 0.6}',
      '1',
      '40',
      '40'
    ]);
  }

  EnemyConfig getEnemy(int id) {
    return _enemies[id] ??
        _enemies[10001] ??
        EnemyConfig.fromCsvRow(['10001', 'Minion', 'Enemy 01', '0', '1', '1.5', '2']);
  }

  HeroUnitConfig getHeroUnit(int id) {
    return _heroes[id] ?? _heroes.values.first;
  }

  /// Roll 3 shop unit offers for the bottom Tactical Shop Deck
  List<HeroUnitConfig> rollShopUnits({int count = 3}) {
    final pool = _heroes.values
        .where((h) => h.unitCategory != 2 && h.price > 0)
        .toList();
    if (pool.isEmpty) return [];

    final selected = <HeroUnitConfig>[];
    for (int i = 0; i < count; i++) {
      selected.add(pool[_random.nextInt(pool.length)]);
    }
    return selected;
  }

  /// Roll N random skill upgrade cards based on authentic weights.
  /// NOTE: All ADS/IAP blockers are completely removed!
  /// Any Rewarded Video (RV) cards are 100% free to draft with no restrictions.
  List<SkillDataConfig> rollCardChoices({int count = 3}) {
    var candidates = _skills.values
        .where((s) => s.name.startsWith('Skill Data') && !s.name.contains('#'))
        .toList();
    if (candidates.isEmpty) {
      candidates = _skills.values.toList();
    }
    if (candidates.isEmpty) return [];

    final selected = <SkillDataConfig>[];
    final available = List<SkillDataConfig>.from(candidates);

    for (int i = 0; i < count && available.isNotEmpty; i++) {
      int totalWeight = 0;
      for (final s in available) {
        totalWeight += (s.baseWeight > 0 ? s.baseWeight : 100);
      }

      int roll = _random.nextInt(math.max(1, totalWeight));
      int accumulated = 0;
      SkillDataConfig? picked;

      for (final s in available) {
        accumulated += (s.baseWeight > 0 ? s.baseWeight : 100);
        if (roll < accumulated) {
          picked = s;
          break;
        }
      }

      picked ??= available.first;
      selected.add(picked);
      available.remove(picked);
    }

    return selected;
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../../models/enemy_config.dart';
import '../../models/skill_config.dart';
import '../../models/wave_config.dart';

/// Central repository and loader for all reverse-engineered game configurations.
class GameConfigLoader {
  static final GameConfigLoader _instance = GameConfigLoader._internal();
  factory GameConfigLoader() => _instance;
  GameConfigLoader._internal();

  final Map<int, EnemyConfig> _enemies = {};
  final Map<int, WaveConfig> _waves = {};
  final Map<int, SkillDataConfig> _skills = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Map<int, EnemyConfig> get enemies => _enemies;
  Map<int, WaveConfig> get waves => _waves;
  Map<int, SkillDataConfig> get skills => _skills;

  final math.Random _random = math.Random();

  /// Load and parse all authentic tables from Flutter bundle
  Future<void> loadAll() async {
    if (_isLoaded) return;

    await Future.wait([
      _loadEnemies(),
      _loadWaves(),
      _loadSkills(),
    ]);

    _isLoaded = true;
  }

  Future<void> _loadEnemies() async {
    final raw = await rootBundle.loadString('assets/configs/EnemyConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#') || line.startsWith('%') || line.startsWith(r'$')) {
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
      if (line.isEmpty || line.startsWith('#') || line.startsWith('%') || line.startsWith(r'$')) {
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
    final raw = await rootBundle.loadString('assets/configs/SkillDataConfig.json');
    final lines = const LineSplitter().convert(raw);

    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#') || line.startsWith('%') || line.startsWith(r'$')) {
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

  /// Helper to handle CSV values with possible quoted content
  List<String> _splitCsvLine(String line) {
    return line.split(',');
  }

  /// Fetch wave by index or ID (defaults to wave 1 if not found)
  WaveConfig? getWave(int waveIndex) {
    if (_waves.containsKey(waveIndex)) {
      return _waves[waveIndex];
    }
    // Fallback: return first available wave
    return _waves.values.isNotEmpty ? _waves.values.first : null;
  }

  /// Fetch enemy by ID
  EnemyConfig? getEnemy(int id) {
    return _enemies[id];
  }

  /// Roll N random skill upgrade cards based on authentic base weights.
  /// NOTE: All ADS/IAP blockers are completely removed!
  /// Any Rewarded Video (RV) cards are 100% free to draft with no restrictions.
  List<SkillDataConfig> rollCardChoices({int count = 3}) {
    final candidates = _skills.values.where((s) => s.baseWeight > 0).toList();
    if (candidates.isEmpty) return [];

    final selected = <SkillDataConfig>[];
    final available = List<SkillDataConfig>.from(candidates);

    for (int i = 0; i < count && available.isNotEmpty; i++) {
      int totalWeight = 0;
      for (final s in available) {
        totalWeight += s.baseWeight;
      }

      int roll = _random.nextInt(totalWeight);
      int accumulated = 0;
      SkillDataConfig? picked;

      for (final s in available) {
        accumulated += s.baseWeight;
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

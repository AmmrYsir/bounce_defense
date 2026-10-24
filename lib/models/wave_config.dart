/// Specific spawn instruction for an enemy group within a wave.
class WaveEnemySpawn {
  final int progressPercent;
  final int spawnType; // 0: random, 1: group
  final bool isBoss;
  final int count;
  final double spawnInterval;
  final String prefabName;
  final int enemyConfigId;

  const WaveEnemySpawn({
    required this.progressPercent,
    required this.spawnType,
    required this.isBoss,
    required this.count,
    required this.spawnInterval,
    required this.prefabName,
    required this.enemyConfigId,
  });

  /// Parse from string chunk like `0:0:0:5:3:Enemy 01:10001`
  static WaveEnemySpawn? parse(String chunk) {
    final parts = chunk.split(':');
    if (parts.length < 7) return null;

    final progress = int.tryParse(parts[0]) ?? 0;
    final spawnType = int.tryParse(parts[1]) ?? 0;
    final isBoss = (int.tryParse(parts[2]) ?? 0) == 1;
    final count = int.tryParse(parts[3]) ?? 1;
    final interval = double.tryParse(parts[4]) ?? 1.0;
    final prefab = parts[5].trim();
    final configId = int.tryParse(parts[6]) ?? 0;

    return WaveEnemySpawn(
      progressPercent: progress,
      spawnType: spawnType,
      isBoss: isBoss,
      count: count,
      spawnInterval: interval,
      prefabName: prefab,
      enemyConfigId: configId,
    );
  }
}

/// Wave progression entry from `WaveConfig`.
class WaveConfig {
  final int id;
  final List<WaveEnemySpawn> enemySpawns;
  final bool isExtra;
  final List<String> predefinedSkills;
  final double hpRatio;
  final double attackRatio;
  final int totalExp;
  final int totalCoin;

  const WaveConfig({
    required this.id,
    required this.enemySpawns,
    required this.isExtra,
    required this.predefinedSkills,
    required this.hpRatio,
    required this.attackRatio,
    required this.totalExp,
    required this.totalCoin,
  });

  /// Parse from WaveConfig Luban CSV line
  factory WaveConfig.fromCsvRow(List<String> columns) {
    // Columns: id, EnemyWaveInfoList, IsExtra, PredefinedSkillList, hp_ratio, attack_ratio, total_exp, total_coin
    final id = int.tryParse(columns[0].trim()) ?? 0;
    
    final spawns = <WaveEnemySpawn>[];
    if (columns.length > 1 && columns[1].trim().isNotEmpty) {
      final entries = columns[1].trim().split('|');
      for (final e in entries) {
        final spawn = WaveEnemySpawn.parse(e.trim());
        if (spawn != null) spawns.add(spawn);
      }
    }

    final isExtra = columns.length > 2 && columns[2].trim().toLowerCase() == 'true';

    final skills = <String>[];
    if (columns.length > 3 && columns[3].trim().isNotEmpty) {
      final entries = columns[3].trim().split('|');
      for (final s in entries) {
        if (s.trim().isNotEmpty) skills.add(s.trim());
      }
    }

    final hpRatio = columns.length > 4 ? double.tryParse(columns[4].trim()) ?? 1.0 : 1.0;
    final atkRatio = columns.length > 5 ? double.tryParse(columns[5].trim()) ?? 1.0 : 1.0;
    final totalExp = columns.length > 6 ? int.tryParse(columns[6].trim()) ?? 0 : 0;
    final totalCoin = columns.length > 7 ? int.tryParse(columns[7].trim()) ?? 0 : 0;

    return WaveConfig(
      id: id,
      enemySpawns: spawns,
      isExtra: isExtra,
      predefinedSkills: skills,
      hpRatio: hpRatio,
      attackRatio: atkRatio,
      totalExp: totalExp,
      totalCoin: totalCoin,
    );
  }
}

/// Data model representing an enemy or boss definition from `EnemyConfig`.
class EnemyConfig {
  final int id;
  final String description;
  final String prefabName;
  final bool isBoss;
  final double baseHp;
  final double baseAtk;
  final int expReward;
  final List<int> extraBehavior;

  const EnemyConfig({
    required this.id,
    required this.description,
    required this.prefabName,
    required this.isBoss,
    required this.baseHp,
    required this.baseAtk,
    required this.expReward,
    required this.extraBehavior,
  });

  /// Parse a line from EnemyConfig Luban CSV
  factory EnemyConfig.fromCsvRow(List<String> columns) {
    final id = int.tryParse(columns[0].trim()) ?? 0;
    final des = columns.length > 1 ? columns[1].trim() : '';
    final prefab = columns.length > 2 ? columns[2].trim() : '';
    final category =
        columns.length > 3 ? int.tryParse(columns[3].trim()) ?? 0 : 0;
    final hp =
        columns.length > 4 ? double.tryParse(columns[4].trim()) ?? 1.0 : 1.0;
    final atk =
        columns.length > 5 ? double.tryParse(columns[5].trim()) ?? 1.0 : 1.0;
    final exp = columns.length > 6 ? int.tryParse(columns[6].trim()) ?? 1 : 1;

    final extra = <int>[];
    if (columns.length > 7 && columns[7].trim().isNotEmpty) {
      final parts = columns[7].trim().split('|');
      for (final p in parts) {
        final val = int.tryParse(p);
        if (val != null) extra.add(val);
      }
    }

    return EnemyConfig(
      id: id,
      description: des,
      prefabName: prefab,
      isBoss: category == 1,
      baseHp: hp,
      baseAtk: atk,
      expReward: exp,
      extraBehavior: extra,
    );
  }

  /// Resolve corresponding extracted sprite path in `assets/sprites/`
  String get spriteAssetPath {
    if (prefabName.contains('Shield') || id == 10101 || id == 11101) {
      return 'assets/sprites/Enemy_10_-_Shield.png';
    }
    if (prefabName.contains('Giant') || id == 10102 || isBoss) {
      return 'assets/sprites/Enemy_11_-_Giant.png';
    }
    if (prefabName.contains('Arcane') ||
        prefabName.contains('Long Range') ||
        id == 10103 ||
        id == 10004) {
      return 'assets/sprites/Enemy_13_-_Arcane_Mage.png';
    }
    if (prefabName.contains('Absorber') || id == 10104) {
      return 'assets/sprites/Enemy_14_-_Absorber.png';
    }
    if (prefabName.contains('Enemy 12') ||
        prefabName.contains('Fast') ||
        prefabName.contains('Suicide')) {
      return 'assets/sprites/Enemy_12.png';
    }
    return 'assets/sprites/monster_1_big.png';
  }

  /// Flame images.load takes path relative to `assets/images/` unless prefix is cleared,
  /// or we pass the full path when `images.prefix = ''`.
  String get cleanDisplayName {
    if (prefabName.isEmpty) return isBoss ? 'Boss' : 'Enemy';
    return prefabName;
  }
}

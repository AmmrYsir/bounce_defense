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
    // Columns: id, Des, PrefabName, EnemyCategory, hp, atk, Exp, ExtraBehavior
    final id = int.tryParse(columns[0].trim()) ?? 0;
    final des = columns.length > 1 ? columns[1].trim() : '';
    final prefab = columns.length > 2 ? columns[2].trim() : '';
    final category = columns.length > 3 ? int.tryParse(columns[3].trim()) ?? 0 : 0;
    final hp = columns.length > 4 ? double.tryParse(columns[4].trim()) ?? 1.0 : 1.0;
    final atk = columns.length > 5 ? double.tryParse(columns[5].trim()) ?? 1.0 : 1.0;
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

  /// Resolve corresponding extracted sprite path
  String get spriteAssetPath {
    final sanitized = prefabName.replaceAll(' ', '_');
    // Try matching specific extracted enemy names or fallback to standard
    return 'assets/sprites/$sanitized.png';
  }
}

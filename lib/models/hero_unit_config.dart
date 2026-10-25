/// Represents a placeable Tactical Grid Unit / Weapon from `HeroConfig.json`.
class HeroUnitConfig {
  final int id;
  final String rawName;
  final String displayName;
  final int unitCategory; // 0: Damage, 1: Debuff, 2: Special, 3: AoE/Control
  final int targetType;
  final int attackPattern; // 0: Bullet, 1: AoE Lob, 2: Melee/Orbit/Bounce
  final int unlockChapterIndex;
  final int startingLevel;
  final bool ricochet;
  final bool echoShot;
  final bool splitBullet;
  final bool receiveSupportBuff;
  final bool canBeRecycled;
  final int price;
  final int fillCount;
  final List<double> levelValues;

  const HeroUnitConfig({
    required this.id,
    required this.rawName,
    required this.displayName,
    required this.unitCategory,
    required this.targetType,
    required this.attackPattern,
    required this.unlockChapterIndex,
    required this.startingLevel,
    required this.ricochet,
    required this.echoShot,
    required this.splitBullet,
    required this.receiveSupportBuff,
    required this.canBeRecycled,
    required this.price,
    required this.fillCount,
    required this.levelValues,
  });

  /// Parse a row from `HeroConfig.json` Luban CSV.
  factory HeroUnitConfig.fromCsvRow(List<String> cols) {
    final id = int.tryParse(cols[0].trim()) ?? 0;
    final rawName = cols.length > 1 ? cols[1].trim() : 'Unit $id';
    final displayName = _cleanEnglishName(id, rawName);
    final category = cols.length > 2 ? int.tryParse(cols[2].trim()) ?? 0 : 0;
    final targetType = cols.length > 3 ? int.tryParse(cols[3].trim()) ?? 0 : 0;
    final pattern = cols.length > 4 ? int.tryParse(cols[4].trim()) ?? 0 : 0;
    final unlockChap = cols.length > 5 ? int.tryParse(cols[5].trim()) ?? -1 : -1;
    final startLvl = cols.length > 7 ? int.tryParse(cols[7].trim()) ?? 1 : 1;
    final ricochet = cols.length > 8 && cols[8].trim().toLowerCase() == 'true';
    final echo = cols.length > 9 && cols[9].trim().toLowerCase() == 'true';
    final split = cols.length > 10 && cols[10].trim().toLowerCase() == 'true';
    final support = cols.length > 11 && cols[11].trim().toLowerCase() == 'true';
    final recycle = cols.length > 12 && cols[12].trim().toLowerCase() == 'true';
    final price = cols.length > 13 ? int.tryParse(cols[13].trim()) ?? 15 : 15;
    final fillCount = cols.length > 14 ? int.tryParse(cols[14].trim()) ?? 3 : 3;

    final values = <double>[];
    if (cols.length > 15 && cols[15].trim().isNotEmpty) {
      for (final p in cols[15].trim().split('|')) {
        final v = double.tryParse(p.trim());
        if (v != null) values.add(v);
      }
    }
    if (values.isEmpty) {
      values.add(1.5);
    }

    return HeroUnitConfig(
      id: id,
      rawName: rawName,
      displayName: displayName,
      unitCategory: category,
      targetType: targetType,
      attackPattern: pattern,
      unlockChapterIndex: unlockChap,
      startingLevel: startLvl,
      ricochet: ricochet,
      echoShot: echo,
      splitBullet: split,
      receiveSupportBuff: support,
      canBeRecycled: recycle,
      price: price,
      fillCount: fillCount < 1 ? 2 : fillCount,
      levelValues: values,
    );
  }

  static String _cleanEnglishName(int id, String raw) {
    // Strip trailing non-ASCII characters (Chinese notes in CSV)
    final asciiOnly = raw.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
    if (asciiOnly.isNotEmpty) {
      switch (asciiOnly) {
        case 'PewPewPod':
          return 'Pew-Pew Pod';
        case 'TwinBlaster':
          return 'Twin Blaster';
        case 'TripleShooter':
          return 'Triple Shooter';
        case 'QuickshotQuill':
          return 'Quickshot Quill';
        case 'WoodMaster':
          return 'Wood Master';
        case 'ArcaneMissile':
          return 'Arcane Missile';
        case 'BlackHole':
          return 'Black Hole';
        default:
          return asciiOnly;
      }
    }
    switch (id) {
      case 26:
        return 'Energy Turret';
      case 27:
        return 'Aircraft Factory';
      default:
        return 'Unit #$id';
    }
  }

  /// Base damage for a given star level (1-based).
  double damageForStar(int star) {
    final idx = ((star - 1) * 3).clamp(0, levelValues.length - 1);
    return levelValues[idx] * (1.0 + (star - 1) * 0.65);
  }

  /// Authentic extracted icon sprite path in `assets/sprites/`.
  String get iconAssetPath {
    if (id >= 1 && id <= 12) {
      final numStr = id.toString().padLeft(2, '0');
      return 'assets/sprites/$numStr.png';
    }
    switch (id) {
      case 13: // Durian
        return 'assets/sprites/07.png';
      case 14: // Rebounder
        return 'assets/sprites/GlowWheel.png';
      case 15: // Exploding Rock
        return 'assets/sprites/02.png';
      case 16: // Kunai
        return 'assets/sprites/06.png';
      case 17: // Glue
        return 'assets/sprites/GlueBottle.png';
      case 18: // Rotten Tomato
        return 'assets/sprites/RottenTomato.png';
      case 19: // Inverter
        return 'assets/sprites/InvertGun.png';
      case 20: // BlackHole
        return 'assets/sprites/black-hole.png';
      case 21: // Landmine
        return 'assets/sprites/Landmine.png';
      case 22: // Detonator
        return 'assets/sprites/Detonode.png';
      case 26: // Energy Turret
        return 'assets/sprites/09.png';
      case 27: // Aircraft Factory
        return 'assets/sprites/08.png';
      case 28: // Katana
        return 'assets/sprites/06.png';
      default:
        return 'assets/sprites/01.png';
    }
  }

  /// Authentic unit tile background sprite based on star rank.
  static String tileBgAssetForStar(int star) {
    switch (star) {
      case 1:
        return 'assets/sprites/Unit_bg_green.png';
      case 2:
        return 'assets/sprites/Unit_bg_blue.png';
      case 3:
        return 'assets/sprites/Unit_bg_purple.png';
      case 4:
        return 'assets/sprites/Unit_bg_yellow.png';
      default:
        return 'assets/sprites/Unit_bg_red.png';
    }
  }
}

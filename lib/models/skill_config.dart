/// Quality tier for a skill upgrade card.
enum SkillRarity {
  common,
  rare,
  epic,
  legendary,
}

/// A tier-specific value roll (e.g. +10% with weight 50)
class SkillTierValue {
  final int value;
  final int weight;

  const SkillTierValue({required this.value, required this.weight});

  static SkillTierValue? parse(String chunk) {
    final parts = chunk.split('|');
    if (parts.length < 2) return null;
    final val = int.tryParse(parts[0]) ?? 0;
    final weight = int.tryParse(parts[1]) ?? 0;
    return SkillTierValue(value: val, weight: weight);
  }
}

/// Roguelike skill/card configuration from `SkillDataConfig`.
class SkillDataConfig {
  final int id;
  final int skillId;
  final String name;
  final String descriptionKey;
  final int star;
  final int upperLimit;
  final int baseWeight;
  
  /// True if this card was originally locked behind Rewarded Video Ads (RV).
  /// In this recreation, ALL ADS ARE DISABLED and rewards are unlocked freely!
  final bool isAdPerk;

  final SkillTierValue? commonTier;
  final SkillTierValue? rareTier;
  final SkillTierValue? epicTier;
  final SkillTierValue? legendaryTier;

  const SkillDataConfig({
    required this.id,
    required this.skillId,
    required this.name,
    required this.descriptionKey,
    required this.star,
    required this.upperLimit,
    required this.baseWeight,
    required this.isAdPerk,
    this.commonTier,
    this.rareTier,
    this.epicTier,
    this.legendaryTier,
  });

  /// Parse a line from SkillDataConfig CSV
  factory SkillDataConfig.fromCsvRow(List<String> columns) {
    // Columns: id, skill_id, skill_add_type, hero_id, des1, des2, des_key, setting_des_key, star, upper_limit, base_weight, value_weight1, value_weight2, value_weight3, value_weight4, refresh
    final id = int.tryParse(columns[0].trim()) ?? 0;
    final skillId = columns.length > 1 ? int.tryParse(columns[1].trim()) ?? 0 : 0;
    final name = columns.length > 5 ? columns[5].trim() : (columns.length > 4 ? columns[4].trim() : 'Skill $id');
    final desKey = columns.length > 6 ? columns[6].trim() : '';
    final star = columns.length > 8 ? int.tryParse(columns[8].trim()) ?? 0 : 0;
    final limit = columns.length > 9 ? int.tryParse(columns[9].trim()) ?? 1 : 1;
    final weight = columns.length > 10 ? int.tryParse(columns[10].trim()) ?? 100 : 100;

    // Detect if this was originally an RV (Rewarded Video) ad perk
    final isAd = name.toUpperCase().contains(' RV') || name.toUpperCase().contains('AD');

    final t1 = columns.length > 11 ? SkillTierValue.parse(columns[11].trim()) : null;
    final t2 = columns.length > 12 ? SkillTierValue.parse(columns[12].trim()) : null;
    final t3 = columns.length > 13 ? SkillTierValue.parse(columns[13].trim()) : null;
    final t4 = columns.length > 14 ? SkillTierValue.parse(columns[14].trim()) : null;

    return SkillDataConfig(
      id: id,
      skillId: skillId,
      name: name,
      descriptionKey: desKey,
      star: star,
      upperLimit: limit,
      baseWeight: weight,
      isAdPerk: isAd,
      commonTier: t1,
      rareTier: t2,
      epicTier: t3,
      legendaryTier: t4,
    );
  }

  /// Get the effective bonus value for a given rarity
  int getValueForRarity(SkillRarity rarity) {
    switch (rarity) {
      case SkillRarity.common:
        return commonTier?.value ?? 1;
      case SkillRarity.rare:
        return rareTier?.value ?? commonTier?.value ?? 1;
      case SkillRarity.epic:
        return epicTier?.value ?? rareTier?.value ?? 1;
      case SkillRarity.legendary:
        return legendaryTier?.value ?? epicTier?.value ?? 1;
    }
  }
}

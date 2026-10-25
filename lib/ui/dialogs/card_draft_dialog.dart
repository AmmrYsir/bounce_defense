import 'package:flutter/material.dart';

import '../../models/skill_config.dart';

/// Authentic 3-Card Wave Completion Drafting Modal (`RewardCardUI` / `RewardCard_v3`).
/// Uses the extracted card backgrounds (`hong_card_UIbg.png`, `huang_card_Banner.png`)
/// and rarity frames (`Rarity_card1.png`..`Rarity_card4.png`).
/// All RV / Ad blockers are disabled — perks and rerolls are 100% free!
class CardDraftOverlay extends StatelessWidget {
  final List<SkillDataConfig> choices;
  final ValueChanged<SkillDataConfig> onSelectCard;
  final VoidCallback onFreeReroll;

  const CardDraftOverlay({
    super.key,
    required this.choices,
    required this.onSelectCard,
    required this.onFreeReroll,
  });

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Banner (`huang_card_Banner.png`)
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/sprites/huang_card_Banner.png',
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(height: 52),
                ),
                const Text(
                  'CHOOSE WAVE UPGRADE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Authentic Reward Cards (`PackCard (01)`..`(03)`)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < choices.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _RewardCardItem(
                        skill: choices[i],
                        index: i,
                        onTap: () => onSelectCard(choices[i]),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            // Free Reroll Button (No Ads / No Blocker!)
            GestureDetector(
              onTap: onFreeReroll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B0FF), Color(0xFF0081CB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white54, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/sprites/Refresh_Button.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FREE REROLL (NO ADS)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCardItem extends StatelessWidget {
  final SkillDataConfig skill;
  final int index;
  final VoidCallback onTap;

  const _RewardCardItem({
    required this.skill,
    required this.index,
    required this.onTap,
  });

  String get _cleanTitle {
    return skill.name
        .replaceAll('Skill Data ', '')
        .replaceAll(' RV', '')
        .trim();
  }

  String get _effectDescription {
    final lower = skill.name.toLowerCase();
    if (lower.contains('+1 ball')) {
      return 'Spawns +1 extra kinetic ball onto the tactical grid!';
    }
    if (lower.contains('ball speed')) {
      return 'Increases kinetic ball velocity by +22%!';
    }
    if (lower.contains('split')) {
      return 'Projectiles gain +20% chance to fork into 2 shots!';
    }
    if (lower.contains('ricochet')) {
      return 'Bullets gain +22% chance to ricochet between enemies!';
    }
    if (lower.contains('critical chance')) {
      return 'Increases weapon Critical Hit Rate by +12%!';
    }
    if (lower.contains('critical damage')) {
      return 'Increases Critical Strike Multiplier by +55%!';
    }
    if (lower.contains('fill')) {
      return 'Reduces all placed unit Fill Counts by -1 bounce!';
    }
    if (lower.contains('heal') || lower.contains('wall')) {
      return 'Restores +200 Barricade Wall HP & increases Max HP!';
    }
    return 'Boosts all tactical unit weapon damage by +30%!';
  }

  String get _iconAsset {
    final lower = skill.name.toLowerCase();
    if (lower.contains('critical')) return 'assets/sprites/CritDamage_.png';
    if (lower.contains('fill')) return 'assets/sprites/Fill_Number_Reduce.png';
    if (lower.contains('range') || lower.contains('split')) {
      return 'assets/sprites/Skill_Range.png';
    }
    return 'assets/sprites/Skill_Duration.png';
  }

  String get _rarityFrameAsset {
    if (skill.isAdPerk) return 'assets/sprites/Rarity_card4.png';
    final r = (index % 3) + 1;
    return 'assets/sprites/Rarity_card$r.png';
  }

  @override
  Widget build(BuildContext context) {
    final bgAsset = skill.isAdPerk
        ? 'assets/sprites/huang_card_UIbg.png'
        : 'assets/sprites/hong_card_UIbg.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 225,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card Background Texture (`hong_card_UIbg.png` / `huang_card_UIbg.png`)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                bgAsset,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF28354A),
                ),
              ),
            ),

            // Rarity Border Frame (`Rarity_card*.png`)
            IgnorePointer(
              child: Image.asset(
                _rarityFrameAsset,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Free Bonus Badge if formerly an RV Perk
                  if (skill.isAdPerk)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFAB00),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '★ FREE BONUS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),

                  // Skill Icon
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: Image.asset(
                      _iconAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.auto_awesome,
                        color: Colors.amberAccent,
                        size: 28,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    _cleanTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // Description
                  Text(
                    _effectDescription,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      height: 1.2,
                    ),
                  ),

                  // Claim Button (`ButtonClaim`)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SELECT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

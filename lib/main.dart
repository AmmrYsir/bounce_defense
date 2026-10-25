import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/config/game_config_loader.dart';
import 'game/bounce_defense_game.dart';
import 'game/components/bouncers/bouncer_component.dart';
import 'models/hero_unit_config.dart';
import 'models/skill_config.dart';
import 'ui/dialogs/card_draft_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameConfigLoader().loadAll();
  runApp(const BounceDefenseApp());
}

class BounceDefenseApp extends StatelessWidget {
  const BounceDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bounce Defense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E131F),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BounceDefenseGame _game;

  @override
  void initState() {
    super.initState();
    _game = BounceDefenseGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                // 1. Two-Tier Flame Game Canvas (Top Battlefield + 5x4 Tactical Grid)
                Positioned.fill(
                  child: GameWidget(game: _game),
                ),

                // 2. Authentic Top Header HUD (`Header`, `GoldInfo`, `TimeRoot`, `DPS`)
                Positioned(
                  top: 6,
                  left: 8,
                  right: 8,
                  child: _buildTopHeaderHud(),
                ),

                // 3. Commander Abilities & Selected Unit Inspector (`UnitStatInfoPanel`)
                Positioned(
                  top: 62,
                  left: 10,
                  right: 10,
                  child: _buildCommanderAndUnitInspectorBar(),
                ),

                // 4. Authentic Bottom Tactical Shop & Deck (`OfflineBottomRoot`)
                Positioned(
                  bottom: 6,
                  left: 8,
                  right: 8,
                  child: _buildBottomShopDeck(),
                ),

                // 5. Wave Completion 3-Card Drafting Modal (`RewardCardUI`)
                Positioned.fill(
                  child: ValueListenableBuilder<List<SkillDataConfig>>(
                    valueListenable: _game.pendingCardChoicesNotifier,
                    builder: (context, choices, _) {
                      if (choices.isEmpty) return const SizedBox.shrink();
                      return CardDraftOverlay(
                        choices: choices,
                        onSelectCard: _game.selectSkillCard,
                        onFreeReroll: _game.rerollSkillCards,
                      );
                    },
                  ),
                ),

                // 6. Defeat / Retry Modal (`Homa_SoulQuest_Product_DefeatMenuAppear`)
                Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _game.isDefeatNotifier,
                    builder: (context, isDefeat, _) {
                      if (!isDefeat) return const SizedBox.shrink();
                      return _buildDefeatOverlay();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeaderHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162035).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E436E), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gold Counter (`GoldInfo` + `gold_coin1.png`)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1220),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/sprites/gold_coin1.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 5),
                ValueListenableBuilder<int>(
                  valueListenable: _game.goldNotifier,
                  builder: (context, gold, _) => Text(
                    '$gold',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Center Wave Banner & Progress Bar (`TimeRoot`)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BOUNCE DEFENSE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: Colors.cyanAccent.shade200,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<int>(
                        valueListenable: _game.currentWaveNotifier,
                        builder: (context, wave, _) => Text(
                          'Wave $wave / 10',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: _game.waveProgressNotifier,
                  builder: (context, progress, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFF0B101C),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E5FF),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Bounces & DPS Telemetry (`DPS Manager`)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _game.totalBouncesNotifier,
                builder: (context, bounces, _) => _buildCompactMetric(
                  icon: Icons.autorenew_rounded,
                  label: 'Bounces',
                  value: '$bounces',
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<double>(
                valueListenable: _game.peakDpsMultiplierNotifier,
                builder: (context, mult, _) => _buildCompactMetric(
                  icon: Icons.bolt_rounded,
                  label: 'Max DPS',
                  value: '${mult.toStringAsFixed(1)}x',
                  color: const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCommanderAndUnitInspectorBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Selected Placed Unit Inspector (`UnitStatInfoPanel Gameplay`)
        Expanded(
          child: ValueListenableBuilder<BouncerComponent?>(
            valueListenable: _game.selectedPlacedUnitNotifier,
            builder: (context, selected, _) {
              if (selected == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Tap grid unit to rotate bounce tail or merge matching ★ units',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9.5,
                    ),
                  ),
                );
              }

              final cfg = selected.unitConfig;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xDD17253B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      cfg.iconAssetPath,
                      width: 20,
                      height: 20,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.shield,
                        size: 16,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${cfg.displayName} (★${selected.starLevel}) • Fill: ${selected.requiredFillCount}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _game.recycleSelectedUnit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SELL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 6),

        // Free Commander Active Skills (`CommanderAbilityMeteorShower`, `Barricade`)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCommanderSkillBtn(
              label: '☄️ Meteor',
              color: const Color(0xFFFF6D00),
              onTap: _game.triggerCommanderMeteorShower,
            ),
            const SizedBox(width: 4),
            _buildCommanderSkillBtn(
              label: '🛡️ Repair',
              color: const Color(0xFF00C853),
              onTap: _game.triggerCommanderWallRepair,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommanderSkillBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomShopDeck() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141D30).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B3E63), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Purchasable Tactical Unit Cards (`InGameShopUnitDealManager`)
          ValueListenableBuilder<List<HeroUnitConfig>>(
            valueListenable: _game.shopOffersNotifier,
            builder: (context, offers, _) {
              return Row(
                children: [
                  for (final unit in offers)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildShopUnitCard(unit),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // Bottom Action Row: Free Reroll + Add Ball Button
          Row(
            children: [
              // Free Reroll Button (`Refresh_Button.png` - No Ads!)
              Expanded(
                child: GestureDetector(
                  onTap: _game.rerollShopOffers,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/sprites/Refresh_Button.png',
                          width: 16,
                          height: 16,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Free Reroll',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Add Ball Button (`ExtraBallPurchaseLogic`)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _game.spawnBall(free: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                  label: ValueListenableBuilder<int>(
                    valueListenable: _game.ballCountNotifier,
                    builder: (context, count, _) {
                      return Text(
                        'Add Ball (${_game.extraBallCost}g)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopUnitCard(HeroUnitConfig unit) {
    return GestureDetector(
      onTap: () => _game.buyOrPlaceShopUnit(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2B44),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF3E588C),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Unit Rarity Tile + Icon (`Unit_bg_green.png` + `01.png`..`12.png`)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/sprites/Unit_bg_green.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  Image.asset(
                    unit.iconAssetPath,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    unit.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fill: ${unit.fillCount}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Image.asset(
                        'assets/sprites/gold_coin1.png',
                        width: 11,
                        height: 11,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.circle,
                          size: 10,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${unit.price}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefeatOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1A243B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BARRICADE BREACHED',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enemy forces overwhelmed the defense line!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _game.restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(42),
                ),
                child: const Text(
                  'RETRY STAGE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

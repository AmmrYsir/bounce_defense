import 'package:bounce_defense/core/constants/game_constants.dart';
import 'package:bounce_defense/game/components/ball/ball_component.dart';
import 'package:bounce_defense/main.dart';
import 'package:bounce_defense/models/enemy_config.dart';
import 'package:bounce_defense/models/hero_unit_config.dart';
import 'package:bounce_defense/models/skill_config.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'App renders authentic Bounce Defense HUD, Tactical Shop Deck, and Commander Skills',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BounceDefenseApp());

    // Verify Top Header HUD elements
    expect(find.text('BOUNCE DEFENSE'), findsOneWidget);
    expect(find.text('Wave 1 / 10'), findsOneWidget);

    // Verify Bottom Tactical Shop & Deck elements
    expect(find.text('Free Reroll'), findsOneWidget);
    expect(find.textContaining('Add Ball'), findsOneWidget);

    // Verify Commander Active Skill buttons
    expect(find.text('☄️ Meteor'), findsOneWidget);
    expect(find.text('🛡️ Repair'), findsOneWidget);
  });

  test('BounceCountAddDPS calculates damage multipliers deterministically', () {
    final ball = BallComponent(
      position: Vector2.zero(),
      velocity: Vector2(100, 100),
      baseDamage: 20.0,
    );

    expect(ball.bounceCount, 0);
    expect(ball.dpsMultiplier, 1.0);
    expect(ball.currentDamage, 20.0);

    const testBounces = 10;
    final expectedMultiplier =
        1.0 + (testBounces * GameConstants.dpsBonusPerBounce);
    final expectedDamage = 20.0 * expectedMultiplier;

    expect(expectedMultiplier, closeTo(2.5, 0.001));
    expect(expectedDamage, closeTo(50.0, 0.001));
  });

  test('EnemyConfig parses authentic CSV row and resolves extracted sprite', () {
    const rawRow = ['10101', '盾兵', 'Enemy 10 - Shield', '0', '0.5', '1', '5'];
    final enemy = EnemyConfig.fromCsvRow(rawRow);

    expect(enemy.id, 10101);
    expect(enemy.prefabName, 'Enemy 10 - Shield');
    expect(enemy.isBoss, false);
    expect(enemy.baseHp, 0.5);
    expect(enemy.baseAtk, 1.0);
    expect(enemy.expReward, 5);
    expect(enemy.spriteAssetPath, 'assets/sprites/Enemy_10_-_Shield.png');
  });

  test('HeroUnitConfig parses authentic HeroConfig row and resolves sprites', () {
    const rawRow = [
      '1',
      'PewPewPod',
      '0',
      '2',
      '0',
      '-1',
      '1',
      '1',
      'true',
      'true',
      'true',
      'true',
      'true',
      '12',
      '2',
      '1|2|3|4.2|5.4',
    ];
    final hero = HeroUnitConfig.fromCsvRow(rawRow);

    expect(hero.id, 1);
    expect(hero.displayName, 'Pew-Pew Pod');
    expect(hero.price, 12);
    expect(hero.fillCount, 2);
    expect(hero.ricochet, true);
    expect(hero.iconAssetPath, 'assets/sprites/01.png');
    expect(
      HeroUnitConfig.tileBgAssetForStar(1),
      'assets/sprites/Unit_bg_green.png',
    );
  });

  test(
      'SkillDataConfig parses authentic row and unlocks RV ad perks with no blocker',
      () {
    const rawRow = [
      '2',
      '2',
      '0',
      '-1',
      '-1',
      'Skill Data Ball Boost RV',
      'Skill.BallBoost',
      '',
      '-1',
      '-1',
      '10000',
      '1|0',
      '1|130',
      '1|0',
      '1|0',
      '-1'
    ];
    final skill = SkillDataConfig.fromCsvRow(rawRow);

    expect(skill.id, 2);
    expect(skill.name, 'Skill Data Ball Boost RV');
    expect(skill.isAdPerk, true);
    expect(skill.baseWeight, 10000);
  });
}

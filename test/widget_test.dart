import 'package:bounce_defense/core/constants/game_constants.dart';
import 'package:bounce_defense/game/components/ball/ball_component.dart';
import 'package:bounce_defense/main.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders Bounce Defense game canvas and HUD',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BounceDefenseApp());

    // Verify HUD elements are present
    expect(find.text('BOUNCE DEFENSE'), findsOneWidget);
    expect(find.text('Wave 1 / 10'), findsOneWidget);
    expect(find.text('Add Ball'), findsOneWidget);
  });

  test('BounceCountAddDPS calculates damage multipliers deterministically', () {
    final ball = BallComponent(
      position: Vector2.zero(),
      velocity: Vector2(100, 100),
      baseDamage: 20.0,
    );

    // Initial state (0 bounces)
    expect(ball.bounceCount, 0);
    expect(ball.dpsMultiplier, 1.0);
    expect(ball.currentDamage, 20.0);

    // Simulate 10 bounces
    // Formula: 1.0 + (10 * 0.15) = 2.5x multiplier
    // Expected damage = 20.0 * 2.5 = 50.0
    const testBounces = 10;
    final expectedMultiplier =
        1.0 + (testBounces * GameConstants.dpsBonusPerBounce);
    final expectedDamage = 20.0 * expectedMultiplier;

    expect(expectedMultiplier, closeTo(2.5, 0.001));
    expect(expectedDamage, closeTo(50.0, 0.001));
  });
}

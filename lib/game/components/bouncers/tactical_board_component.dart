import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../bounce_defense_game.dart';

/// Renders the two-tier Bounce Defense arena:
/// 1) Top Enemy Battlefield & lanes
/// 2) Segmented RPG Wall Barricade & Shield + HP bar
/// 3) Bottom 5x4 Tactical Placement Grid (`Cell Holder`) + Neighbor Synergy Lines
class TacticalBoardComponent extends PositionComponent
    with HasGameReference<BounceDefenseGame> {
  TacticalBoardComponent()
      : super(
          position: Vector2.zero(),
          size: Vector2(GameConstants.gameWidth, GameConstants.gameHeight),
          priority: GameConstants.zIndexGridCells,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _renderBattlefieldZone(canvas);
    _renderBarricadeWall(canvas);
    _renderTacticalGrid(canvas);
    _renderSynergyConnections(canvas);
  }

  void _renderBattlefieldZone(Canvas canvas) {
    // Top Enemy March Battlefield background
    final bfRect = const Rect.fromLTWH(
      0,
      62,
      GameConstants.gameWidth,
      GameConstants.barricadeWallY - 62,
    );
    canvas.drawRect(
      bfRect,
      Paint()..color = GameConstants.battlefieldColor,
    );

    // Subtle vertical marching lane dividers
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 5; i++) {
      final lx = i * (GameConstants.gameWidth / 5);
      canvas.drawLine(
        Offset(lx, 66),
        Offset(lx, GameConstants.barricadeWallY),
        lanePaint,
      );
    }
  }

  void _renderBarricadeWall(Canvas canvas) {
    const wallY = GameConstants.barricadeWallY;
    const wallHeight = 16.0;

    // 9 Segmented RPG Wall blocks (`RPG Wall (01)`..`(09)`)
    const segments = 9;
    const segWidth = (GameConstants.gameWidth - 32.0) / segments;
    for (int i = 0; i < segments; i++) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          16.0 + i * segWidth + 1.5,
          wallY,
          segWidth - 3.0,
          wallHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xFF2C3E50),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Barricade HP Bar overlay (`CFXR3 HP`)
    final hpRatio =
        (game.baseHpNotifier.value / game.maxBaseHpNotifier.value).clamp(0.0, 1.0);
    const barW = 180.0;
    const barH = 10.0;
    const barX = (GameConstants.gameWidth - barW) / 2;
    const barY = wallY + 3.0;

    final bgRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(barX, barY, barW, barH),
      const Radius.circular(5),
    );
    canvas.drawRRect(bgRRect, Paint()..color = const Color(0xDD090D16));

    final fillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barX, barY, barW * hpRatio, barH),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      fillRRect,
      Paint()
        ..color = hpRatio > 0.35
            ? const Color(0xFF00E676)
            : const Color(0xFFFF1744),
    );

    final hpTp = TextPainter(
      text: TextSpan(
        text:
            'WALL HP ${game.baseHpNotifier.value.toInt()}/${game.maxBaseHpNotifier.value.toInt()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hpTp.paint(
      canvas,
      Offset(
        GameConstants.gameWidth / 2 - hpTp.width / 2,
        barY + (barH - hpTp.height) / 2,
      ),
    );
  }

  void _renderTacticalGrid(Canvas canvas) {
    // Outer kinetic chamber frame
    final boardRect = RRect.fromRectAndRadius(
      const Rect.fromLTRB(
        GameConstants.gridAreaLeftX,
        GameConstants.gridAreaTopY,
        GameConstants.gridAreaRightX,
        GameConstants.gridAreaBottomY,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      boardRect,
      Paint()..color = GameConstants.gridBoardColor,
    );
    canvas.drawRRect(
      boardRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final hasPendingBuy = game.pendingShopUnitNotifier.value != null;
    final selectedUnit = game.selectedPlacedUnitNotifier.value;

    // Draw 5x4 placement cells (`Cell Holder`)
    for (int r = 0; r < GameConstants.gridRows; r++) {
      for (int c = 0; c < GameConstants.gridCols; c++) {
        final center = game.cellCenterFor(c, r);
        final cellRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.x, center.y),
            width: GameConstants.cellWidth - 8.0,
            height: GameConstants.cellHeight - 8.0,
          ),
          const Radius.circular(10),
        );

        final occupant = game.unitAtCell(c, r);
        final isSelected = occupant != null && occupant == selectedUnit;

        canvas.drawRRect(
          cellRect,
          Paint()
            ..color = isSelected
                ? const Color(0xFF1F3A52)
                : const Color(0xFF151E30).withValues(alpha: 0.75),
        );

        canvas.drawRRect(
          cellRect,
          Paint()
            ..color = isSelected
                ? Colors.amberAccent
                : (hasPendingBuy && occupant == null
                    ? const Color(0xFF00E676).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.09))
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected || (hasPendingBuy && occupant == null)
                ? 1.8
                : 1.0,
        );
      }
    }
  }

  void _renderSynergyConnections(Canvas canvas) {
    final units = game.placedUnits;
    if (units.length < 2) return;

    final synergyPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22)
      ..strokeWidth = 2.0;

    for (int i = 0; i < units.length; i++) {
      for (int j = i + 1; j < units.length; j++) {
        final a = units[i];
        final b = units[j];
        final dc = (a.gridCol - b.gridCol).abs();
        final dr = (a.gridRow - b.gridRow).abs();
        if (dc + dr == 1) {
          canvas.drawLine(
            Offset(a.position.x, a.position.y),
            Offset(b.position.x, b.position.y),
            synergyPaint,
          );
        }
      }
    }
  }
}

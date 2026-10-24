import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/bounce_defense_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFF10141E),
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
        child: Stack(
          children: [
            // The Flame Game Canvas
            GameWidget(game: _game),

            // Top HUD Overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopHud(),
            ),

            // Bottom Control Overlay
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2234).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wave & Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BOUNCE DEFENSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.cyanAccent.shade200,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Wave 1 / 10',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Total Bounces Counter
          ValueListenableBuilder<int>(
            valueListenable: _game.totalBouncesNotifier,
            builder: (context, bounces, child) {
              return _buildStatBadge(
                icon: Icons.refresh_rounded,
                label: 'Bounces',
                value: '$bounces',
                color: Colors.amberAccent,
              );
            },
          ),

          // Peak DPS Multiplier
          ValueListenableBuilder<double>(
            valueListenable: _game.peakDpsMultiplierNotifier,
            builder: (context, dps, child) {
              return _buildStatBadge(
                icon: Icons.bolt_rounded,
                label: 'Max DPS',
                value: '${dps.toStringAsFixed(1)}x',
                color: Colors.redAccent.shade200,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Helper hint
        const Expanded(
          child: Text(
            '💡 Tap anywhere on board to launch balls',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Spawn Ball button
        ElevatedButton.icon(
          onPressed: _game.spawnBall,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent.shade700,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text(
            'Add Ball',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

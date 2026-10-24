# AGENTS.md — Development & Architecture Guidelines

Welcome to the **Bounce Defense** codebase. This document outlines operational protocols, architectural standards, and workflow instructions for AI agents (and human developers) working on this project.

---

## 🎯 Mission & Project Context

The objective of this project is to build an open-source, high-performance Flutter recreation of the hybrid mobile game **"Bounce Defense"**.

### Primary Reference Artifact
- **Location**: [`tmp/Bounce Defense.apk`](file:///c:/Users/ammar/Desktop/Jangan%20sentuh/bounce_defense/tmp/Bounce%20Defense.apk)
- **Package ID**: `com.minigamelab.bouncedefense`
- **Engine**: Unity 6 (`6000.3.10f1`), IL2CPP Metadata v39
- **Scope**: Serves as the source of truth for gameplay mechanics, balance numbers, wave pacing, boss patterns, and audio-visual design.
- **Git Policy**: The `tmp/` folder is explicitly gitignored. Never attempt to stage, commit, or push `.apk` or large binary extraction dumps to remote repositories.

---

## 🏛️ Architectural Principles

### 1. Engine & Simulation Decoupling
- **Game Engine**: Built using [Flame Engine](https://flame-engine.org/) or Flutter `CustomPainter` with 2D rigid-body/vector physics (e.g., `forge2d` or custom kinematic bounce solver).
- **Decouple Physics from Rendering**: Ensure simulation state (ball positions, velocities, HP, damage ticks) can update deterministically independent of frame rate or render passes.
- **Flutter UI as Overlays**: HUD, health bars, card drafting popups, and shop dialogs must be rendered using standard Flutter widgets overlaid on top of the game canvas.

### 2. Performance & Memory Budget
- **Object Pooling**: Mandatory for high-frequency entities (`EnemyBulletPool`, `Ball`, particle emitters, damage numbers). Avoid creating new heap allocations during the active combat loop.
- **Spatial Partitioning / Collision Optimization**: Keep collision checks fast (bounding circles/AABBs for pins/bouncers) to maintain 60–120 FPS on mobile hardware.
- **Const Constructors**: Use `const` everywhere possible for UI widgets and immutable data models.

### 3. Data-Driven Game Design
- Game entities must be configured via typed data models (`ArtifactConfig`, `CardConfig`, `EnemyConfig`, `WaveConfig`) rather than hardcoded logic.
- Keep configuration structures aligned with the reverse-engineered formulas found in the reference APK (e.g. `BounceCountAddDPS`, `BulletRicochetChancePercent`, `CritDamageMultiply`).

---

## 🔍 Reverse Engineering & REA Protocols

When extracting formulas, balance curves, or asset structures from the reference APK:
1. **Tooling**:
   - Utilize the active **REA (Reverse Engineer Anything)** MCP tools (`call_mcp_tool` with server `rea`) or fast CLI utilities (`rg`, `tar`).
   - For Android/Java metadata, inspect manifest and dex structures without executing the binary.
   - For IL2CPP symbols, reference `global-metadata.dat` for class and field identifiers.
2. **Hygiene**:
   - Always clean up temporary extracted files from `tmp/` after analysis to prevent cluttering the disk and context.

---

## 📂 Code Organization Standards

```
lib/
├── core/
│   ├── constants/            # Game constants, physics constants, layer z-indexes
│   ├── audio/                # Sound effects and background music controller
│   └── pool/                 # Generic object pooling implementation
├── game/
│   ├── bounce_game.dart      # Main Flame Game or GameController class
│   ├── components/
│   │   ├── ball/             # Ball entity, movement curves, bounce counters
│   │   ├── bouncers/         # Pins, bumpers, dynamic obstacles, bricks
│   │   ├── enemies/          # Walkers, ranged casters, bosses (Durian, Bird)
│   │   └── abilities/        # Commander abilities (Laser, Barricade, Meteor)
│   └── systems/
│       ├── combat_system.dart# Damage, crit, ricochet, and split calculators
│       └── wave_system.dart  # Wave progression and enemy spawner logic
├── models/
│   ├── card_model.dart       # Roguelike card definitions and tier pools
│   ├── artifact_model.dart   # Persistent artifacts and upgrade weights
│   └── enemy_config.dart     # Enemy HP, speed, and attack patterns
└── ui/
    ├── hud/                  # Health, wave counter, DPS display
    ├── dialogs/              # Card selection modal, victory/defeat screen
    └── lobby/                # Commander selection, artifact gallery, meta upgrades
```

---

## 🧪 Testing & Verification Expectations

- **Physics Determinism Tests**: Unit tests in `test/physics/` verifying that ball angle reflections and damage multiplier calculations (`BounceCountAddDPS`) compute exactly according to formulas.
- **Combat Formula Tests**: Unit tests in `test/combat/` verifying critical hit chances, armor/reduction math, and bullet ricochet behavior.
- **Linter Compliance**: Maintain clean code adhering to `analysis_options.yaml` (`flutter_lints`). Always run `flutter analyze` or check for analyzer warnings before considering an implementation complete.

---

## 🤝 Collaboration & Agent Protocol

1. **Be Proactive & Incremental**: Implement features step-by-step (e.g. Core Bounce Physics -> Enemy Waves -> Combat Resolver -> Card Drafting UI).
2. **Documentation Integrity**: When adding new mechanics, update `README.md` and inline docstrings to match.
3. **User Confirmation**: Seek user input before introducing major structural changes (such as selecting between pure Flutter `CustomPainter` vs `Flame` + `Forge2D`).

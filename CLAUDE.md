# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A match-3 puzzle game built with Flutter/Dart. Players swap adjacent gems to create matches of 3+ in a row/column, triggering cascades, scoring, and level progression. Free and open source, funded by voluntary donations (Ko-fi).

## Build & Run Commands

```bash
flutter run                          # Run on connected device/emulator
flutter run -d chrome                # Run in Chrome (web)
flutter run -d linux                 # Run on Linux desktop
flutter build apk                    # Build Android APK
flutter test                         # Run all tests
flutter test test/game/              # Run tests in a directory
flutter test test/game/match_detector_test.dart  # Run a single test file
flutter analyze                      # Static analysis (uses flutter_lints)
flutter pub get                      # Install dependencies
```

## Architecture

### State Management
- Uses `InheritedWidget` pattern (no third-party state management). `GameStateManagerProvider` and `MusicManagerProvider` in `lib/main.dart` provide state to the widget tree.
- `GameStateManager` (ChangeNotifier) is the central state hub: manages save data, coins, level progression, settings, and emoji themes. Persists to a local JSON file with debounced saves.
- Access via `GameStateManagerProvider.of(context)` (rebuilds on change) or `.read(context)` (no rebuild).

### Game Engine (lib/game/)
The match-3 logic is split into focused, composable handlers:
- **Board + Gem model** (`lib/models/`): `Board` holds a `List<List<Gem?>>` grid. `Gem` has a `GemType` (6 colors) and `SpecialType` (striped, bomb, rainbow).
- **MatchDetector**: Finds horizontal/vertical runs of 3+. Returns `Match` objects with positions and pattern info.
- **SwapHandler**: Validates and executes gem swaps between adjacent positions.
- **GravityHandler**: Drops gems down to fill empty cells, spawns new gems at the top.
- **CascadeEngine**: Orchestrates the match-clear-gravity loop. Each `CascadeStep` tracks matches and cascade level for score multipliers.
- **SpecialGemHandler**: Creates and activates special gems (striped clears row/col, bomb clears 3x3, rainbow clears a color).
- **DeadlockDetector / HintTimer**: Detects no-valid-moves states, provides hint suggestions.
- **ScoreCalculator**: Computes points from matches with cascade multipliers.
- **LevelGenerator**: Procedurally generates `LevelConfig` from a level number (objective type, constraints, obstacles, board size).
- **ObstacleManager**: Manages ice/stone/chain/slime obstacles on the board.
- **SaveSystem**: `SaveState` with coins, level records, player stats, power-ups, bonus moves regeneration, and daily login rewards. Serializes to/from JSON.

### Screens (lib/screens/)
- `MainMenuScreen` -> `LevelSelectScreen` -> `GameScreen` (with optional `LevelConfig`)
- `GameScreen` handles both level mode (with move/time constraints) and free/endless mode (when `levelConfig` is null)
- `SettingsScreen`, `ShopScreen` for settings and in-game shop

### Visual System
- Gems render as emoji (via `EmojiTheme` system with swappable themes) or as custom-painted diamonds (`GemPainter` with `GemVisualDef` defining cut, shape, rarity, colors).
- 24 gem visual variants (4 per color, escalating rarity).
- `ParticleSystem` and `ScreenEffects` widgets handle match/combo visual effects.

### Audio
- `AudioManager`: SFX playback (match, swap, combo, win, lose sounds in `assets/sounds/`)
- `MusicManager`: Background music, reacts to settings changes

## Testing Patterns

- Test helper `createTestApp()` in `test/helpers/test_helpers.dart` wraps widgets with required providers (GameStateManagerProvider, MusicManagerProvider, MaterialApp).
- `GameStateManager` accepts optional `SaveState`, `GameSettings`, and `DirectoryProvider` for test injection.
- `Board.fromGrid()` creates boards from literal grid data for deterministic testing.
- Game logic classes (MatchDetector, GravityHandler, etc.) are pure/stateless and testable without Flutter widgets.

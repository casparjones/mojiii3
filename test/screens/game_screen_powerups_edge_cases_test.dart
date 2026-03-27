import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen Power-Up edge cases', () {
    testWidgets('power-up bar shows in level mode with saveState',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 3);
      final config = const LevelGenerator().generate(1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            levelConfig: config,
            saveState: saveState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('powerup_extra_moves_btn')), findsOneWidget);
      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('extra moves adds 20 to movesRemaining in level mode',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 1);
      final config = const LevelGenerator().generate(1);
      final key = GlobalKey<GameScreenState>();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            key: key,
            levelConfig: config,
            saveState: saveState,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialMoves = key.currentState!.movesRemaining;

      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.pumpAndSettle();

      expect(key.currentState!.movesRemaining, initialMoves + 20);
      expect(saveState.powerUpCount('powerup_extra_moves'), 0);
    });

    testWidgets('using all power-ups shows x0 count', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('x1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.pumpAndSettle();

      expect(find.text('x0'), findsWidgets);
    });

    testWidgets('onPowerUpUsed called for shuffle', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_shuffle', count: 1);
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            saveState: saveState,
            onPowerUpUsed: () => called = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('powerup_shuffle_btn')));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('color bomb button shows dialog when tapped', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_color_bomb', count: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('powerup_color_bomb_btn')));
      await tester.pumpAndSettle();

      // Dialog should appear asking to choose a color
      expect(find.text('Choose a color to destroy'), findsOneWidget);
    });

    testWidgets('power-up counts display correctly for multiple power-ups',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 5);
      saveState.addPowerUp('powerup_shuffle', count: 10);
      saveState.addPowerUp('powerup_color_bomb', count: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('x5'), findsOneWidget);
      expect(find.text('x10'), findsOneWidget);
      // x0 appears for both color_bomb (0) and mega_moves (0)
      expect(find.text('x0'), findsNWidgets(2));
    });

    testWidgets('tapping disabled power-up button does not crash',
        (tester) async {
      final saveState = SaveState();
      // All 0

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      // Tap all disabled buttons - should not crash
      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.tap(find.byKey(const Key('powerup_shuffle_btn')));
      await tester.tap(find.byKey(const Key('powerup_color_bomb_btn')));
      await tester.pumpAndSettle();

      // Nothing should have changed
      expect(saveState.powerUpCount('powerup_extra_moves'), 0);
    });

    testWidgets('power-up inventory persists through JSON round-trip',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 3);
      saveState.addPowerUp('powerup_shuffle', count: 2);
      saveState.addPowerUp('powerup_color_bomb', count: 1);

      final json = saveState.toJsonString();
      final restored = SaveState.fromJsonString(json);

      expect(restored.powerUpCount('powerup_extra_moves'), 3);
      expect(restored.powerUpCount('powerup_shuffle'), 2);
      expect(restored.powerUpCount('powerup_color_bomb'), 1);
    });

    testWidgets('addPowerUp accumulates correctly', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_shuffle', count: 2);
      saveState.addPowerUp('powerup_shuffle', count: 3);

      expect(saveState.powerUpCount('powerup_shuffle'), 5);
    });

    testWidgets('usePowerUp returns false for non-existent power-up',
        (tester) async {
      final saveState = SaveState();
      expect(saveState.usePowerUp('nonexistent'), false);
    });
  });
}

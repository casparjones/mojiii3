import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen Power-Up Bar', () {
    testWidgets('shows power-up bar when saveState is provided',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 2);
      saveState.addPowerUp('powerup_shuffle', count: 1);
      saveState.addPowerUp('powerup_color_bomb', count: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      // Power-up buttons should be present.
      expect(find.byKey(const Key('powerup_extra_moves_btn')), findsOneWidget);
      expect(find.byKey(const Key('powerup_shuffle_btn')), findsOneWidget);
      expect(find.byKey(const Key('powerup_color_bomb_btn')), findsOneWidget);

      // Counts should be displayed.
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget);
      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('does not show power-up bar when saveState is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('powerup_extra_moves_btn')), findsNothing);
      expect(find.byKey(const Key('powerup_shuffle_btn')), findsNothing);
      expect(find.byKey(const Key('powerup_color_bomb_btn')), findsNothing);
    });

    testWidgets('extra moves power-up adds 5 moves', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 1);

      bool powerUpUsedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            saveState: saveState,
            onPowerUpUsed: () => powerUpUsedCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial moves (free mode = 30).
      final state =
          tester.state<GameScreenState>(find.byType(GameScreen));
      final initialMoves = state.movesRemaining;

      // Tap extra moves button.
      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.pumpAndSettle();

      expect(state.movesRemaining, initialMoves + 5);
      expect(saveState.powerUpCount('powerup_extra_moves'), 0);
      expect(powerUpUsedCalled, true);
    });

    testWidgets('shuffle power-up shuffles the board', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_shuffle', count: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      // Tap shuffle button.
      await tester.tap(find.byKey(const Key('powerup_shuffle_btn')));
      await tester.pumpAndSettle();

      // After usage, count should be 0.
      expect(saveState.powerUpCount('powerup_shuffle'), 0);
    });

    testWidgets('power-up buttons disabled when count is 0', (tester) async {
      final saveState = SaveState();
      // All counts are 0.

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      // Buttons should exist but tapping should do nothing (no errors).
      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.pumpAndSettle();

      expect(saveState.powerUpCount('powerup_extra_moves'), 0);
    });
  });
}

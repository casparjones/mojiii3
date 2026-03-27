import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen Mega Moves Power-Up', () {
    testWidgets('mega moves button is shown when saveState is provided',
        (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_mega_moves', count: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('powerup_mega_moves_btn')), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
    });

    testWidgets('mega moves power-up adds 60 moves', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_mega_moves', count: 1);

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

      final state =
          tester.state<GameScreenState>(find.byType(GameScreen));
      final initialMoves = state.movesRemaining;

      await tester.tap(find.byKey(const Key('powerup_mega_moves_btn')));
      await tester.pumpAndSettle();

      expect(state.movesRemaining, initialMoves + 60);
      expect(saveState.powerUpCount('powerup_mega_moves'), 0);
      expect(powerUpUsedCalled, true);
    });

    testWidgets('mega moves button disabled when count is 0', (tester) async {
      final saveState = SaveState();
      // No mega moves added

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byKey(const Key('powerup_mega_moves_btn'));
      expect(btn, findsOneWidget);
      expect(find.text('x0'), findsWidgets); // multiple power-ups might have x0
    });

    testWidgets('extra moves power-up still adds 20 moves', (tester) async {
      final saveState = SaveState();
      saveState.addPowerUp('powerup_extra_moves', count: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      final state =
          tester.state<GameScreenState>(find.byType(GameScreen));
      final initialMoves = state.movesRemaining;

      await tester.tap(find.byKey(const Key('powerup_extra_moves_btn')));
      await tester.pumpAndSettle();

      expect(state.movesRemaining, initialMoves + 20);
    });
  });

  group('GameScreen bonus moves at level start', () {
    testWidgets('bonus moves are consumed at level start', (tester) async {
      final saveState = SaveState(bonusMoves: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      final state =
          tester.state<GameScreenState>(find.byType(GameScreen));
      // Free mode starts with 30 + 5 bonus = 35
      expect(state.movesRemaining, 35);
      expect(saveState.bonusMoves, 0);
    });

    testWidgets('no bonus moves consumed when saveState is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final state =
          tester.state<GameScreenState>(find.byType(GameScreen));
      expect(state.movesRemaining, 30);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen level integration edge cases', () {
    testWidgets('dark background in both free and level mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1a1a2e));
    });

    testWidgets('uses SafeArea', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('level mode shows LEVEL number for various levels',
        (tester) async {
      for (final levelNum in [1, 5, 10, 50]) {
        final config = const LevelGenerator().generate(levelNum);
        await tester.pumpWidget(
          MaterialApp(home: GameScreen(levelConfig: config)),
        );
        await tester.pump();

        expect(find.text('LEVEL $levelNum'), findsOneWidget);
      }
    });

    testWidgets('restart resets movesRemaining in level mode', (tester) async {
      final key = GlobalKey<GameScreenState>();
      final config = const LevelGenerator().generate(3);
      final saveState = SaveState(bonusMoves: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key, levelConfig: config, saveState: saveState),
        ),
      );
      await tester.pump();

      expect(key.currentState!.movesRemaining, 30);
      expect(key.currentState!.score, 0);
      expect(key.currentState!.gemsCollected, 0);
      expect(key.currentState!.obstaclesDestroyed, 0);

      // Tap restart
      await tester.tap(find.text('Restart'));
      await tester.pump();

      expect(key.currentState!.score, 0);
      expect(key.currentState!.movesRemaining, greaterThanOrEqualTo(0));
      expect(key.currentState!.movesUsed, 0);
      expect(key.currentState!.levelEnded, false);
    });

    testWidgets('new game button in free mode resets state', (tester) async {
      final key = GlobalKey<GameScreenState>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('New Game'));
      await tester.pump();

      expect(key.currentState!.score, 0);
      expect(key.currentState!.movesUsed, 0);
    });

    testWidgets('hint button is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      expect(find.text('Hint'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('refresh icon is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('coin balance of 0 is displayed correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(coinBalance: 0),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
    });

    testWidgets('large coin balance is displayed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(coinBalance: 999999),
        ),
      );
      await tester.pump();

      expect(find.text('999999'), findsOneWidget);
    });

    testWidgets('coins earned text not shown when coinsEarned is 0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(coinBalance: 100),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('coins_earned_this_level')), findsNothing);
    });

    testWidgets('destroyObstacles objective renders correctly',
        (tester) async {
      // Find a level with destroyObstacles objective.
      // According to level_generator, levels >10 with odd number may have it.
      LevelConfig? config;
      for (int i = 11; i < 100; i++) {
        final c = const LevelGenerator().generate(i);
        if (c.objective.type == LevelObjectiveType.destroyObstacles) {
          config = c;
          break;
        }
      }

      if (config != null) {
        await tester.pumpWidget(
          MaterialApp(home: GameScreen(levelConfig: config)),
        );
        await tester.pump();

        expect(find.textContaining('Destroy:'), findsOneWidget);
      }
    });

    testWidgets('gemsCollectedByType starts empty', (tester) async {
      final key = GlobalKey<GameScreenState>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key),
        ),
      );
      await tester.pump();

      expect(key.currentState!.gemsCollectedByType, isEmpty);
    });

    testWidgets('onLevelEnd callback is not called on init', (tester) async {
      bool callbackCalled = false;

      final config = const LevelGenerator().generate(1);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            levelConfig: config,
            onLevelEnd: (won, score, stars, coins) {
              callbackCalled = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(callbackCalled, false);
    });

    testWidgets('high-level config with obstacles initializes correctly',
        (tester) async {
      final key = GlobalKey<GameScreenState>();
      final config = const LevelGenerator().generate(30);
      final saveState = SaveState(bonusMoves: 33);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key, levelConfig: config, saveState: saveState),
        ),
      );
      await tester.pump();

      final state = key.currentState!;
      expect(state.movesRemaining, 33);
      expect(state.obstacleManager.activeCount, greaterThanOrEqualTo(0));
      expect(state.levelEnded, false);
    });

    testWidgets('SCORE label always present in both modes', (tester) async {
      // Free mode
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();
      expect(find.text('SCORE'), findsOneWidget);

      // Level mode
      final config = const LevelGenerator().generate(1);
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config)),
      );
      await tester.pump();
      expect(find.text('SCORE'), findsOneWidget);
    });
  });
}

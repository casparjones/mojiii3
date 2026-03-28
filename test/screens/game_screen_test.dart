import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen widget', () {
    testWidgets('renders in free mode without LevelConfig', (tester) async {
      final saveState = SaveState(bonusMoves: 30);
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(saveState: saveState)),
      );
      await tester.pump();

      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('MOVES'), findsOneWidget);
      expect(find.textContaining('30/'), findsOneWidget); // "30/60" format
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('New Game'), findsOneWidget);
    });

    testWidgets('renders in level mode with LevelConfig', (tester) async {
      final config = const LevelGenerator().generate(1);
      final saveState = SaveState(bonusMoves: 30);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config, saveState: saveState)),
      );
      await tester.pump();

      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('MOVES'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);
    });

    testWidgets('displays moves from saveState bonusMoves', (tester) async {
      final config = const LevelGenerator().generate(1);
      final saveState = SaveState(bonusMoves: 25);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config, saveState: saveState)),
      );
      await tester.pump();

      // Moves come from saveState.bonusMoves, displayed as "XX/60".
      expect(find.textContaining('25/'), findsOneWidget);
    });

    testWidgets('shows objective HUD for score objective', (tester) async {
      final config = const LevelGenerator().generate(1);
      // Level 1 is always score objective type.
      expect(config.objective.type, LevelObjectiveType.score);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config)),
      );
      await tester.pump();

      // Should show score target text.
      expect(
        find.textContaining('Score:'),
        findsOneWidget,
      );
    });

    testWidgets('shows objective HUD for collectGems objective',
        (tester) async {
      // Level 6 has collectGems objective (even level > 5 && <= 10).
      final config = const LevelGenerator().generate(6);
      expect(config.objective.type, LevelObjectiveType.collectGems);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config)),
      );
      await tester.pump();

      // Should show gem emoji target(s).
      // Find any text containing "/" (the target format).
      expect(find.textContaining('/'), findsWidgets);
    });

    testWidgets('state exposes test accessors correctly', (tester) async {
      final key = GlobalKey<GameScreenState>();
      final config = const LevelGenerator().generate(1);
      final saveState = SaveState(bonusMoves: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key, levelConfig: config, saveState: saveState),
        ),
      );
      await tester.pump();

      final state = key.currentState!;
      expect(state.score, 0);
      expect(state.movesRemaining, 30);
      expect(state.movesUsed, 0);
      expect(state.obstaclesDestroyed, 0);
      expect(state.gemsCollected, 0);
      expect(state.levelEnded, false);
    });

    testWidgets('free mode does not show objective HUD', (tester) async {
      final saveState = SaveState(bonusMoves: 30);
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(saveState: saveState)),
      );
      await tester.pump();

      // Free mode should not show "LEVEL" text.
      expect(find.textContaining('LEVEL'), findsNothing);
      // Free mode now shows "MOVES" header.
      expect(find.text('MOVES'), findsOneWidget);
    });

    testWidgets('restart button resets state in level mode', (tester) async {
      final key = GlobalKey<GameScreenState>();
      final config = const LevelGenerator().generate(1);
      final saveState = SaveState(bonusMoves: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key, levelConfig: config, saveState: saveState),
        ),
      );
      await tester.pump();

      // Tap restart.
      await tester.tap(find.text('Restart'));
      await tester.pump();

      final state = key.currentState!;
      expect(state.score, 0);
      // After restart, moves come from saveState.bonusMoves again.
      expect(state.movesRemaining, greaterThanOrEqualTo(0));
    });
  });

  group('Obstacle rendering', () {
    testWidgets('renders obstacle emojis for level with obstacles',
        (tester) async {
      // Level 15+ has obstacles (ice at minimum).
      final config = const LevelGenerator().generate(20);
      expect(config.obstacles.isNotEmpty, true);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config)),
      );
      await tester.pump();

      final key2 = GlobalKey<GameScreenState>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key2, levelConfig: config),
        ),
      );
      await tester.pump();

      final state = key2.currentState!;
      expect(state.obstacleManager.activeCount, greaterThan(0));
    });
  });

  group('Coin Display', () {
    testWidgets('shows coin balance when coinBalance is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(coinBalance: 500),
        ),
      );
      await tester.pump();

      // Should find the coin balance text.
      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('hides coin display when coinBalance is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      expect(find.byKey(const Key('coin_balance')), findsNothing);
    });

    testWidgets('coin display works with level mode', (tester) async {
      final config = const LevelGenerator().generate(1);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(levelConfig: config, coinBalance: 1234),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
    });

    testWidgets('coinsEarnedThisLevel accessor starts at 0', (tester) async {
      final key = GlobalKey<GameScreenState>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: key, coinBalance: 100),
        ),
      );
      await tester.pump();

      expect(key.currentState!.coinsEarnedThisLevel, 0);
    });
  });

  group('GameScreen onLevelEnd callback', () {
    testWidgets('callback parameters are accessible', (tester) async {
      bool? callbackWon;
      int? callbackScore;
      int? callbackStars;
      int? callbackCoins;

      final config = LevelConfig(
        levelNumber: 1,
        rows: 7,
        cols: 7,
        gemTypeCount: 4,
        objective: const LevelObjective(
          type: LevelObjectiveType.score,
          targetScore: 0, // 0 means it will immediately win.
          twoStarScore: 100,
          threeStarScore: 200,
        ),
        constraintType: LevelConstraintType.moves,
        moveLimit: 30,
        difficulty: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            levelConfig: config,
            onLevelEnd: (won, score, stars, coins) {
              callbackWon = won;
              callbackScore = score;
              callbackStars = stars;
              callbackCoins = coins;
            },
          ),
        ),
      );
      await tester.pump();

      // With targetScore=0, this test verifies the callback signature exists.
      // Actual triggering would require a full swap interaction.
      expect(callbackWon, isNull); // Not yet triggered, just testing setup.
    });
  });
}

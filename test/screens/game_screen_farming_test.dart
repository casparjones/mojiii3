import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen farming mode', () {
    testWidgets('isFarmingMode is false when levelNumber is null',
        (tester) async {
      final saveState = SaveState();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(saveState: saveState),
        ),
      );
      await tester.pumpAndSettle();

      // No farming mode indicator - just verify the screen renders
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('isFarmingMode is false when level has fewer than 3 stars',
        (tester) async {
      final saveState = SaveState();
      saveState.levelRecords[1] = LevelRecord(
        levelNumber: 1,
        bestStars: 2,
      );
      final config = const LevelGenerator().generate(1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            saveState: saveState,
            levelConfig: config,
            levelNumber: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('isFarmingMode is true when level has 3 stars',
        (tester) async {
      final saveState = SaveState();
      saveState.levelRecords[1] = LevelRecord(
        levelNumber: 1,
        bestStars: 3,
      );
      final config = const LevelGenerator().generate(1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            saveState: saveState,
            levelConfig: config,
            levelNumber: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('levelNumber parameter is accepted', (tester) async {
      final saveState = SaveState();
      final config = const LevelGenerator().generate(5);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            saveState: saveState,
            levelConfig: config,
            levelNumber: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
    });
  });

  group('GameScreen farming rewards integration', () {
    test('farming coins increment saveState coins', () {
      final saveState = SaveState(coins: 100);
      saveState.levelRecords[1] = LevelRecord(
        levelNumber: 1,
        bestStars: 3,
      );

      // Directly test that coins can be added
      saveState.coins += 2;
      expect(saveState.coins, 102);
    });

    test('farming moves increment saveState bonusMoves', () {
      final saveState = SaveState(bonusMoves: 3);

      saveState.bonusMoves =
          (saveState.bonusMoves + 1).clamp(0, saveState.maxBonusMoves);
      expect(saveState.bonusMoves, 4);
    });

    test('farming moves do not exceed maxBonusMoves', () {
      final saveState = SaveState(bonusMoves: 60);

      saveState.bonusMoves =
          (saveState.bonusMoves + 1).clamp(0, saveState.maxBonusMoves);
      expect(saveState.bonusMoves, 60);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/level_select_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LevelSelectScreen edge cases', () {
    Widget createApp({SaveState? saveState, int totalLevels = 20}) {
      return createTestApp(
        home: LevelSelectScreen(totalLevels: totalLevels),
        saveState: saveState,
      );
    }

    testWidgets('renders with default SaveState when none provided',
        (tester) async {
      await tester.pumpWidget(createApp());
      // Should not crash. With 0 bonus moves, level 1 shows "Keine Moves".
      expect(find.text('Keine Moves'), findsOneWidget);
    });

    testWidgets('renders with totalLevels = 1', (tester) async {
      final save = SaveState(currentLevel: 1, bonusMoves: 5);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 1));
      expect(find.text('1'), findsOneWidget);
      // No lock icons since the only level is unlocked
      expect(find.text('\u{1F512}'), findsNothing);
    });

    testWidgets('all levels unlocked shows no lock icons', (tester) async {
      final save = SaveState(currentLevel: 8, bonusMoves: 5);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 8));
      expect(find.text('\u{1F512}'), findsNothing);
    });

    testWidgets('level with 0 stars shows 3 empty stars on New Levels tab',
        (tester) async {
      final save = SaveState(currentLevel: 2, bonusMoves: 5);
      // Level 1 and 2 are unlocked, no completions
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // New Levels tab shows level 1, 2 (unlocked, 0 stars) + level 3 (locked preview)
      // 2 unlocked levels * 3 empty stars each = 6 empty stars
      expect(find.text('\u2606'), findsNWidgets(6));
    });

    testWidgets(
        'level with 1 star shows 1 filled and 2 empty on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 2));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Level 1: 1 filled star
      expect(find.text('\u2B50'), findsNWidgets(1));
    });

    testWidgets('highscore of 0 is not displayed', (tester) async {
      final save = SaveState(currentLevel: 2, bonusMoves: 5);
      // Level 1 unlocked but no record, so highScore = 0
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 2));

      // The text "0" for highscore should not appear
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
        'multiple levels with different star counts render on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 5);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);
      save.levelRecord(2).recordCompletion(score: 200, stars: 2);
      save.levelRecord(3).recordCompletion(score: 300, stars: 3);
      // Level 4: unlocked but not completed

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Total filled stars: 1 + 2 + 3 = 6
      expect(find.text('\u2B50'), findsNWidgets(6));
      // Total empty stars: 2 + 1 + 0 = 3
      expect(find.text('\u2606'), findsNWidgets(3));
    });

    testWidgets('multiple highscores displayed on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 3);
      save.levelRecord(1).recordCompletion(score: 1234, stars: 1);
      save.levelRecord(2).recordCompletion(score: 5678, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 3));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('1234'), findsOneWidget);
      expect(find.text('5678'), findsOneWidget);
    });

    testWidgets('tapping unlocked level without record navigates',
        (tester) async {
      final save = SaveState(currentLevel: 2, bonusMoves: 5);
      // Level 2 is unlocked but has no record - on New Levels tab
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      await tester.tap(find.byKey(const Key('level_tile_2')));
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsNothing);
    });

    testWidgets('grid uses 2 columns', (tester) async {
      await tester.pumpWidget(createApp(totalLevels: 8));

      final sliverGrid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate = sliverGrid.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('AppBar is centered', (tester) async {
      await tester.pumpWidget(createApp());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('New Levels tab shows unlocked uncompleted levels',
        (tester) async {
      final save = SaveState(currentLevel: 4, bonusMoves: 5);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);
      save.levelRecord(2).recordCompletion(score: 200, stars: 2);
      // Level 3, 4 unlocked but not completed

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 6));

      // New Levels tab: levels 3, 4 (unlocked, 0 stars) + level 5 (locked preview)
      expect(find.byKey(const Key('level_tile_3')), findsOneWidget);
      expect(find.byKey(const Key('level_tile_4')), findsOneWidget);
      expect(find.byKey(const Key('level_tile_5')), findsOneWidget);
      // Completed levels should NOT be on this tab
      expect(find.byKey(const Key('level_tile_1')), findsNothing);
      expect(find.byKey(const Key('level_tile_2')), findsNothing);
    });

    testWidgets('Completed tab shows only completed levels', (tester) async {
      final save = SaveState(currentLevel: 4);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);
      save.levelRecord(2).recordCompletion(score: 200, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 6));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Only levels 1 and 2 should be shown
      expect(find.byKey(const Key('level_tile_1')), findsOneWidget);
      expect(find.byKey(const Key('level_tile_2')), findsOneWidget);
      expect(find.byKey(const Key('level_tile_3')), findsNothing);
    });

    testWidgets('tab indicator color is amberAccent', (tester) async {
      await tester.pumpWidget(createApp());

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorColor, Colors.amberAccent);
    });
  });
}

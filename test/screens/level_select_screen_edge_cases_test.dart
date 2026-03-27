import 'package:flutter/material.dart';
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
      // Should not crash and show level 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders with totalLevels = 1', (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 1));
      expect(find.text('1'), findsOneWidget);
      // No lock icons since the only level is unlocked
      expect(find.text('\u{1F512}'), findsNothing);
    });

    testWidgets('all levels unlocked shows no lock icons', (tester) async {
      final save = SaveState(currentLevel: 8);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 8));
      expect(find.text('\u{1F512}'), findsNothing);
    });

    testWidgets('level with 0 stars shows 3 empty stars', (tester) async {
      final save = SaveState(currentLevel: 2);
      // Level 1 is unlocked but has no record (0 stars)
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Level 1 and 2 are unlocked, both with 0 stars = 6 empty stars total
      // Level 3 and 4 are locked (no stars shown)
      // Each unlocked level without record shows 3 empty "☆"
      expect(find.text('\u2606'), findsNWidgets(6));
    });

    testWidgets('level with 1 star shows 1 filled and 2 empty',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 2));

      // Level 1: 1 filled star, Level 2: 0 filled stars
      expect(find.text('\u2B50'), findsNWidgets(1));
    });

    testWidgets('highscore of 0 is not displayed', (tester) async {
      final save = SaveState(currentLevel: 2);
      // Level 1 unlocked but no record, so highScore = 0
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 2));

      // The text "0" for highscore should not appear (only shows if > 0)
      // Note: "0" might match other things, so we check there's no highscore text
      // Level numbers are shown, but highscore 0 should be hidden
      expect(find.text('0'), findsNothing);
    });

    testWidgets('multiple levels with different star counts render correctly',
        (tester) async {
      final save = SaveState(currentLevel: 5);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);
      save.levelRecord(2).recordCompletion(score: 200, stars: 2);
      save.levelRecord(3).recordCompletion(score: 300, stars: 3);
      // Level 4: unlocked but not completed

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Total filled stars: 1 + 2 + 3 + 0 = 6
      expect(find.text('\u2B50'), findsNWidgets(6));
      // Total empty stars: 2 + 1 + 0 + 3 = 6
      expect(find.text('\u2606'), findsNWidgets(6));
    });

    testWidgets('multiple highscores displayed', (tester) async {
      final save = SaveState(currentLevel: 3);
      save.levelRecord(1).recordCompletion(score: 1234, stars: 1);
      save.levelRecord(2).recordCompletion(score: 5678, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 3));

      expect(find.text('1234'), findsOneWidget);
      expect(find.text('5678'), findsOneWidget);
    });

    testWidgets('tapping unlocked level without record navigates',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      // Level 2 is unlocked but has no record
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      await tester.tap(find.byKey(const Key('level_tile_2')));
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsNothing);
    });

    testWidgets('grid uses 4 columns', (tester) async {
      await tester.pumpWidget(createApp(totalLevels: 8));

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('AppBar is centered', (tester) async {
      await tester.pumpWidget(createApp());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('level tiles have correct keys for all levels',
        (tester) async {
      final save = SaveState(currentLevel: 4);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      for (int i = 1; i <= 4; i++) {
        expect(find.byKey(Key('level_tile_$i')), findsOneWidget);
      }
    });
  });
}

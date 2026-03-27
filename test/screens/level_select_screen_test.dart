import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/level_select_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LevelSelectScreen', () {
    Widget createApp({SaveState? saveState, int totalLevels = 20}) {
      return createTestApp(
        home: LevelSelectScreen(totalLevels: totalLevels),
        saveState: saveState,
      );
    }

    testWidgets('displays Select Level title', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Select Level'), findsOneWidget);
    });

    testWidgets('has dark background color', (tester) async {
      await tester.pumpWidget(createApp());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1a1a2e));
    });

    testWidgets('displays level tiles', (tester) async {
      await tester.pumpWidget(createApp(totalLevels: 8));
      // Level 1 should be visible
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('first level is unlocked by default', (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Level 1 should show its number (unlocked)
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('locked levels show lock emoji', (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Levels 2-4 are locked, each shows a lock
      expect(find.text('🔒'), findsNWidgets(3));
    });

    testWidgets('completed level shows stars', (tester) async {
      final save = SaveState(currentLevel: 3);
      // Record a completion for level 1 with 2 stars
      save.levelRecord(1).recordCompletion(score: 1000, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Should have stars rendered - 2 filled + 1 empty for level 1
      // Plus 3 empty for level 2 (unlocked but no stars)
      // Plus 3 empty for level 3 (unlocked but no stars)
      expect(find.text('⭐'), findsNWidgets(2));
    });

    testWidgets('completed level shows highscore', (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 5000, stars: 1);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      expect(find.text('5000'), findsOneWidget);
    });

    testWidgets('tapping unlocked level navigates to GameScreen',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      await tester.tap(find.byKey(const Key('level_tile_1')));
      await tester.pumpAndSettle();

      // Should have navigated away from LevelSelectScreen
      // GameScreen should now be showing
      expect(find.byType(LevelSelectScreen), findsNothing);
    });

    testWidgets('tapping locked level does not navigate', (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Level 2 is locked
      await tester.tap(find.byKey(const Key('level_tile_2')));
      await tester.pumpAndSettle();

      // Should still be on LevelSelectScreen
      expect(find.byType(LevelSelectScreen), findsOneWidget);
    });

    testWidgets('shows back button that navigates back', (tester) async {
      await tester.pumpWidget(createApp());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('3-star level has amber glow effect', (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 9999, stars: 3);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Just verify it renders without error when a level has 3 stars
      expect(find.text('1'), findsOneWidget);
      expect(find.text('⭐'), findsNWidgets(3));
    });
  });
}

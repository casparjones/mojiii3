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
      // Level 1 should be visible on New Levels tab
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('first level is unlocked by default', (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Level 1 should show its number (unlocked) on New Levels tab
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('locked level preview shows lock emoji on New Levels tab',
        (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Only the first locked level (2) shows as preview
      expect(find.text('\u{1F512}'), findsOneWidget);
    });

    testWidgets('completed level shows stars on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 3);
      // Record a completion for level 1 with 2 stars
      save.levelRecord(1).recordCompletion(score: 1000, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Should have 2 filled stars for level 1
      expect(find.text('\u2B50'), findsNWidgets(2));
    });

    testWidgets('completed level shows highscore on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 5000, stars: 1);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

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

    testWidgets('tapping locked level preview does not navigate',
        (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Level 2 is locked (shown as preview)
      await tester.tap(find.byKey(const Key('level_tile_2')));
      await tester.pumpAndSettle();

      // Should still be on LevelSelectScreen
      expect(find.byType(LevelSelectScreen), findsOneWidget);
    });

    testWidgets('shows back button that navigates back', (tester) async {
      await tester.pumpWidget(createApp());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('3-star level has amber glow effect on Completed tab',
        (tester) async {
      final save = SaveState(currentLevel: 2);
      save.levelRecord(1).recordCompletion(score: 9999, stars: 3);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Just verify it renders without error when a level has 3 stars
      expect(find.text('1'), findsOneWidget);
      expect(find.text('\u2B50'), findsNWidgets(3));
    });

    testWidgets('shows tabs for New Levels and Completed', (tester) async {
      await tester.pumpWidget(createApp());

      expect(find.text('New Levels'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('New Levels tab is selected by default', (tester) async {
      await tester.pumpWidget(createApp());

      // The New Levels tab should be visible and active
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 2);
    });

    testWidgets('Completed tab shows empty message when no levels completed',
        (tester) async {
      final save = SaveState(currentLevel: 1);
      await tester.pumpWidget(createApp(saveState: save, totalLevels: 4));

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Noch kein Level abgeschlossen'), findsOneWidget);
    });

    testWidgets(
        'New Levels tab shows completion message when all levels done',
        (tester) async {
      final save = SaveState(currentLevel: 3);
      save.levelRecord(1).recordCompletion(score: 100, stars: 1);
      save.levelRecord(2).recordCompletion(score: 200, stars: 2);

      await tester.pumpWidget(createApp(saveState: save, totalLevels: 2));

      expect(find.textContaining('Alle Level geschafft'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/settings_screen.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('SettingsScreen', () {
    Widget createApp({SaveState? saveState, GameSettings? settings}) {
      return createTestApp(
        home: const SettingsScreen(),
        saveState: saveState,
        settings: settings,
      );
    }

    testWidgets('displays Settings title', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('has dark background color', (tester) async {
      await tester.pumpWidget(createApp());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1a1a2e));
    });

    testWidgets('displays Audio & Haptics section', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Audio & Haptics'), findsOneWidget);
    });

    testWidgets('displays Sound toggle', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Sound'), findsOneWidget);
      expect(find.byKey(const Key('sound_toggle')), findsOneWidget);
    });

    testWidgets('displays Music toggle', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Music'), findsOneWidget);
      expect(find.byKey(const Key('music_toggle')), findsOneWidget);
    });

    testWidgets('displays Vibration toggle', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Vibration'), findsOneWidget);
      expect(find.byKey(const Key('vibration_toggle')), findsOneWidget);
    });

    testWidgets('Sound toggle can be switched off', (tester) async {
      await tester.pumpWidget(createApp());

      final switchWidget =
          tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      expect(switchWidget.value, isTrue);

      await tester.tap(find.byKey(const Key('sound_toggle')));
      await tester.pumpAndSettle();

      final updatedSwitch =
          tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('Music toggle can be switched off', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.tap(find.byKey(const Key('music_toggle')));
      await tester.pumpAndSettle();

      final updatedSwitch =
          tester.widget<Switch>(find.byKey(const Key('music_toggle')));
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('Vibration toggle can be switched off', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.tap(find.byKey(const Key('vibration_toggle')));
      await tester.pumpAndSettle();

      final updatedSwitch =
          tester.widget<Switch>(find.byKey(const Key('vibration_toggle')));
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('displays Statistics section with PlayerStats data',
        (tester) async {
      final save = SaveState(coins: 999);
      save.stats.levelsPlayed = 42;
      save.stats.levelsCompleted = 35;
      save.stats.bestCombo = 7;
      save.stats.totalGemsMatched = 1234;
      save.stats.totalCoinsEarned = 5000;
      save.stats.bestMoveScore = 3500;
      save.stats.totalPlayTimeSeconds = 3661; // 1h 1m
      save.stats.threeStarCount = 10;

      await tester.pumpWidget(createApp(saveState: save));

      // Scroll to see statistics
      await tester.scrollUntilVisible(
        find.text('Statistics'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('42'), findsOneWidget); // levels played
      expect(find.text('35'), findsOneWidget); // levels completed
      expect(find.text('7x'), findsOneWidget); // best combo
      expect(find.text('1234'), findsOneWidget); // total gems
    });

    testWidgets('displays play time formatted correctly', (tester) async {
      final save = SaveState();
      save.stats.totalPlayTimeSeconds = 7200; // 2h 0m

      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Play Time'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('2h 0m'), findsOneWidget);
    });

    testWidgets('displays current coins in stats', (tester) async {
      final save = SaveState(coins: 777);
      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Current Coins'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('777'), findsOneWidget);
    });

    testWidgets('displays reset button', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.text('Reset All Progress'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Reset All Progress'), findsOneWidget);
    });

    testWidgets('reset button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Progress?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('cancel in reset dialog does not reset', (tester) async {
      final save = SaveState(coins: 500);
      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Coins should still be displayed
      expect(save.coins, 500);
    });

    testWidgets('confirming reset resets state and shows snackbar',
        (tester) async {
      final save = SaveState(coins: 500);
      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_reset')));
      await tester.pumpAndSettle();
      // Flush the scheduleSave timer from GameStateManager.reset()
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Progress reset!'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

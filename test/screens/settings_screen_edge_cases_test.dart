import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/settings_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('SettingsScreen edge cases', () {
    Widget createApp({SaveState? saveState}) {
      return createTestApp(
        home: const SettingsScreen(),
        saveState: saveState,
      );
    }

    testWidgets('renders with default SaveState when none provided',
        (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('all toggles start enabled by default', (tester) async {
      await tester.pumpWidget(createApp());

      final soundSwitch =
          tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      final musicSwitch =
          tester.widget<Switch>(find.byKey(const Key('music_toggle')));
      final vibrationSwitch =
          tester.widget<Switch>(find.byKey(const Key('vibration_toggle')));

      expect(soundSwitch.value, isTrue);
      expect(musicSwitch.value, isTrue);
      expect(vibrationSwitch.value, isTrue);
    });

    testWidgets('toggling off and on again works', (tester) async {
      await tester.pumpWidget(createApp());

      // Toggle sound off
      await tester.tap(find.byKey(const Key('sound_toggle')));
      await tester.pumpAndSettle();
      var s = tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      expect(s.value, isFalse);

      // Toggle sound back on
      await tester.tap(find.byKey(const Key('sound_toggle')));
      await tester.pumpAndSettle();
      s = tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      expect(s.value, isTrue);
    });

    testWidgets('all toggles can be toggled independently', (tester) async {
      await tester.pumpWidget(createApp());

      // Toggle only vibration off
      await tester.tap(find.byKey(const Key('vibration_toggle')));
      await tester.pumpAndSettle();

      final soundSwitch =
          tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      final musicSwitch =
          tester.widget<Switch>(find.byKey(const Key('music_toggle')));
      final vibrationSwitch =
          tester.widget<Switch>(find.byKey(const Key('vibration_toggle')));

      expect(soundSwitch.value, isTrue);
      expect(musicSwitch.value, isTrue);
      expect(vibrationSwitch.value, isFalse);
    });

    testWidgets('stats show zero values for fresh save', (tester) async {
      final save = SaveState();
      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Play Time'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      // Fresh save: 0 levels played, 0x combo, 0m play time
      expect(find.text('0m'), findsOneWidget);
      expect(find.text('0x'), findsOneWidget);
    });

    testWidgets('play time shows minutes only when under 1 hour',
        (tester) async {
      final save = SaveState();
      save.stats.totalPlayTimeSeconds = 1800; // 30m

      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Play Time'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('play time shows hours and minutes when over 1 hour',
        (tester) async {
      final save = SaveState();
      save.stats.totalPlayTimeSeconds = 5400; // 1h 30m

      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Play Time'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('total stars from level records are displayed',
        (tester) async {
      final save = SaveState(currentLevel: 3);
      save.levelRecord(1).recordCompletion(score: 100, stars: 2);
      save.levelRecord(2).recordCompletion(score: 200, stars: 3);

      await tester.pumpWidget(createApp(saveState: save));

      await tester.scrollUntilVisible(
        find.text('Total Stars'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      // Total stars: 2 + 3 = 5
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('danger zone section is present', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.text('Danger Zone'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Danger Zone'), findsOneWidget);
    });

    testWidgets('reset dialog warns about irreversible action',
        (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });

    testWidgets('confirming reset shows snackbar', (tester) async {
      await tester.pumpWidget(createApp());

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

    testWidgets('section headers have correct icons', (tester) async {
      await tester.pumpWidget(createApp());

      // Audio section has volume, music, vibration icons
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byIcon(Icons.vibration), findsOneWidget);
    });

    testWidgets('reset button has delete icon', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('AppBar is centered', (tester) async {
      await tester.pumpWidget(createApp());
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });
  });
}

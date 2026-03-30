import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/main_menu_screen.dart';
import 'package:match3/screens/level_select_screen.dart';
import 'package:match3/screens/shop_screen.dart';
import 'package:match3/screens/settings_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('MainMenuScreen edge cases', () {
    Widget createApp() {
      return createTestApp(home: const MainMenuScreen());
    }

    testWidgets('all three navigation buttons have keys', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.byKey(const Key('play_button')), findsOneWidget);
      expect(find.byKey(const Key('shop_button')), findsOneWidget);
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    testWidgets('all three buttons have correct icons', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.store_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('logo text has correct styling', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Mojiii3'));
      final style = textWidget.style!;
      expect(style.fontSize, 48);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, Colors.white);
    });

    testWidgets('uses SafeArea for content', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('navigating to LevelSelect and back returns to menu',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      // Navigate to LevelSelect
      await tester.tap(find.byKey(const Key('play_button')));
      // Use pump with duration since MainMenuScreen has repeating animations
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LevelSelectScreen), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('navigating to Shop and back returns to menu',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('shop_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ShopScreen), findsOneWidget);

      // Navigate back
      final arrowBack = find.byIcon(Icons.arrow_back);
      if (arrowBack.evaluate().isNotEmpty) {
        await tester.tap(arrowBack.first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('navigating to Settings and back returns to menu',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SettingsScreen), findsOneWidget);

      final arrowBack = find.byIcon(Icons.arrow_back);
      if (arrowBack.evaluate().isNotEmpty) {
        await tester.tap(arrowBack.first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('floating emojis are from the correct emoji set',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final emojiSet = {'🍎', '🫐', '🍋', '🍊', '🍇', '🍓'};

      // Find all Opacity widgets (floating emojis use Opacity)
      final opacityFinder = find.byType(Opacity);
      final opacityWidgets = opacityFinder.evaluate();

      for (final element in opacityWidgets) {
        final opacityWidget = element.widget as Opacity;
        // Each floating emoji should have an Opacity child containing a Text widget
        if (opacityWidget.child is Text) {
          final text = opacityWidget.child as Text;
          if (text.data != null) {
            expect(emojiSet.contains(text.data), isTrue,
                reason: 'Unexpected emoji: ${text.data}');
          }
        }
      }
    });

    testWidgets('floating emojis have opacity between 0 and 1',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final opacityFinder = find.byType(Opacity);
      final opacityWidgets = opacityFinder.evaluate();

      for (final element in opacityWidgets) {
        final opacityWidget = element.widget as Opacity;
        expect(opacityWidget.opacity, greaterThanOrEqualTo(0.0));
        expect(opacityWidget.opacity, lessThanOrEqualTo(1.0));
      }
    });

    testWidgets('exactly 15 floating emojis are rendered', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder.evaluate().length, 15);
    });

    testWidgets('animation controllers are properly disposed',
        (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      // Navigate away, which should dispose the screen
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // If dispose was not called properly, this would throw
      // The test passing means dispose worked correctly
    });

    testWidgets('uses Stack to layer background and content', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.byType(Stack), findsAtLeast(1));
    });
  });
}

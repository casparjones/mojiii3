import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/main_menu_screen.dart';
import 'package:match3/screens/level_select_screen.dart';
import 'package:match3/screens/shop_screen.dart';
import 'package:match3/screens/settings_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('MainMenuScreen', () {
    Widget createApp() {
      return createTestApp(home: const MainMenuScreen());
    }

    testWidgets('displays Match3 logo text', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('Match3'), findsOneWidget);
    });

    testWidgets('displays Play button', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('displays Shop button', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('displays Settings button', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays an animated emoji in logo area', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      // At least one of the fruit emojis should be visible in the logo
      final emojiSet = ['🍎', '🫐', '🍋', '🍊', '🍇', '🍓'];
      bool foundEmoji = false;
      for (final emoji in emojiSet) {
        if (find.text(emoji).evaluate().isNotEmpty) {
          foundEmoji = true;
          break;
        }
      }
      expect(foundEmoji, isTrue);
    });

    testWidgets('has dark background color', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1a1a2e));
    });

    testWidgets('Play button navigates to LevelSelectScreen', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsOneWidget);
    });

    testWidgets('Shop button navigates to ShopScreen', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('shop_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('Settings button navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('renders floating background emojis', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      // There should be multiple Opacity widgets for the floating emojis
      // (at least 15 from the floating emojis + any in the logo)
      final opacityWidgets = find.byType(Opacity);
      expect(opacityWidgets.evaluate().length, greaterThanOrEqualTo(15));
    });

    testWidgets('displays coin balance on main menu', (tester) async {
      await tester.pumpWidget(createTestApp(
        home: const MainMenuScreen(),
        saveState: SaveState(coins: 1234),
      ));
      await tester.pump();

      expect(find.text('1234'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/main.dart';
import 'package:match3/screens/main_menu_screen.dart';
import 'package:match3/screens/settings_screen.dart';
import 'package:match3/screens/shop_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('GameStateManager Integration', () {
    testWidgets('GameStateManagerProvider.of returns the manager',
        (tester) async {
      final gsm = GameStateManager(saveState: SaveState(coins: 42));
      late GameStateManager found;

      await tester.pumpWidget(
        GameStateManagerProvider(
          gameStateManager: gsm,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                found = GameStateManagerProvider.of(context);
                return const Scaffold();
              },
            ),
          ),
        ),
      );

      expect(found, same(gsm));
      expect(found.coins, 42);
    });

    testWidgets('GameStateManagerProvider.read returns the manager',
        (tester) async {
      final gsm = GameStateManager(saveState: SaveState(coins: 99));
      late GameStateManager found;

      await tester.pumpWidget(
        GameStateManagerProvider(
          gameStateManager: gsm,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                found = GameStateManagerProvider.read(context);
                return const Scaffold();
              },
            ),
          ),
        ),
      );

      expect(found, same(gsm));
      expect(found.coins, 99);
    });

    testWidgets('MainMenuScreen displays coin balance from GameStateManager',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        home: const MainMenuScreen(),
        saveState: SaveState(coins: 555),
      ));
      await tester.pump();

      expect(find.text('555'), findsOneWidget);
    });

    testWidgets('ShopScreen reflects GameStateManager coin balance',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        home: const ShopScreen(),
        saveState: SaveState(coins: 888),
      ));

      expect(find.text('888'), findsOneWidget);
    });

    testWidgets('SettingsScreen reflects GameStateManager settings',
        (tester) async {
      final settings = GameSettings(soundEnabled: false);
      await tester.pumpWidget(createTestApp(
        home: const SettingsScreen(),
        settings: settings,
      ));

      final soundSwitch =
          tester.widget<Switch>(find.byKey(const Key('sound_toggle')));
      expect(soundSwitch.value, isFalse);
    });

    testWidgets('SettingsScreen toggle updates GameStateManager',
        (tester) async {
      final gsm = GameStateManager();
      await tester.pumpWidget(createTestApp(
        home: const SettingsScreen(),
        gameStateManager: gsm,
      ));

      expect(gsm.settings.soundEnabled, isTrue);

      await tester.tap(find.byKey(const Key('sound_toggle')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(gsm.settings.soundEnabled, isFalse);
    });

    testWidgets('Match3App creates and provides GameStateManager',
        (tester) async {
      final gsm = GameStateManager(saveState: SaveState(coins: 333));
      await tester.pumpWidget(Match3App(gameStateManager: gsm));
      await tester.pump();

      // Coins should be visible on main menu
      expect(find.text('333'), findsOneWidget);
    });

    testWidgets('ShopScreen purchase updates coins via GameStateManager',
        (tester) async {
      final gsm = GameStateManager(saveState: SaveState(coins: 600));
      await tester.pumpWidget(createTestApp(
        home: const ShopScreen(),
        gameStateManager: gsm,
      ));

      // Buy animal theme (200)
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(gsm.coins, 400);
      expect(find.text('400'), findsOneWidget);
    });

    testWidgets('SettingsScreen reset resets GameStateManager',
        (tester) async {
      final gsm = GameStateManager(saveState: SaveState(coins: 1000));
      await tester.pumpWidget(createTestApp(
        home: const SettingsScreen(),
        gameStateManager: gsm,
      ));

      await tester.scrollUntilVisible(
        find.byKey(const Key('reset_button')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('reset_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_reset')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(gsm.coins, 0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/shop_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ShopScreen edge cases', () {
    Widget createApp({SaveState? saveState}) {
      return createTestApp(
        home: const ShopScreen(),
        saveState: saveState,
      );
    }

    testWidgets('renders with default SaveState when none provided',
        (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // default coins = 0
    });

    testWidgets('coin balance shows 0 for fresh save', (tester) async {
      final save = SaveState();
      await tester.pumpWidget(createApp(saveState: save));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('cancel in purchase dialog does not deduct coins',
        (tester) async {
      final save = SaveState(coins: 1000);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button via its shop item key
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      // Find the price text within the animal card area
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Coins unchanged
      expect(save.coins, 1000);
    });

    testWidgets('buying with exact coins succeeds', (tester) async {
      final save = SaveState(coins: 200);
      await tester.pumpWidget(createApp(saveState: save));

      // Buy animal theme (exactly 200)
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 0);
      expect(save.isExtraUnlocked('theme_animals'), isTrue);
    });

    testWidgets('successful purchase updates state', (tester) async {
      final save = SaveState(coins: 600);
      await tester.pumpWidget(createApp(saveState: save));

      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();

      expect(save.coins, 400);
      expect(save.isExtraUnlocked('theme_animals'), isTrue);
    });

    testWidgets('failed purchase keeps coins unchanged', (tester) async {
      final save = SaveState(coins: 10);
      await tester.pumpWidget(createApp(saveState: save));

      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();

      expect(save.coins, 10);
      expect(save.isExtraUnlocked('theme_animals'), isFalse);
    });

    testWidgets('multiple items can be purchased sequentially',
        (tester) async {
      final save = SaveState(coins: 2000);
      await tester.pumpWidget(createApp(saveState: save));

      // Buy animal theme (200) using descendant finder
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 1800);

      // Buy space theme (200) using descendant finder to avoid ambiguity
      final spaceCard = find.byKey(const Key('shop_item_theme_space'));
      await tester.tap(find.descendant(
        of: spaceCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 1600);
      expect(save.isExtraUnlocked('theme_animals'), isTrue);
      expect(save.isExtraUnlocked('theme_space'), isTrue);
    });

    testWidgets('owned items do not show buy button', (tester) async {
      final save = SaveState(coins: 1000);
      save.unlockExtra('theme_animals');
      // theme_fruit is always owned by default
      await tester.pumpWidget(createApp(saveState: save));

      // Fruit is the active theme -> shows "Active ✓"
      final fruitCard = find.byKey(const Key('shop_item_theme_fruit'));
      expect(
        find.descendant(of: fruitCard, matching: find.text('Active \u2713')),
        findsOneWidget,
      );
      // Animal is owned but not active -> shows "Use"
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      expect(
        find.descendant(of: animalCard, matching: find.text('Use')),
        findsOneWidget,
      );
      // Neither should show a price button
      expect(
        find.descendant(of: fruitCard, matching: find.text('200')),
        findsNothing,
      );
      expect(
        find.descendant(of: animalCard, matching: find.text('200')),
        findsNothing,
      );
    });

    testWidgets('shop items have correct keys', (tester) async {
      await tester.pumpWidget(createApp());

      expect(
          find.byKey(const Key('shop_item_theme_fruit')), findsOneWidget);
      expect(
          find.byKey(const Key('shop_item_theme_animals')), findsOneWidget);
      expect(
          find.byKey(const Key('shop_item_theme_space')), findsOneWidget);
    });

    testWidgets('power-up items have correct keys', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.byKey(const Key('shop_item_powerup_color_bomb')),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.byKey(const Key('shop_item_powerup_extra_moves')),
          findsOneWidget);
      expect(
          find.byKey(const Key('shop_item_powerup_shuffle')), findsOneWidget);
      expect(find.byKey(const Key('shop_item_powerup_color_bomb')),
          findsOneWidget);
    });

    testWidgets('coin balance display has coin_balance key', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
    });

    testWidgets('AppBar is centered', (tester) async {
      await tester.pumpWidget(createApp());
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('shop items display descriptions', (tester) async {
      await tester.pumpWidget(createApp());

      expect(find.text('Classic fruit emojis'), findsOneWidget);
      expect(find.text('Cute animal emojis'), findsOneWidget);
      expect(find.text('Cosmic space emojis'), findsOneWidget);
    });

    testWidgets('power-up items display descriptions', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.scrollUntilVisible(
        find.text('Destroy all of one color'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('\uD83D\uDC8A +20 Zuege im Spiel aktivieren'), findsOneWidget);
      expect(find.text('\uD83D\uDC8A +60 Zuege im Spiel aktivieren'), findsOneWidget);
      expect(find.text('Shuffle the board'), findsOneWidget);
      expect(find.text('Destroy all of one color'), findsOneWidget);
    });
  });
}

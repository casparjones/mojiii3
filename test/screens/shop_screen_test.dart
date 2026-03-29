import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/screens/shop_screen.dart';
import 'package:match3/game/save_system.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ShopScreen', () {
    Widget createApp({SaveState? saveState}) {
      return createTestApp(
        home: const ShopScreen(),
        saveState: saveState,
      );
    }

    testWidgets('displays Shop title', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('has dark background color', (tester) async {
      await tester.pumpWidget(createApp());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1a1a2e));
    });

    testWidgets('displays coin balance', (tester) async {
      final save = SaveState(coins: 750);
      await tester.pumpWidget(createApp(saveState: save));

      expect(find.text('750'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
    });

    testWidgets('displays theme section', (tester) async {
      await tester.pumpWidget(createApp());

      expect(find.text('Emoji Themes'), findsOneWidget);
      expect(find.text('Fruit Theme'), findsOneWidget);
      expect(find.text('Animal Theme'), findsOneWidget);
      expect(find.text('Space Theme'), findsOneWidget);
    });

    testWidgets('displays power-up section', (tester) async {
      await tester.pumpWidget(createApp());

      // Scroll down to see power-ups
      await tester.scrollUntilVisible(
        find.text('Power-Ups'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Power-Ups'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Shuffle'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Extra Moves (20)'), findsOneWidget);
      expect(find.text('Mega Moves (60)'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Color Bomb'), findsOneWidget);
    });

    testWidgets('fruit theme shows Active since it is the default theme', (tester) async {
      await tester.pumpWidget(createApp());
      // Fruit theme is always owned and active by default
      expect(find.text('Active \u2713'), findsOneWidget);
    });

    testWidgets('animal theme shows price 200', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('200'), findsWidgets);
    });

    testWidgets('space theme shows price 200', (tester) async {
      await tester.pumpWidget(createApp());
      final spaceCard = find.byKey(const Key('shop_item_theme_space'));
      expect(
        find.descendant(of: spaceCard, matching: find.text('200')),
        findsOneWidget,
      );
    });

    testWidgets('tapping paid item shows confirmation dialog', (tester) async {
      final save = SaveState(coins: 1000);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button (200 coins)
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Buy Animal Theme?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);
    });

    testWidgets('confirming purchase deducts coins and shows Use',
        (tester) async {
      final save = SaveState(coins: 600);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      // Confirm purchase
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      // Flush the scheduleSave timer
      await tester.pump(const Duration(seconds: 1));

      // Coins should be deducted
      expect(find.text('400'), findsOneWidget); // 600 - 200
      // Purchased theme is owned but not active, so it shows "Use"
      expect(find.text('Use'), findsOneWidget);
    });

    testWidgets('purchase fails with not enough coins', (tester) async {
      final save = SaveState(coins: 100);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button (costs 200, only have 100)
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('200'),
      ));
      await tester.pumpAndSettle();

      // Confirm purchase
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();

      // Coins unchanged (purchase failed)
      expect(save.coins, 100);
      expect(save.isExtraUnlocked('theme_animals'), isFalse);
    });

    testWidgets('fruit theme is always owned by default', (tester) async {
      final save = SaveState();
      await tester.pumpWidget(createApp(saveState: save));

      // Fruit theme is always treated as owned and is the default active theme
      // so it shows "Active ✓" rather than "Free"
      final fruitCard = find.byKey(const Key('shop_item_theme_fruit'));
      expect(
        find.descendant(of: fruitCard, matching: find.text('Active \u2713')),
        findsOneWidget,
      );
    });

    testWidgets('already owned non-active theme shows Use button', (tester) async {
      final save = SaveState(coins: 1000);
      save.unlockExtra('theme_animals');
      await tester.pumpWidget(createApp(saveState: save));

      // Animal theme is owned but not the active theme, so it shows "Use"
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      expect(
        find.descendant(of: animalCard, matching: find.text('Use')),
        findsOneWidget,
      );
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

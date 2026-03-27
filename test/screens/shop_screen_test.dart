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
      expect(find.text('Extra Moves'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Color Bomb'), findsOneWidget);
    });

    testWidgets('fruit theme shows Free button', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('animal theme shows price 500', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('space theme shows price 1000', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('tapping paid item shows confirmation dialog', (tester) async {
      final save = SaveState(coins: 1000);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button (500 coins)
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      expect(find.text('Buy Animal Theme?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Buy'), findsOneWidget);
    });

    testWidgets('confirming purchase deducts coins and shows Owned',
        (tester) async {
      final save = SaveState(coins: 600);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      // Confirm purchase
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      // Flush the scheduleSave timer
      await tester.pump(const Duration(seconds: 1));

      // Coins should be deducted
      expect(find.text('100'), findsOneWidget); // 600 - 500
      // Item should show Owned
      expect(find.text('Owned'), findsOneWidget);
    });

    testWidgets('purchase fails with not enough coins', (tester) async {
      final save = SaveState(coins: 100);
      await tester.pumpWidget(createApp(saveState: save));

      // Tap animal theme buy button (costs 500, only have 100)
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      // Confirm purchase
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Not enough coins!'), findsOneWidget);
      // Coins unchanged
      expect(save.coins, 100);
    });

    testWidgets('free item can be claimed without dialog', (tester) async {
      final save = SaveState();
      await tester.pumpWidget(createApp(saveState: save));

      // Tap Free button for fruit theme
      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();

      // Should now show Owned (no dialog for free items)
      expect(find.text('Owned'), findsOneWidget);
      expect(save.isExtraUnlocked('theme_fruit'), isTrue);
    });

    testWidgets('already owned items show Owned label', (tester) async {
      final save = SaveState(coins: 1000);
      save.unlockExtra('theme_animals');
      await tester.pumpWidget(createApp(saveState: save));

      expect(find.text('Owned'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

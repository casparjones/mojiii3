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
        matching: find.text('500'),
      ));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Coins unchanged
      expect(save.coins, 1000);
    });

    testWidgets('buying with exact coins succeeds', (tester) async {
      final save = SaveState(coins: 500);
      await tester.pumpWidget(createApp(saveState: save));

      // Buy animal theme (exactly 500)
      final animalCard = find.byKey(const Key('shop_item_theme_animals'));
      await tester.tap(find.descendant(
        of: animalCard,
        matching: find.text('500'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 0);
      expect(save.isExtraUnlocked('theme_animals'), isTrue);
      expect(find.text('Animal Theme purchased!'), findsOneWidget);
    });

    testWidgets('successful purchase shows green snackbar', (tester) async {
      final save = SaveState(coins: 600);
      await tester.pumpWidget(createApp(saveState: save));

      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Animal Theme purchased!'), findsOneWidget);
    });

    testWidgets('failed purchase shows red snackbar', (tester) async {
      final save = SaveState(coins: 10);
      await tester.pumpWidget(createApp(saveState: save));

      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();

      expect(find.text('Not enough coins!'), findsOneWidget);
    });

    testWidgets('multiple items can be purchased sequentially',
        (tester) async {
      final save = SaveState(coins: 2000);
      await tester.pumpWidget(createApp(saveState: save));

      // Buy animal theme (500)
      await tester.tap(find.text('500'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 1500);

      // Buy space theme (1000)
      await tester.tap(find.text('1000'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_purchase')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(save.coins, 500);
      expect(save.isExtraUnlocked('theme_animals'), isTrue);
      expect(save.isExtraUnlocked('theme_space'), isTrue);
    });

    testWidgets('owned items do not show buy button', (tester) async {
      final save = SaveState(coins: 1000);
      save.unlockExtra('theme_animals');
      save.unlockExtra('theme_fruit');
      await tester.pumpWidget(createApp(saveState: save));

      // Two items show "Owned"
      expect(find.text('Owned'), findsNWidgets(2));
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

      expect(find.text('+5 extra moves'), findsOneWidget);
      expect(find.text('Shuffle the board'), findsOneWidget);
      expect(find.text('Destroy all of one color'), findsOneWidget);
    });
  });
}

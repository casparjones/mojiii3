import 'package:flutter_test/flutter_test.dart';

import 'package:match3/main.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';

void main() {
  testWidgets('Match3App smoke test - renders main menu', (tester) async {
    final gsm = GameStateManager(saveState: SaveState(coins: 0));
    await tester.pumpWidget(Match3App(gameStateManager: gsm));
    await tester.pump();

    // Verify the app renders the main menu
    expect(find.textContaining('jiii 3'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}

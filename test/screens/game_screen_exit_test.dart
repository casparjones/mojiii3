import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/screens/game_screen.dart';

void main() {
  group('GameScreen Exit button', () {
    testWidgets('Exit button is displayed in free mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen()),
      );
      await tester.pump();

      expect(find.text('Exit'), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('Exit button is displayed in level mode', (tester) async {
      final config = const LevelGenerator().generate(1);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(levelConfig: config)),
      );
      await tester.pump();

      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('Exit button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      // Navigate to GameScreen
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Tap Exit
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Spiel verlassen?'), findsOneWidget);
      expect(
        find.text('Spiel verlassen? Deine Zuege bleiben erhalten.'),
        findsOneWidget,
      );
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Verlassen'), findsOneWidget);
    });

    testWidgets('Cancel in dialog keeps game screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Should still be on GameScreen
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('Confirm in dialog navigates back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      // Tap Confirm
      await tester.tap(find.byKey(const Key('exit_confirm_btn')));
      await tester.pumpAndSettle();

      // Should have navigated back
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Go'), findsOneWidget);
    });
  });
}

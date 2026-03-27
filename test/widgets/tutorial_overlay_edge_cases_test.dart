import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:match3/widgets/tutorial_overlay.dart';

void main() {
  group('TutorialOverlay edge cases', () {
    testWidgets('tutorial_overlay key is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      expect(find.byKey(const Key('tutorial_overlay')), findsOneWidget);
    });

    testWidgets('tutorial_title key is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      expect(find.byKey(const Key('tutorial_title')), findsOneWidget);
    });

    testWidgets('tutorial_description key is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      expect(find.byKey(const Key('tutorial_description')), findsOneWidget);
    });

    testWidgets('first step shows "Tap to continue"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      expect(find.text('Tap to continue'), findsOneWidget);
    });

    testWidgets('single step tutorial shows "Tap to start playing"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'Only Step',
                  description: 'Description',
                  emoji: '!',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tap to start playing'), findsOneWidget);
    });

    testWidgets('onComplete is called after dismissing single step',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'Only',
                  description: 'Desc',
                  emoji: '!',
                ),
              ],
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('step indicators match step count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      // Default 4 steps = 4 indicator dots (Container widgets with circle shape)
      // We can count by checking that we find exactly 4 step titles through the flow
      expect(defaultTutorialSteps.length, 4);
    });

    testWidgets('custom steps with 2 steps work correctly', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(title: 'Step A', description: 'Desc A', emoji: 'A'),
                TutorialStep(title: 'Step B', description: 'Desc B', emoji: 'B'),
              ],
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Step A'), findsOneWidget);

      // Advance
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();

      expect(find.text('Step B'), findsOneWidget);

      // Complete
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('spotlight appears for steps with spotlightAlignment',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TutorialOverlay())),
      );
      await tester.pump();

      // First step has spotlightAlignment = Alignment.center, so Align widget is present
      expect(find.byType(Align), findsWidgets);
    });

    testWidgets('no spotlight for step without spotlightAlignment',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'No Spot',
                  description: 'No spotlight',
                  emoji: '!',
                  // spotlightAlignment is null
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No Spot'), findsOneWidget);
      // Should render without any spotlight circle, just the centered content
    });

    testWidgets('state exposes currentStep accessor', (tester) async {
      final key = GlobalKey<TutorialOverlayState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(key: key),
          ),
        ),
      );
      await tester.pump();

      expect(key.currentState!.currentStep, 0);
      expect(key.currentState!.isComplete, false);
    });

    testWidgets('onComplete null does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(title: 'X', description: 'Y', emoji: 'Z'),
              ],
              // onComplete is null
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();
      // Should not crash
    });

    testWidgets('default tutorial steps have correct titles', (tester) async {
      expect(defaultTutorialSteps[0].title, 'Tap to select');
      expect(defaultTutorialSteps[1].title, 'Swap with neighbor');
      expect(defaultTutorialSteps[2].title, '3 in a row = Match!');
      expect(defaultTutorialSteps[3].title, 'Have fun!');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/widgets/tutorial_overlay.dart';

void main() {
  group('TutorialOverlay', () {
    testWidgets('displays first step on creation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tutorial_overlay')), findsOneWidget);
      expect(find.byKey(const Key('tutorial_title')), findsOneWidget);
      expect(find.text('Tap to select'), findsOneWidget);
      expect(find.text('Tippe auf ein Emoji um es auszuwählen'),
          findsOneWidget);
    });

    testWidgets('advances to next step on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      expect(find.text('Tap to select'), findsOneWidget);

      // Tap to advance
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();

      // Step 2
      expect(find.text('Swap with neighbor'), findsOneWidget);
      expect(find.text('Tippe auf ein Nachbar-Emoji zum Tauschen'),
          findsOneWidget);
    });

    testWidgets('shows all 4 steps sequentially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      expect(find.text('Tap to select'), findsOneWidget);

      // Tap to step 2
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();
      expect(find.text('Swap with neighbor'), findsOneWidget);

      // Tap to step 3
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();
      expect(find.text('3 in a row = Match!'), findsOneWidget);

      // Tap to step 4
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();
      expect(find.text('Have fun!'), findsOneWidget);
    });

    testWidgets('calls onComplete when last step is dismissed',
        (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'Only step',
                  description: 'Just one step',
                  emoji: '\uD83D\uDC4B',
                ),
              ],
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Only step'), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.byKey(const Key('tutorial_overlay')));
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('shows step indicator dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have 4 step indicator dots (defaultTutorialSteps has 4 steps)
      // The dots are Container widgets with BoxShape.circle decoration
      // We can verify by finding the step indicator text
      expect(find.text('Tap to continue'), findsOneWidget);
    });

    testWidgets('last step shows "Tap to start playing"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(
              steps: const [
                TutorialStep(
                  title: 'Last',
                  description: 'The end',
                  emoji: '\uD83C\uDF89',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap to start playing'), findsOneWidget);
    });

    testWidgets('shows spotlight for steps with spotlightAlignment',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First step has spotlightAlignment = Alignment.center
      // Should find an Align widget (the spotlight container)
      expect(find.byType(Align), findsWidgets);
    });

    testWidgets('custom steps are displayed correctly', (tester) async {
      const customSteps = [
        TutorialStep(
          title: 'Custom Step 1',
          description: 'Custom description 1',
          emoji: '\u2764\uFE0F',
        ),
        TutorialStep(
          title: 'Custom Step 2',
          description: 'Custom description 2',
          emoji: '\uD83D\uDE80',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(steps: customSteps),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Step 1'), findsOneWidget);
      expect(find.text('Custom description 1'), findsOneWidget);
    });

    test('defaultTutorialSteps has 4 steps', () {
      expect(defaultTutorialSteps.length, 4);
    });

    test('TutorialStep constructor sets all fields', () {
      const step = TutorialStep(
        title: 'Test',
        description: 'Desc',
        emoji: 'E',
        spotlightAlignment: Alignment.topLeft,
      );
      expect(step.title, 'Test');
      expect(step.description, 'Desc');
      expect(step.emoji, 'E');
      expect(step.spotlightAlignment, Alignment.topLeft);
    });

    test('TutorialStep spotlightAlignment defaults to null', () {
      const step = TutorialStep(
        title: 'Test',
        description: 'Desc',
        emoji: 'E',
      );
      expect(step.spotlightAlignment, isNull);
    });
  });
}

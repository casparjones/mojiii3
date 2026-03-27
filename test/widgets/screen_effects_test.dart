import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/widgets/screen_effects.dart';

void main() {
  group('comboText', () {
    test('returns empty for level 1', () {
      expect(comboText(1), '');
    });

    test('returns x2 for level 2', () {
      expect(comboText(2), 'x2!');
    });

    test('returns x3 for level 3', () {
      expect(comboText(3), 'x3!');
    });

    test('returns AMAZING for level 4', () {
      expect(comboText(4), 'AMAZING!');
    });

    test('returns INCREDIBLE for level 5', () {
      expect(comboText(5), 'INCREDIBLE!');
    });

    test('returns LEGENDARY for level 6+', () {
      expect(comboText(6), contains('LEGENDARY'));
      expect(comboText(6), contains('6'));
      expect(comboText(10), contains('10'));
    });
  });

  group('comboColor', () {
    test('returns amber for low combos', () {
      expect(comboColor(1), Colors.amber);
      expect(comboColor(2), Colors.amber);
    });

    test('returns orange for level 3', () {
      expect(comboColor(3), Colors.orange);
    });

    test('returns deepOrange for level 4', () {
      expect(comboColor(4), Colors.deepOrange);
    });

    test('returns redAccent for level 5', () {
      expect(comboColor(5), Colors.redAccent);
    });

    test('returns purpleAccent for level 6+', () {
      expect(comboColor(6), Colors.purpleAccent);
    });
  });

  group('ComboPopup', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ComboPopup(text: 'x3!'),
            ),
          ),
        ),
      );

      expect(find.text('x3!'), findsOneWidget);
    });

    testWidgets('animates and completes', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ComboPopup(
                text: 'AMAZING!',
                duration: const Duration(milliseconds: 200),
                onComplete: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completed, true);
    });

    testWidgets('renders with custom color and fontSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ComboPopup(
                text: 'test',
                color: Colors.red,
                fontSize: 48.0,
              ),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('test'));
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.style?.fontSize, 48.0);
    });
  });

  group('ScreenShake', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScreenShake(
              child: Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shakes when shakeKey changes', (tester) async {
      int shakeKey = 0;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setter = setState;
                return ScreenShake(
                  shakeKey: shakeKey,
                  duration: const Duration(milliseconds: 100),
                  child: const Text('Shake me'),
                );
              },
            ),
          ),
        ),
      );

      // Trigger shake.
      setter(() => shakeKey = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Find the Transform.translate
      final transform = tester.widget<Transform>(
        find.byType(Transform).first,
      );
      expect(transform, isNotNull);

      await tester.pumpAndSettle();
    });

    testWidgets('does not shake when shakeKey is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScreenShake(
              shakeKey: 0,
              child: Text('Static'),
            ),
          ),
        ),
      );

      // The transform offset should be zero.
      final transform = tester.widget<Transform>(
        find.byType(Transform).first,
      );
      // Matrix translation should be at origin.
      expect(transform.transform.getTranslation().x, 0.0);
      expect(transform.transform.getTranslation().y, 0.0);
    });
  });

  group('FloatingScore', () {
    testWidgets('renders score text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              FloatingScore(
                score: 150,
                startPosition: const Offset(100, 100),
              ),
            ],
          ),
        ),
      );

      expect(find.text('+150'), findsOneWidget);
    });

    testWidgets('calls onComplete after animation', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              FloatingScore(
                score: 100,
                startPosition: const Offset(50, 50),
                duration: const Duration(milliseconds: 200),
                onComplete: () => completed = true,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completed, true);
    });
  });

  group('GlitterRain', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitterRain(
              duration: Duration(milliseconds: 200),
              particleCount: 10,
            ),
          ),
        ),
      );

      expect(find.byType(GlitterRain), findsOneWidget);
    });

    testWidgets('calls onComplete after duration', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlitterRain(
              duration: const Duration(milliseconds: 200),
              particleCount: 5,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completed, true);
    });
  });
}

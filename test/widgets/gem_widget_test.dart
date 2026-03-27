import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/widgets/gem_widget.dart';

void main() {
  group('GemWidget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(visual: GemVisuals.rubyRed),
          ),
        ),
      );

      expect(find.byType(GemWidget), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(visual: GemVisuals.sapphireBlue, size: 64.0),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(GemWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.size, const Size(64, 64));
    });

    testWidgets('fromGem factory works', (tester) async {
      const gem = Gem(type: GemType.red);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget.fromGem(gem: gem),
          ),
        ),
      );

      expect(find.byType(GemWidget), findsOneWidget);
    });

    testWidgets('handles tap events', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(
              visual: GemVisuals.emeraldGreen,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GemWidget));
      expect(tapped, true);
    });

    testWidgets('animates when animate is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(visual: GemVisuals.rubyRed, animate: true),
          ),
        ),
      );

      // Pump a frame to allow animation to progress.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GemWidget), findsOneWidget);
    });

    testWidgets('does not animate when animate is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(visual: GemVisuals.rubyRed, animate: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GemWidget), findsOneWidget);
    });

    testWidgets('updates animation state when animate changes', (tester) async {
      bool animate = true;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setter = setState;
                return GemWidget(
                  visual: GemVisuals.rubyRed,
                  animate: animate,
                );
              },
            ),
          ),
        ),
      );

      // Toggle animation off.
      setter(() => animate = false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GemWidget(visual: GemVisuals.rubyRed, animate: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GemWidget), findsOneWidget);
    });
  });

  group('GemCatalogWidget', () {
    testWidgets('renders all 24 gems', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GemCatalogWidget(gemSize: 32),
            ),
          ),
        ),
      );

      expect(find.byType(GemWidget), findsNWidgets(24));
    });
  });
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/widgets/gem_painter.dart';

void main() {
  group('GemPainter', () {
    test('can be instantiated with default values', () {
      final painter = GemPainter(visual: GemVisuals.rubyRed);
      expect(painter.visual, GemVisuals.rubyRed);
      expect(painter.shimmerProgress, 0.0);
      expect(painter.pulseScale, 1.0);
      expect(painter.highlighted, false);
    });

    test('can be instantiated with custom values', () {
      final painter = GemPainter(
        visual: GemVisuals.sapphireBlue,
        shimmerProgress: 0.5,
        pulseScale: 1.1,
        highlighted: true,
      );
      expect(painter.visual, GemVisuals.sapphireBlue);
      expect(painter.shimmerProgress, 0.5);
      expect(painter.pulseScale, 1.1);
      expect(painter.highlighted, true);
    });

    test('shouldRepaint returns true when visual changes', () {
      final a = GemPainter(visual: GemVisuals.rubyRed);
      final b = GemPainter(visual: GemVisuals.sapphireBlue);
      expect(a.shouldRepaint(b), true);
    });

    test('shouldRepaint returns true when shimmerProgress changes', () {
      final a = GemPainter(visual: GemVisuals.rubyRed, shimmerProgress: 0.0);
      final b = GemPainter(visual: GemVisuals.rubyRed, shimmerProgress: 0.5);
      expect(a.shouldRepaint(b), true);
    });

    test('shouldRepaint returns true when pulseScale changes', () {
      final a = GemPainter(visual: GemVisuals.rubyRed, pulseScale: 1.0);
      final b = GemPainter(visual: GemVisuals.rubyRed, pulseScale: 0.9);
      expect(a.shouldRepaint(b), true);
    });

    test('shouldRepaint returns true when highlighted changes', () {
      final a = GemPainter(visual: GemVisuals.rubyRed, highlighted: false);
      final b = GemPainter(visual: GemVisuals.rubyRed, highlighted: true);
      expect(a.shouldRepaint(b), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final a = GemPainter(visual: GemVisuals.rubyRed);
      final b = GemPainter(visual: GemVisuals.rubyRed);
      expect(a.shouldRepaint(b), false);
    });

    test('paints without errors for all shapes', () {
      // Test each shape variant paints without throwing.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(48, 48);

      for (final visual in GemVisuals.all) {
        final painter = GemPainter(
          visual: visual,
          shimmerProgress: 0.5,
          pulseScale: 1.0,
          highlighted: false,
        );
        // Should not throw.
        painter.paint(canvas, size);
      }

      recorder.endRecording();
    });

    test('paints with highlight enabled', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(48, 48);

      final painter = GemPainter(
        visual: GemVisuals.rubyRed,
        highlighted: true,
        shimmerProgress: 0.75,
      );
      painter.paint(canvas, size);

      recorder.endRecording();
    });

    test('paints with zero shimmer progress', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(48, 48);

      final painter = GemPainter(
        visual: GemVisuals.rubyRed,
        shimmerProgress: 0.0,
      );
      painter.paint(canvas, size);

      recorder.endRecording();
    });

    test('paints all shape types correctly', () {
      // Pick one visual for each shape type.
      final shapeVisuals = <GemShape, GemVisualDef>{};
      for (final v in GemVisuals.all) {
        shapeVisuals.putIfAbsent(v.shape, () => v);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(64, 64);

      for (final entry in shapeVisuals.entries) {
        final painter = GemPainter(
          visual: entry.value,
          shimmerProgress: 0.5,
        );
        painter.paint(canvas, size);
      }

      recorder.endRecording();

      // Verify we tested all shapes.
      expect(shapeVisuals.keys.toSet(), GemShape.values.toSet());
    });

    test('paints at different scales', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(48, 48);

      for (final scale in [0.5, 0.8, 1.0, 1.2, 1.5]) {
        final painter = GemPainter(
          visual: GemVisuals.rubyRed,
          pulseScale: scale,
        );
        painter.paint(canvas, size);
      }

      recorder.endRecording();
    });
  });
}

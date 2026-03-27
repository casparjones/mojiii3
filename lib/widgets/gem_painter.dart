import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gem_type.dart';

/// CustomPainter that renders a gem with facets, gradients, and glint effects.
class GemPainter extends CustomPainter {
  final GemVisualDef visual;

  /// Animation progress for the idle shimmer effect (0.0 to 1.0).
  final double shimmerProgress;

  /// Scale factor for pulsing idle animation (1.0 = normal size).
  final double pulseScale;

  /// Whether the gem is selected / highlighted.
  final bool highlighted;

  GemPainter({
    required this.visual,
    this.shimmerProgress = 0.0,
    this.pulseScale = 1.0,
    this.highlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) * pulseScale * 0.85;

    // Draw highlight ring if selected.
    if (highlighted) {
      _drawHighlight(canvas, center, radius);
    }

    // Draw base shape.
    final path = _buildShapePath(center, radius);
    _drawBase(canvas, center, radius, path);

    // Draw facets.
    _drawFacets(canvas, center, radius, path);

    // Draw shimmer / glint.
    _drawShimmer(canvas, center, radius);
  }

  Path _buildShapePath(Offset center, double radius) {
    switch (visual.shape) {
      case GemShape.diamond:
        return _diamondPath(center, radius);
      case GemShape.circle:
        return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      case GemShape.square:
        final r = radius * 0.85;
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 2, height: r * 2),
            Radius.circular(r * 0.15),
          ));
      case GemShape.hexagon:
        return _polygonPath(center, radius, 6);
      case GemShape.triangle:
        return _polygonPath(center, radius, 3, rotationOffset: -math.pi / 2);
      case GemShape.star:
        return _starPath(center, radius, 5);
      case GemShape.teardrop:
        return _teardropPath(center, radius);
    }
  }

  Path _diamondPath(Offset center, double r) {
    return Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.75, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.75, center.dy)
      ..close();
  }

  Path _polygonPath(Offset center, double r, int sides,
      {double rotationOffset = -math.pi / 2}) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = rotationOffset + (2 * math.pi * i / sides);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _starPath(Offset center, double r, int points) {
    final path = Path();
    final innerR = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + (math.pi * i / points);
      final currentR = i.isEven ? r : innerR;
      final x = center.dx + currentR * math.cos(angle);
      final y = center.dy + currentR * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _teardropPath(Offset center, double r) {
    final path = Path();
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(
      center.dx + r, center.dy - r * 0.3,
      center.dx + r * 0.6, center.dy + r * 0.3,
    );
    path.quadraticBezierTo(
      center.dx + r * 0.2, center.dy + r,
      center.dx, center.dy + r,
    );
    path.quadraticBezierTo(
      center.dx - r * 0.2, center.dy + r,
      center.dx - r * 0.6, center.dy + r * 0.3,
    );
    path.quadraticBezierTo(
      center.dx - r, center.dy - r * 0.3,
      center.dx, center.dy - r,
    );
    path.close();
    return path;
  }

  void _drawBase(Canvas canvas, Offset center, double radius, Path path) {
    // Gradient fill.
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [visual.secondaryColor, visual.primaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, paint);

    // Outline.
    final outlinePaint = Paint()
      ..color = visual.primaryColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);
  }

  void _drawFacets(Canvas canvas, Offset center, double radius, Path path) {
    canvas.save();
    canvas.clipPath(path);

    final facetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = visual.glintColor.withValues(alpha: 0.3);

    final count = visual.facetCount;
    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), facetPaint);
    }

    canvas.restore();
  }

  void _drawShimmer(Canvas canvas, Offset center, double radius) {
    if (shimmerProgress <= 0) return;

    // Rotating glint spot.
    final angle = shimmerProgress * 2 * math.pi;
    final glintOffset = Offset(
      center.dx + radius * 0.35 * math.cos(angle),
      center.dy + radius * 0.35 * math.sin(angle),
    );

    final glintPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          visual.glintColor.withValues(alpha: 0.8),
          visual.glintColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glintOffset, radius: radius * 0.4));

    canvas.drawCircle(glintOffset, radius * 0.4, glintPaint);

    // Small highlight dot at top-left.
    final highlightPaint = Paint()
      ..color = visual.glintColor.withValues(
        alpha: 0.5 + 0.5 * math.sin(shimmerProgress * math.pi * 2),
      );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
      radius * 0.1,
      highlightPaint,
    );
  }

  void _drawHighlight(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius + 3, paint);
  }

  @override
  bool shouldRepaint(covariant GemPainter oldDelegate) {
    return oldDelegate.visual != visual ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.highlighted != highlighted;
  }
}

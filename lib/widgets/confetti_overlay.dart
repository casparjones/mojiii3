import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single confetti particle.
class _ConfettiParticle {
  Offset position;
  Offset velocity;
  double life;
  double maxLife;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  /// Shape: 0 = rect, 1 = circle, 2 = long strip
  int shape;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  }) : maxLife = life;

  bool get isAlive => life > 0;

  double get opacity => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    position += velocity * dt;
    // Gravity pulls down, slight air resistance.
    velocity = Offset(
      velocity.dx * 0.98,
      velocity.dy + 400.0 * dt,
    );
    rotation += rotationSpeed * dt;
    life -= dt;
  }
}

/// CustomPainter for rendering confetti particles.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (!p.isAlive) continue;
      final alpha = (p.opacity * 255).round();
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      switch (p.shape) {
        case 0:
          // Small square
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case 1:
          // Circle
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case 2:
          // Long rectangular strip
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size * 0.4, height: p.size * 1.5),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// An overlay widget that shows a confetti burst explosion.
///
/// Place this as a child in a Stack that covers the game board.
/// Call [ConfettiOverlayState.trigger] to start a confetti burst at a
/// specific position with a given combo level.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  final List<_ConfettiParticle> _particles = [];
  late AnimationController _controller;
  double _lastTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_tick);
  }

  void _tick() {
    final now = _controller.value * 2.0; // duration is 2 seconds
    final dt = now >= _lastTimestamp
        ? (now - _lastTimestamp)
        : (2.0 - _lastTimestamp + now);
    _lastTimestamp = now;

    // Clamp dt to avoid huge jumps.
    final safeDt = dt.clamp(0.0, 0.05);

    for (final p in _particles) {
      p.update(safeDt);
    }
    _particles.removeWhere((p) => !p.isAlive);

    if (_particles.isEmpty) {
      _controller.stop();
    }

    setState(() {});
  }

  /// Trigger a confetti burst.
  ///
  /// [origin] is the center point in local coordinates of this widget.
  /// [comboLevel] controls the intensity (2 = small, 3 = medium, 4+ = large).
  /// [colors] are the confetti colors to use.
  void trigger({
    required Offset origin,
    required int comboLevel,
    List<Color>? colors,
  }) {
    final rng = math.Random();

    final effectiveColors = colors ??
        const [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ];

    // Scale particle count with combo level.
    final int particleCount;
    final double speedMultiplier;
    final double sizeMultiplier;
    final double lifetime;

    if (comboLevel <= 2) {
      particleCount = 25;
      speedMultiplier = 1.0;
      sizeMultiplier = 1.0;
      lifetime = 1.0;
    } else if (comboLevel == 3) {
      particleCount = 50;
      speedMultiplier = 1.3;
      sizeMultiplier = 1.2;
      lifetime = 1.2;
    } else {
      // 4x+ : full screen confetti rain
      particleCount = 80 + (comboLevel - 4) * 15;
      speedMultiplier = 1.6;
      sizeMultiplier = 1.4;
      lifetime = 1.5;
    }

    final clampedCount = particleCount.clamp(15, 200);

    for (int i = 0; i < clampedCount; i++) {
      // For 4x+ combos, spread origins across the top half for a rain effect.
      final Offset spawnPos;
      if (comboLevel >= 4) {
        final size = (context.findRenderObject() as RenderBox?)?.size;
        if (size != null && rng.nextDouble() < 0.5) {
          // Half particles from random positions across the top.
          spawnPos = Offset(
            rng.nextDouble() * size.width,
            rng.nextDouble() * size.height * 0.3,
          );
        } else {
          spawnPos = origin;
        }
      } else {
        spawnPos = origin;
      }

      final angle = rng.nextDouble() * 2 * math.pi;
      final speed =
          (100.0 + rng.nextDouble() * 250.0) * speedMultiplier;
      final size = (3.0 + rng.nextDouble() * 5.0) * sizeMultiplier;
      final color = effectiveColors[rng.nextInt(effectiveColors.length)];

      _particles.add(_ConfettiParticle(
        position: spawnPos,
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 150.0, // bias upward initially
        ),
        life: lifetime * (0.6 + rng.nextDouble() * 0.4),
        size: size,
        color: color,
        rotation: rng.nextDouble() * 2 * math.pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8.0,
        shape: rng.nextInt(3),
      ));
    }

    _lastTimestamp = 0;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(particles: _particles),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Maps a [GemType] name to a representative confetti color.
/// Use this to derive confetti colors from matched gem types.
Color gemTypeToColor(String gemTypeName) {
  switch (gemTypeName) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'purple':
      return Colors.purple;
    case 'orange':
      return Colors.orange;
    default:
      return Colors.white;
  }
}

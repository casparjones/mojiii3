import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single particle in the particle system.
class Particle {
  Offset position;
  Offset velocity;
  double life; // 0.0 = dead, 1.0 = just born
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    this.life = 1.0,
    this.size = 4.0,
    required this.color,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  });

  /// Whether this particle is still alive.
  bool get isAlive => life > 0;

  /// Update particle state for one tick.
  void update(double dt, {double gravity = 200.0, double drag = 0.98}) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * drag, velocity.dy * drag + gravity * dt);
    rotation += rotationSpeed * dt;
    life -= dt;
  }
}

/// Configuration for a particle emitter burst.
class ParticleEmitterConfig {
  final int particleCount;
  final double minSpeed;
  final double maxSpeed;
  final double minSize;
  final double maxSize;
  final double lifetime;
  final double gravity;
  final double drag;
  final List<Color> colors;
  final double spread; // Angle spread in radians (2*pi = full circle)

  const ParticleEmitterConfig({
    this.particleCount = 20,
    this.minSpeed = 50.0,
    this.maxSpeed = 200.0,
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.lifetime = 1.0,
    this.gravity = 200.0,
    this.drag = 0.98,
    this.colors = const [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.white,
    ],
    this.spread = 2 * math.pi,
  });

  /// Preset for match burst explosions.
  static const matchBurst = ParticleEmitterConfig(
    particleCount: 12,
    minSpeed: 80.0,
    maxSpeed: 180.0,
    minSize: 2.0,
    maxSize: 5.0,
    lifetime: 0.8,
    gravity: 150.0,
  );

  /// Preset for combo celebration.
  static const comboCelebration = ParticleEmitterConfig(
    particleCount: 30,
    minSpeed: 100.0,
    maxSpeed: 300.0,
    minSize: 3.0,
    maxSize: 8.0,
    lifetime: 1.5,
    gravity: 100.0,
    colors: [
      Colors.amber,
      Colors.yellow,
      Colors.orange,
      Colors.white,
    ],
  );

  /// Preset for glitter rain (level complete).
  static const glitterRain = ParticleEmitterConfig(
    particleCount: 50,
    minSpeed: 20.0,
    maxSpeed: 60.0,
    minSize: 2.0,
    maxSize: 4.0,
    lifetime: 3.0,
    gravity: 50.0,
    drag: 0.995,
    colors: [
      Colors.white,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.amber,
      Colors.greenAccent,
    ],
  );
}

/// Manages a collection of particles.
class ParticleSystem {
  final List<Particle> _particles = [];
  final math.Random _random;

  ParticleSystem({math.Random? random}) : _random = random ?? math.Random();

  /// All currently alive particles.
  List<Particle> get particles => List.unmodifiable(_particles);

  /// Number of alive particles.
  int get particleCount => _particles.length;

  /// Whether the system has any active particles.
  bool get isActive => _particles.isNotEmpty;

  /// Emit a burst of particles at the given origin.
  void emit(Offset origin, ParticleEmitterConfig config) {
    for (int i = 0; i < config.particleCount; i++) {
      final angle = _random.nextDouble() * config.spread -
          config.spread / 2 -
          math.pi / 2;
      final speed = config.minSpeed +
          _random.nextDouble() * (config.maxSpeed - config.minSpeed);
      final size = config.minSize +
          _random.nextDouble() * (config.maxSize - config.minSize);
      final color = config.colors[_random.nextInt(config.colors.length)];

      _particles.add(Particle(
        position: origin,
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        life: config.lifetime,
        size: size,
        color: color,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6.0,
      ));
    }
  }

  /// Update all particles; remove dead ones.
  void update(double dt, {double gravity = 200.0, double drag = 0.98}) {
    for (final p in _particles) {
      p.update(dt, gravity: gravity, drag: drag);
    }
    _particles.removeWhere((p) => !p.isAlive);
  }

  /// Remove all particles.
  void clear() {
    _particles.clear();
  }
}

/// CustomPainter that renders a ParticleSystem.
class ParticlePainter extends CustomPainter {
  final ParticleSystem system;

  ParticlePainter({required this.system});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in system.particles) {
      if (!p.isAlive) continue;
      final alpha = (p.life.clamp(0.0, 1.0) * 255).round();
      final paint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

/// Widget that manages a ParticleSystem with animation loop.
class ParticleOverlay extends StatefulWidget {
  final ParticleSystem system;
  final Widget? child;

  const ParticleOverlay({
    super.key,
    required this.system,
    this.child,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _controller.repeat();
  }

  void _tick() {
    final currentTime = _controller.value;
    // Calculate dt based on animation progress (wrapping at 1.0).
    final dt = currentTime >= _lastTime
        ? (currentTime - _lastTime)
        : (1.0 - _lastTime + currentTime);
    _lastTime = currentTime;

    if (widget.system.isActive) {
      widget.system.update(dt);
      // Trigger repaint.
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(system: widget.system),
      child: widget.child,
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/widgets/particle_system.dart';

void main() {
  group('Particle', () {
    test('creates with required fields', () {
      final p = Particle(
        position: const Offset(10, 20),
        velocity: const Offset(5, -10),
        color: Colors.red,
      );
      expect(p.position, const Offset(10, 20));
      expect(p.velocity, const Offset(5, -10));
      expect(p.life, 1.0);
      expect(p.isAlive, true);
      expect(p.color, Colors.red);
    });

    test('update moves particle', () {
      final p = Particle(
        position: const Offset(0, 0),
        velocity: const Offset(100, 0),
        color: Colors.red,
        life: 1.0,
      );
      p.update(0.1, gravity: 0, drag: 1.0);
      expect(p.position.dx, closeTo(10.0, 0.01));
      expect(p.life, closeTo(0.9, 0.01));
    });

    test('update applies gravity', () {
      final p = Particle(
        position: const Offset(0, 0),
        velocity: const Offset(0, 0),
        color: Colors.red,
      );
      p.update(0.1, gravity: 100.0, drag: 1.0);
      expect(p.velocity.dy, closeTo(10.0, 0.01));
    });

    test('update applies drag', () {
      final p = Particle(
        position: const Offset(0, 0),
        velocity: const Offset(100, 0),
        color: Colors.red,
      );
      p.update(0.1, gravity: 0, drag: 0.5);
      expect(p.velocity.dx, closeTo(50.0, 0.01));
    });

    test('dies when life reaches zero', () {
      final p = Particle(
        position: Offset.zero,
        velocity: Offset.zero,
        color: Colors.red,
        life: 0.1,
      );
      p.update(0.2, gravity: 0, drag: 1.0);
      expect(p.isAlive, false);
    });

    test('rotation updates', () {
      final p = Particle(
        position: Offset.zero,
        velocity: Offset.zero,
        color: Colors.red,
        rotationSpeed: 2.0,
      );
      p.update(0.5, gravity: 0, drag: 1.0);
      expect(p.rotation, closeTo(1.0, 0.01));
    });
  });

  group('ParticleEmitterConfig', () {
    test('default config has valid values', () {
      const config = ParticleEmitterConfig();
      expect(config.particleCount, 20);
      expect(config.minSpeed, lessThan(config.maxSpeed));
      expect(config.minSize, lessThan(config.maxSize));
      expect(config.lifetime, greaterThan(0));
      expect(config.colors, isNotEmpty);
    });

    test('matchBurst preset is valid', () {
      const config = ParticleEmitterConfig.matchBurst;
      expect(config.particleCount, 12);
      expect(config.lifetime, 0.8);
    });

    test('comboCelebration preset is valid', () {
      const config = ParticleEmitterConfig.comboCelebration;
      expect(config.particleCount, 30);
    });

    test('glitterRain preset is valid', () {
      const config = ParticleEmitterConfig.glitterRain;
      expect(config.particleCount, 50);
      expect(config.lifetime, 3.0);
    });
  });

  group('ParticleSystem', () {
    late ParticleSystem system;

    setUp(() {
      system = ParticleSystem(random: math.Random(42));
    });

    test('starts empty', () {
      expect(system.particleCount, 0);
      expect(system.isActive, false);
      expect(system.particles, isEmpty);
    });

    test('emit creates particles', () {
      system.emit(const Offset(100, 100), const ParticleEmitterConfig(
        particleCount: 10,
      ));
      expect(system.particleCount, 10);
      expect(system.isActive, true);
    });

    test('emit places particles at origin', () {
      system.emit(const Offset(50, 75), const ParticleEmitterConfig(
        particleCount: 5,
      ));
      for (final p in system.particles) {
        expect(p.position, const Offset(50, 75));
      }
    });

    test('update removes dead particles', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 5,
        lifetime: 0.1,
      ));
      expect(system.particleCount, 5);

      // Update past lifetime.
      system.update(0.2, gravity: 0, drag: 1.0);
      expect(system.particleCount, 0);
      expect(system.isActive, false);
    });

    test('update moves particles', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 1,
        minSpeed: 100,
        maxSpeed: 100,
        lifetime: 2.0,
      ));
      final before = system.particles.first.position;
      system.update(0.1, gravity: 0, drag: 1.0);
      final after = system.particles.first.position;
      expect(after, isNot(equals(before)));
    });

    test('clear removes all particles', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 20,
      ));
      expect(system.isActive, true);
      system.clear();
      expect(system.particleCount, 0);
      expect(system.isActive, false);
    });

    test('multiple emits accumulate particles', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 5,
      ));
      system.emit(const Offset(100, 100), const ParticleEmitterConfig(
        particleCount: 3,
      ));
      expect(system.particleCount, 8);
    });

    test('particles have randomized velocities', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 10,
      ));
      final velocities = system.particles.map((p) => p.velocity).toSet();
      // With 10 particles, very unlikely all have the same velocity.
      expect(velocities.length, greaterThan(1));
    });

    test('particles have randomized sizes', () {
      system.emit(const Offset(0, 0), const ParticleEmitterConfig(
        particleCount: 10,
        minSize: 1.0,
        maxSize: 10.0,
      ));
      final sizes = system.particles.map((p) => p.size).toSet();
      expect(sizes.length, greaterThan(1));
    });
  });

  group('ParticlePainter', () {
    test('paints without errors', () {
      final system = ParticleSystem();
      system.emit(const Offset(50, 50), const ParticleEmitterConfig(
        particleCount: 5,
      ));

      final painter = ParticlePainter(system: system);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 200));
      recorder.endRecording();
    });

    test('shouldRepaint always returns true', () {
      final system = ParticleSystem();
      final painter1 = ParticlePainter(system: system);
      final painter2 = ParticlePainter(system: system);
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('paints empty system without errors', () {
      final system = ParticleSystem();
      final painter = ParticlePainter(system: system);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 200));
      recorder.endRecording();
    });
  });

  group('ParticleOverlay', () {
    testWidgets('renders with particle system', (tester) async {
      final system = ParticleSystem();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(
              system: system,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });

    testWidgets('renders without child', (tester) async {
      final system = ParticleSystem();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParticleOverlay(system: system),
          ),
        ),
      );

      expect(find.byType(ParticleOverlay), findsOneWidget);
    });
  });
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Combo Popup
// ---------------------------------------------------------------------------

/// Shows a floating combo text (e.g., "x3!", "AMAZING!") that
/// animates upward and fades out.
class ComboPopup extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final Duration duration;
  final VoidCallback? onComplete;

  const ComboPopup({
    super.key,
    required this.text,
    this.color = Colors.amber,
    this.fontSize = 32.0,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<ComboPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          color: widget.color,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to generate combo text based on cascade level.
String comboText(int cascadeLevel) {
  if (cascadeLevel <= 1) return '';
  if (cascadeLevel == 2) return 'x2!';
  if (cascadeLevel == 3) return 'x3!';
  if (cascadeLevel == 4) return 'AMAZING!';
  if (cascadeLevel == 5) return 'INCREDIBLE!';
  return 'LEGENDARY x$cascadeLevel!';
}

/// Returns a color for the combo level.
Color comboColor(int cascadeLevel) {
  if (cascadeLevel <= 2) return Colors.amber;
  if (cascadeLevel == 3) return Colors.orange;
  if (cascadeLevel == 4) return Colors.deepOrange;
  if (cascadeLevel == 5) return Colors.redAccent;
  return Colors.purpleAccent;
}

// ---------------------------------------------------------------------------
// Screen Shake
// ---------------------------------------------------------------------------

/// A widget that shakes its child when triggered.
class ScreenShake extends StatefulWidget {
  final Widget child;
  final double intensity;
  final Duration duration;

  /// Set to a new unique object / counter to trigger a shake.
  final int shakeKey;

  const ScreenShake({
    super.key,
    required this.child,
    this.intensity = 8.0,
    this.duration = const Duration(milliseconds: 300),
    this.shakeKey = 0,
  });

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        setState(() {
          final progress = 1.0 - _controller.value;
          final magnitude = widget.intensity * progress;
          _offset = Offset(
            (_random.nextDouble() - 0.5) * 2 * magnitude,
            (_random.nextDouble() - 0.5) * 2 * magnitude,
          );
        });
      });
  }

  @override
  void didUpdateWidget(ScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shakeKey != widget.shakeKey && widget.shakeKey > 0) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Floating Score
// ---------------------------------------------------------------------------

/// A floating score number that rises and fades.
class FloatingScore extends StatefulWidget {
  final int score;
  final Offset startPosition;
  final Duration duration;
  final VoidCallback? onComplete;

  const FloatingScore({
    super.key,
    required this.score,
    required this.startPosition,
    this.duration = const Duration(milliseconds: 600),
    this.onComplete,
  });

  @override
  State<FloatingScore> createState() => _FloatingScoreState();
}

class _FloatingScoreState extends State<FloatingScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _posYAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _posYAnimation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx,
          top: widget.startPosition.dy + _posYAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Text(
        '+${widget.score}',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glitter Rain
// ---------------------------------------------------------------------------

/// Glitter rain overlay for level completion.
class GlitterRain extends StatefulWidget {
  final Duration duration;
  final int particleCount;
  final VoidCallback? onComplete;

  const GlitterRain({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.particleCount = 40,
    this.onComplete,
  });

  @override
  State<GlitterRain> createState() => _GlitterRainState();
}

class _GlitterRainState extends State<GlitterRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_GlitterParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _randomParticle());

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        setState(() {});
      });

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  _GlitterParticle _randomParticle() {
    final colors = [
      Colors.white,
      Colors.amber,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
    ];
    return _GlitterParticle(
      x: _random.nextDouble(),
      startY: -0.1 - _random.nextDouble() * 0.3,
      speed: 0.3 + _random.nextDouble() * 0.4,
      wobble: (_random.nextDouble() - 0.5) * 0.1,
      size: 2.0 + _random.nextDouble() * 4.0,
      color: colors[_random.nextInt(colors.length)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlitterPainter(
        particles: _particles,
        progress: _controller.value,
      ),
      size: Size.infinite,
    );
  }
}

class _GlitterParticle {
  final double x;
  final double startY;
  final double speed;
  final double wobble;
  final double size;
  final Color color;

  const _GlitterParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.wobble,
    required this.size,
    required this.color,
  });
}

class _GlitterPainter extends CustomPainter {
  final List<_GlitterParticle> particles;
  final double progress;

  _GlitterPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.startY + progress * p.speed * 2;
      if (y < 0 || y > 1.0) continue;

      final x = p.x + math.sin(progress * math.pi * 4 + p.x * 10) * p.wobble;
      final alpha = (1.0 - (progress * 0.7).clamp(0.0, 1.0));

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlitterPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

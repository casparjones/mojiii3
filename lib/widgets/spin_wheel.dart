import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/emoji_text.dart';

/// A single segment on the spin wheel.
class WheelSegment {
  final String label;
  final String emoji;
  final Color color;
  final WheelRewardType rewardType;

  /// Reward value: coin amount, or 1 for powerup/emoji.
  final int rewardValue;

  /// For powerup rewards: the powerup ID string.
  final String? powerUpId;

  /// For emoji rewards: the emoji string to show.
  final String? rewardEmoji;

  /// Relative weight for random selection (higher = more likely).
  final int weight;

  const WheelSegment({
    required this.label,
    required this.emoji,
    required this.color,
    required this.rewardType,
    this.rewardValue = 1,
    this.powerUpId,
    this.rewardEmoji,
    this.weight = 1,
  });
}

enum WheelRewardType {
  coins,
  powerUp,
  emoji,
}

/// Result of a spin.
class SpinResult {
  final WheelSegment segment;
  final int segmentIndex;

  const SpinResult({required this.segment, required this.segmentIndex});
}

/// Default segments for the boss victory wheel.
List<WheelSegment> defaultBossWheelSegments() {
  return const [
    WheelSegment(
      label: '50 Coins',
      emoji: '\u{1FA99}',
      color: Color(0xFFFFD700),
      rewardType: WheelRewardType.coins,
      rewardValue: 50,
      weight: 15,
    ),
    WheelSegment(
      label: 'Shuffle',
      emoji: '\u{1F500}',
      color: Color(0xFF4FC3F7),
      rewardType: WheelRewardType.powerUp,
      powerUpId: 'powerup_shuffle',
      weight: 18,
    ),
    WheelSegment(
      label: '100 Coins',
      emoji: '\u{1FA99}',
      color: Color(0xFFFFA000),
      rewardType: WheelRewardType.coins,
      rewardValue: 100,
      weight: 10,
    ),
    WheelSegment(
      label: 'Color Bomb',
      emoji: '\u{1F4A3}\u{1F308}',
      color: Color(0xFFE040FB),
      rewardType: WheelRewardType.powerUp,
      powerUpId: 'powerup_color_bomb',
      weight: 12,
    ),
    WheelSegment(
      label: '25 Coins',
      emoji: '\u{1FA99}',
      color: Color(0xFFFFEB3B),
      rewardType: WheelRewardType.coins,
      rewardValue: 25,
      weight: 15,
    ),
    WheelSegment(
      label: 'Extra Moves',
      emoji: '\u{1F48A}',
      color: Color(0xFF66BB6A),
      rewardType: WheelRewardType.powerUp,
      powerUpId: 'powerup_extra_moves',
      weight: 18,
    ),
    WheelSegment(
      label: '200 Coins',
      emoji: '\u{1FA99}',
      color: Color(0xFFFF8F00),
      rewardType: WheelRewardType.coins,
      rewardValue: 200,
      weight: 5,
    ),
    WheelSegment(
      label: 'Mega Moves',
      emoji: '\u{1F48A}\u{1F48A}',
      color: Color(0xFF42A5F5),
      rewardType: WheelRewardType.powerUp,
      powerUpId: 'powerup_mega_moves',
      weight: 7,
    ),
  ];
}

/// A spinning wheel widget displayed after defeating a boss.
///
/// The player taps to spin. The wheel rotates with deceleration and lands on
/// a weighted-random segment. A callback fires with the result.
class SpinWheelDialog extends StatefulWidget {
  final List<WheelSegment> segments;
  final void Function(SpinResult result) onSpinComplete;
  final String bossEmoji;
  final String bossName;

  const SpinWheelDialog({
    super.key,
    required this.segments,
    required this.onSpinComplete,
    this.bossEmoji = '',
    this.bossName = '',
  });

  @override
  State<SpinWheelDialog> createState() => _SpinWheelDialogState();
}

class _SpinWheelDialogState extends State<SpinWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasSpun = false;
  bool _spinning = false;
  SpinResult? _result;
  int? _targetIndex;
  double _currentAngle = 0;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pick a segment based on weighted probability.
  int _pickWeightedIndex() {
    final totalWeight =
        widget.segments.fold<int>(0, (sum, s) => sum + s.weight);
    var roll = _random.nextInt(totalWeight);
    for (var i = 0; i < widget.segments.length; i++) {
      roll -= widget.segments[i].weight;
      if (roll < 0) return i;
    }
    return widget.segments.length - 1;
  }

  void _spin() {
    if (_hasSpun || _spinning) return;
    setState(() => _spinning = true);

    _targetIndex = _pickWeightedIndex();
    final segCount = widget.segments.length;
    final segAngle = 2 * pi / segCount;

    // Target angle: land in the middle of the target segment.
    // Segment 0 starts at the top (12 o'clock). The pointer is at the top.
    // We spin clockwise, so to land on segment i, the wheel needs to rotate
    // so that segment i is at the top.
    final targetSegCenter = _targetIndex! * segAngle + segAngle / 2;
    // We want the wheel to rotate many full turns plus the offset to land
    // the target segment under the pointer at the top.
    final fullRotations = 5 + _random.nextInt(3); // 5-7 full spins
    final targetAngle =
        fullRotations * 2 * pi + (2 * pi - targetSegCenter);

    _animation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _animation.addListener(() {
      setState(() {
        _currentAngle = _animation.value;
      });
    });

    _controller.forward().then((_) {
      final result = SpinResult(
        segment: widget.segments[_targetIndex!],
        segmentIndex: _targetIndex!,
      );
      setState(() {
        _spinning = false;
        _hasSpun = true;
        _result = result;
      });
      widget.onSpinComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Title
            if (widget.bossEmoji.isNotEmpty) ...[
              EmojiText(widget.bossEmoji, fontSize: 40),
              const SizedBox(height: 4),
            ],
            Text(
              _result != null ? 'Gewonnen!' : 'Boss besiegt!',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.bossName.isNotEmpty && _result == null)
              Text(
                '${widget.bossName} wurde besiegt!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            const SizedBox(height: 12),
            // Wheel
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Wheel
                  Transform.rotate(
                    angle: _currentAngle,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _WheelPainter(segments: widget.segments),
                    ),
                  ),
                  // Pointer (top)
                  Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: const Size(24, 20),
                      painter: _PointerPainter(),
                    ),
                  ),
                  // Center circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1a1a2e),
                      border: Border.all(color: Colors.amberAccent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amberAccent.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _spinning
                          ? const Icon(Icons.autorenew, color: Colors.amberAccent, size: 24)
                          : const Icon(Icons.touch_app, color: Colors.amberAccent, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Result display or spin button
            if (_result != null) ...[
              _buildResultDisplay(_result!),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('spin_wheel_close_btn'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Weiter',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              TextButton(
                key: const Key('spin_wheel_spin_btn'),
                onPressed: _spinning ? null : _spin,
                child: Text(
                  _spinning ? 'Dreht...' : 'Drehen!',
                  style: TextStyle(
                    color: _spinning ? Colors.white38 : Colors.amberAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay(SpinResult result) {
    final seg = result.segment;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: seg.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: seg.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(seg.emoji, fontSize: 36),
          const SizedBox(height: 4),
          Text(
            seg.label,
            style: TextStyle(
              color: seg.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _rewardDescription(seg),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _rewardDescription(WheelSegment seg) {
    switch (seg.rewardType) {
      case WheelRewardType.coins:
        return '+${seg.rewardValue} Muenzen erhalten!';
      case WheelRewardType.powerUp:
        return '${seg.label} erhalten!';
      case WheelRewardType.emoji:
        return 'Neues Emoji freigeschaltet!';
    }
  }
}

/// Custom painter for the wheel segments.
class _WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * pi / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final startAngle = -pi / 2 + i * segAngle;
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        paint,
      );

      // Border between segments
      final borderPaint = Paint()
        ..color = const Color(0xFF1a1a2e)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        borderPaint,
      );

      // Draw emoji text in the segment
      final midAngle = startAngle + segAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(midAngle);
      final textY = center.dy + textRadius * sin(midAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].emoji,
          style: const TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Outer ring
    final outerRingPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}

/// The arrow pointer at the top of the wheel.
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF1a1a2e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

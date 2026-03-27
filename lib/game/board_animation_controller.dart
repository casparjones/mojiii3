import 'package:flutter/material.dart';
import '../models/position.dart';

/// Types of animations that can occur on the board.
enum BoardAnimationType {
  swap,
  swapFailed,
  match,
  fall,
  spawn,
  idle,
}

/// Describes a single animated gem movement or effect.
class GemAnimation {
  final BoardAnimationType type;
  final Position from;
  final Position to;

  /// Progress from 0.0 (start) to 1.0 (end).
  final double progress;

  /// Optional scale factor (used for match burst).
  final double scale;

  /// Optional opacity (used for match fade-out / spawn fade-in).
  final double opacity;

  const GemAnimation({
    required this.type,
    required this.from,
    required this.to,
    this.progress = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
  });

  GemAnimation withProgress(double p) => GemAnimation(
        type: type,
        from: from,
        to: to,
        progress: p,
        scale: scale,
        opacity: opacity,
      );

  /// Returns the interpolated position at current progress.
  Offset interpolatedOffset(double cellSize) {
    final fromOffset = Offset(from.col * cellSize, from.row * cellSize);
    final toOffset = Offset(to.col * cellSize, to.row * cellSize);
    return Offset.lerp(fromOffset, toOffset, progress)!;
  }

  @override
  String toString() =>
      'GemAnimation($type, $from -> $to, progress: ${progress.toStringAsFixed(2)})';
}

/// Manages all board animations: swap, match, fall, and spawn.
///
/// This controller coordinates the sequencing of animation phases
/// and provides per-gem animation state for rendering.
class BoardAnimationController extends ChangeNotifier {
  final TickerProvider _vsync;

  /// Duration for swap animations.
  final Duration swapDuration;

  /// Duration for match (burst) animations.
  final Duration matchDuration;

  /// Duration for falling animations.
  final Duration fallDuration;

  /// Duration for spawn (fade-in from top) animations.
  final Duration spawnDuration;

  AnimationController? _currentController;
  List<GemAnimation> _currentAnimations = [];
  BoardAnimationType _currentPhase = BoardAnimationType.idle;
  VoidCallback? _onPhaseComplete;

  BoardAnimationController({
    required TickerProvider vsync,
    this.swapDuration = const Duration(milliseconds: 250),
    this.matchDuration = const Duration(milliseconds: 300),
    this.fallDuration = const Duration(milliseconds: 350),
    this.spawnDuration = const Duration(milliseconds: 200),
  }) : _vsync = vsync;

  /// The current animation phase.
  BoardAnimationType get currentPhase => _currentPhase;

  /// Whether any animation is currently running.
  bool get isAnimating => _currentController?.isAnimating ?? false;

  /// Current animations for rendering.
  List<GemAnimation> get currentAnimations =>
      List.unmodifiable(_currentAnimations);

  /// Get the animation for a specific position, if any.
  GemAnimation? animationAt(Position pos) {
    for (final anim in _currentAnimations) {
      if (anim.from == pos || anim.to == pos) return anim;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Swap animation
  // ---------------------------------------------------------------------------

  /// Animate a swap between two positions.
  Future<void> animateSwap(Position a, Position b) async {
    _currentPhase = BoardAnimationType.swap;
    _currentAnimations = [
      GemAnimation(type: BoardAnimationType.swap, from: a, to: b),
      GemAnimation(type: BoardAnimationType.swap, from: b, to: a),
    ];

    await _runAnimation(swapDuration, Curves.easeInOut);
    _currentPhase = BoardAnimationType.idle;
  }

  /// Animate a failed swap (bounce back).
  Future<void> animateSwapFailed(Position a, Position b) async {
    _currentPhase = BoardAnimationType.swapFailed;

    // First half: move towards target.
    _currentAnimations = [
      GemAnimation(type: BoardAnimationType.swapFailed, from: a, to: b),
      GemAnimation(type: BoardAnimationType.swapFailed, from: b, to: a),
    ];

    await _runAnimation(
      Duration(milliseconds: swapDuration.inMilliseconds ~/ 2),
      Curves.easeOut,
    );

    // Second half: bounce back.
    _currentAnimations = [
      GemAnimation(type: BoardAnimationType.swapFailed, from: b, to: a),
      GemAnimation(type: BoardAnimationType.swapFailed, from: a, to: b),
    ];

    await _runAnimation(
      Duration(milliseconds: swapDuration.inMilliseconds ~/ 2),
      Curves.bounceOut,
    );

    _currentPhase = BoardAnimationType.idle;
  }

  // ---------------------------------------------------------------------------
  // Match animation
  // ---------------------------------------------------------------------------

  /// Animate matched gems bursting.
  Future<void> animateMatch(Set<Position> matchedPositions) async {
    _currentPhase = BoardAnimationType.match;
    _currentAnimations = matchedPositions
        .map((pos) => GemAnimation(
              type: BoardAnimationType.match,
              from: pos,
              to: pos,
              scale: 1.0,
              opacity: 1.0,
            ))
        .toList();

    await _runAnimation(matchDuration, Curves.easeOut, onTick: (value) {
      _currentAnimations = matchedPositions
          .map((pos) => GemAnimation(
                type: BoardAnimationType.match,
                from: pos,
                to: pos,
                progress: value,
                scale: 1.0 + value * 0.3, // Grow slightly before disappearing.
                opacity: 1.0 - value, // Fade out.
              ))
          .toList();
    });

    _currentPhase = BoardAnimationType.idle;
  }

  // ---------------------------------------------------------------------------
  // Fall animation
  // ---------------------------------------------------------------------------

  /// Describes a gem falling from one row to another within the same column.
  Future<void> animateFall(List<FallMove> moves) async {
    if (moves.isEmpty) return;
    _currentPhase = BoardAnimationType.fall;

    _currentAnimations = moves
        .map((m) => GemAnimation(
              type: BoardAnimationType.fall,
              from: m.from,
              to: m.to,
            ))
        .toList();

    await _runAnimation(fallDuration, Curves.bounceOut);
    _currentPhase = BoardAnimationType.idle;
  }

  // ---------------------------------------------------------------------------
  // Spawn animation
  // ---------------------------------------------------------------------------

  /// Animate new gems spawning from the top.
  Future<void> animateSpawn(List<Position> spawnPositions) async {
    if (spawnPositions.isEmpty) return;
    _currentPhase = BoardAnimationType.spawn;

    _currentAnimations = spawnPositions
        .map((pos) => GemAnimation(
              type: BoardAnimationType.spawn,
              from: Position(-1, pos.col), // Start above the board.
              to: pos,
              opacity: 0.0,
            ))
        .toList();

    await _runAnimation(spawnDuration, Curves.easeOut, onTick: (value) {
      _currentAnimations = spawnPositions
          .map((pos) => GemAnimation(
                type: BoardAnimationType.spawn,
                from: Position(-1, pos.col),
                to: pos,
                progress: value,
                opacity: value, // Fade in.
              ))
          .toList();
    });

    _currentPhase = BoardAnimationType.idle;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _runAnimation(
    Duration duration,
    Curve curve, {
    void Function(double value)? onTick,
  }) async {
    _disposeCurrentController();

    final controller = AnimationController(
      vsync: _vsync,
      duration: duration,
    );
    _currentController = controller;

    final curved = CurvedAnimation(parent: controller, curve: curve);

    curved.addListener(() {
      final value = curved.value;
      if (onTick != null) {
        onTick(value);
      } else {
        _currentAnimations = _currentAnimations
            .map((a) => a.withProgress(value))
            .toList();
      }
      notifyListeners();
    });

    await controller.forward().orCancel.catchError((_) {});

    _currentAnimations = [];
    _disposeCurrentController();
  }

  void _disposeCurrentController() {
    _currentController?.dispose();
    _currentController = null;
  }

  /// Cancel any running animation.
  void cancelAnimation() {
    _currentController?.stop();
    _currentAnimations = [];
    _currentPhase = BoardAnimationType.idle;
    _disposeCurrentController();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeCurrentController();
    super.dispose();
  }
}

/// Describes a gem moving from one position to another during gravity.
class FallMove {
  final Position from;
  final Position to;

  const FallMove({required this.from, required this.to});

  /// Number of rows the gem falls.
  int get distance => to.row - from.row;

  @override
  String toString() => 'FallMove($from -> $to)';
}

import 'dart:async';

import '../models/board.dart';
import 'deadlock_detector.dart';

/// Manages hint display after player inactivity.
class HintTimer {
  final Duration inactivityDuration;
  final DeadlockDetector _deadlockDetector;

  Timer? _timer;
  Hint? _currentHint;
  void Function(Hint hint)? onHint;

  HintTimer({
    this.inactivityDuration = const Duration(seconds: 5),
    DeadlockDetector deadlockDetector = const DeadlockDetector(),
    this.onHint,
  }) : _deadlockDetector = deadlockDetector;

  /// The currently displayed hint, if any.
  Hint? get currentHint => _currentHint;

  /// Whether the timer is currently running.
  bool get isRunning => _timer?.isActive ?? false;

  /// Resets the inactivity timer (call on any player action).
  void resetTimer(Board board) {
    _cancelTimer();
    _currentHint = null;

    _timer = Timer(inactivityDuration, () {
      _showHint(board);
    });
  }

  /// Shows a hint immediately without waiting for the timer.
  Hint? showHintNow(Board board) {
    _cancelTimer();
    return _showHint(board);
  }

  /// Stops the timer and clears the current hint.
  void dispose() {
    _cancelTimer();
    _currentHint = null;
  }

  Hint? _showHint(Board board) {
    final hint = _deadlockDetector.findHint(board);
    _currentHint = hint;
    if (hint != null) {
      onHint?.call(hint);
    }
    return hint;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

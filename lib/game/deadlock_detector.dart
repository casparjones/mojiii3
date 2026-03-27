import 'dart:math';

import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';
import 'match_detector.dart';

/// A hint representing a valid swap move.
class Hint {
  final Position from;
  final Position to;

  const Hint({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hint &&
          runtimeType == other.runtimeType &&
          ((from == other.from && to == other.to) ||
              (from == other.to && to == other.from));

  @override
  int get hashCode {
    // Order-independent hash
    final a = from.hashCode;
    final b = to.hashCode;
    return a < b ? a ^ (b * 31) : b ^ (a * 31);
  }

  @override
  String toString() => 'Hint($from -> $to)';
}

/// Detects deadlocks (no valid moves) and finds hints (valid moves).
class DeadlockDetector {
  final MatchDetector _matchDetector;

  const DeadlockDetector(
      {MatchDetector matchDetector = const MatchDetector()})
      : _matchDetector = matchDetector;

  /// Returns true if no valid moves exist on the board (deadlock).
  bool isDeadlocked(Board board) {
    return findHint(board) == null;
  }

  /// Finds a single valid move (hint), or null if none exists.
  /// Checks all adjacent pairs for a swap that would produce a match.
  Hint? findHint(Board board) {
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final pos = Position(r, c);
        if (board.gemAt(pos) == null) continue;

        // Check right neighbor
        if (c + 1 < board.cols) {
          final right = Position(r, c + 1);
          if (board.gemAt(right) != null && _wouldMatch(board, pos, right)) {
            return Hint(from: pos, to: right);
          }
        }

        // Check down neighbor
        if (r + 1 < board.rows) {
          final down = Position(r + 1, c);
          if (board.gemAt(down) != null && _wouldMatch(board, pos, down)) {
            return Hint(from: pos, to: down);
          }
        }
      }
    }
    return null;
  }

  /// Finds all valid moves on the board.
  List<Hint> findAllHints(Board board) {
    final hints = <Hint>[];

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final pos = Position(r, c);
        if (board.gemAt(pos) == null) continue;

        // Check right neighbor
        if (c + 1 < board.cols) {
          final right = Position(r, c + 1);
          if (board.gemAt(right) != null && _wouldMatch(board, pos, right)) {
            hints.add(Hint(from: pos, to: right));
          }
        }

        // Check down neighbor
        if (r + 1 < board.rows) {
          final down = Position(r + 1, c);
          if (board.gemAt(down) != null && _wouldMatch(board, pos, down)) {
            hints.add(Hint(from: pos, to: down));
          }
        }
      }
    }

    return hints;
  }

  /// Checks if swapping [a] and [b] would produce a match.
  bool _wouldMatch(Board board, Position a, Position b) {
    board.swap(a, b);
    final matches = _matchDetector.findMatches(board);
    board.swap(a, b); // Revert
    return matches.isNotEmpty;
  }

  /// Shuffles the board until no deadlock exists and no immediate matches
  /// exist. Returns the number of shuffle attempts.
  int shuffleBoard(Board board, {Random? random}) {
    final rng = random ?? Random();
    var attempts = 0;
    const maxAttempts = 1000;

    while (attempts < maxAttempts) {
      attempts++;
      _fisherYatesShuffle(board, rng);

      // Check: no immediate matches AND at least one valid move
      final matches = _matchDetector.findMatches(board);
      if (matches.isEmpty && !isDeadlocked(board)) {
        return attempts;
      }
    }

    // Fallback: reinitialize
    _reinitialize(board, rng);
    return attempts;
  }

  void _fisherYatesShuffle(Board board, Random rng) {
    final gems = <Gem>[];
    final positions = <Position>[];

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final gem = board.gemAt(Position(r, c));
        if (gem != null) {
          gems.add(gem);
          positions.add(Position(r, c));
        }
      }
    }

    // Fisher-Yates shuffle
    for (var i = gems.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = gems[i];
      gems[i] = gems[j];
      gems[j] = temp;
    }

    // Place shuffled gems back
    for (var i = 0; i < positions.length; i++) {
      board.setGem(positions[i], gems[i]);
    }
  }

  void _reinitialize(Board board, Random rng) {
    final config = BoardConfig(rows: board.rows, cols: board.cols);
    final fresh = Board.initialize(config, random: rng);
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        board.setGem(Position(r, c), fresh.gemAt(Position(r, c)));
      }
    }
  }
}

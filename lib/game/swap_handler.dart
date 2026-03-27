import '../models/board.dart';
import '../models/position.dart';
import 'match_detector.dart';

/// Result of a swap attempt.
enum SwapResult {
  /// Swap produced matches - valid move.
  success,

  /// Swap did not produce matches - reverted.
  noMatch,

  /// Positions are not adjacent - rejected.
  notAdjacent,

  /// One or both positions are out of bounds or empty.
  invalid,
}

/// Handles gem swapping with validation.
class SwapHandler {
  final MatchDetector _matchDetector;

  const SwapHandler({MatchDetector matchDetector = const MatchDetector()})
      : _matchDetector = matchDetector;

  /// Attempts to swap gems at [a] and [b].
  ///
  /// Returns [SwapResult.success] if the swap produces at least one match.
  /// If no match is found, the swap is reverted and [SwapResult.noMatch] is
  /// returned. If the positions are not adjacent, returns
  /// [SwapResult.notAdjacent].
  SwapResult trySwap(Board board, Position a, Position b) {
    // Validate positions
    if (!board.isInBounds(a) || !board.isInBounds(b)) {
      return SwapResult.invalid;
    }
    if (board.gemAt(a) == null || board.gemAt(b) == null) {
      return SwapResult.invalid;
    }

    // Must be adjacent
    if (!a.isAdjacentTo(b)) {
      return SwapResult.notAdjacent;
    }

    // Perform swap
    board.swap(a, b);

    // Check for matches
    final matches = _matchDetector.findMatches(board);

    if (matches.isEmpty) {
      // Revert swap
      board.swap(a, b);
      return SwapResult.noMatch;
    }

    return SwapResult.success;
  }

  /// Performs a swap without validation (for testing or forced moves).
  void forceSwap(Board board, Position a, Position b) {
    board.swap(a, b);
  }
}

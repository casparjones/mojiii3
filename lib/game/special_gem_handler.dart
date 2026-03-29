import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';
import 'match_detector.dart';

/// Determines which special gem to create from a match and handles
/// special gem activation effects.
class SpecialGemHandler {
  const SpecialGemHandler();

  /// Determines the special gem to spawn for a given match.
  /// Returns null if no special gem should be created (match-3).
  /// The [swapPosition] is the position where the player initiated the swap
  /// (where the special gem will be placed).
  Gem? determineSpecialGem(Match match, {Position? swapPosition}) {
    final baseType = match.gemType;

    switch (match.shape) {
      case MatchShape.five:
        // 5 in a row => Rainbow gem
        return Gem(type: baseType, special: SpecialType.rainbow);

      case MatchShape.four:
        // 4 in a row => Striped gem (direction depends on match orientation)
        final positions = match.positions.toList();
        final isHorizontal = _isHorizontalRun(positions);
        return Gem(
          type: baseType,
          special: isHorizontal
              ? SpecialType.stripedVertical   // horizontal match creates vertical stripe
              : SpecialType.stripedHorizontal, // vertical match creates horizontal stripe
        );

      case MatchShape.lShape:
      case MatchShape.tShape:
        // L/T shape => Bomb
        return Gem(type: baseType, special: SpecialType.bomb);

      case MatchShape.three:
        // Regular match-3 => no special gem
        return null;
    }
  }

  /// Determines the best position to place a special gem.
  /// Prefers the swap position if it's part of the match, otherwise
  /// picks the center of the match.
  Position bestPlacement(Match match, {Position? swapPosition}) {
    if (swapPosition != null && match.positions.contains(swapPosition)) {
      return swapPosition;
    }
    // Pick center-ish position
    final sorted = match.positions.toList()
      ..sort((a, b) {
        final rowCmp = a.row.compareTo(b.row);
        return rowCmp != 0 ? rowCmp : a.col.compareTo(b.col);
      });
    return sorted[sorted.length ~/ 2];
  }

  /// Activates a special gem at [pos] on the board.
  /// Returns all positions that should be cleared by the activation.
  Set<Position> activate(Board board, Position pos) {
    final gem = board.gemAt(pos);
    if (gem == null) return {};

    switch (gem.special) {
      case SpecialType.none:
        return {pos};

      case SpecialType.stripedHorizontal:
        return _activateStripedHorizontal(board, pos);

      case SpecialType.stripedVertical:
        return _activateStripedVertical(board, pos);

      case SpecialType.bomb:
        return _activateBomb(board, pos);

      case SpecialType.crossBomb:
        return _activateCrossBomb(board, pos);

      case SpecialType.rainbow:
        return _activateRainbow(board, pos, gem.type);
    }
  }

  /// Striped horizontal: clears entire row.
  Set<Position> _activateStripedHorizontal(Board board, Position pos) {
    final result = <Position>{};
    for (var c = 0; c < board.cols; c++) {
      result.add(Position(pos.row, c));
    }
    return result;
  }

  /// Striped vertical: clears entire column.
  Set<Position> _activateStripedVertical(Board board, Position pos) {
    final result = <Position>{};
    for (var r = 0; r < board.rows; r++) {
      result.add(Position(r, pos.col));
    }
    return result;
  }

  /// Cross bomb: clears entire row AND entire column (cross shape).
  Set<Position> _activateCrossBomb(Board board, Position pos) {
    final result = <Position>{};
    // Entire row
    for (var c = 0; c < board.cols; c++) {
      result.add(Position(pos.row, c));
    }
    // Entire column
    for (var r = 0; r < board.rows; r++) {
      result.add(Position(r, pos.col));
    }
    return result;
  }

  /// Bomb: clears a 3x3 area around the position.
  Set<Position> _activateBomb(Board board, Position pos) {
    final result = <Position>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final p = Position(pos.row + dr, pos.col + dc);
        if (board.isInBounds(p)) {
          result.add(p);
        }
      }
    }
    return result;
  }

  /// Rainbow: clears all gems of the same base type on the board.
  Set<Position> _activateRainbow(
      Board board, Position pos, GemType targetType) {
    final result = <Position>{pos};
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final gem = board.gemAt(Position(r, c));
        if (gem != null && gem.type == targetType) {
          result.add(Position(r, c));
        }
      }
    }
    return result;
  }

  /// Checks if a set of positions forms a horizontal run.
  bool _isHorizontalRun(List<Position> positions) {
    if (positions.length < 2) return true;
    final firstRow = positions.first.row;
    return positions.every((p) => p.row == firstRow);
  }
}

import 'dart:math';

import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';

/// Handles gravity (gems falling down) and refilling empty cells.
class GravityHandler {
  final int gemTypeCount;
  final Random _random;

  GravityHandler({
    this.gemTypeCount = GemType.count,
    Random? random,
  }) : _random = random ?? Random();

  /// Applies gravity: moves gems down to fill empty cells.
  /// Returns the number of gems that moved.
  int applyGravity(Board board) {
    var moved = 0;

    for (var c = 0; c < board.cols; c++) {
      // Start from the bottom, find empty cells and pull gems down
      var writeRow = board.rows - 1;

      for (var r = board.rows - 1; r >= 0; r--) {
        final gem = board.gemAt(Position(r, c));
        if (gem != null) {
          if (r != writeRow) {
            board.setGem(Position(writeRow, c), gem);
            board.setGem(Position(r, c), null);
            moved++;
          }
          writeRow--;
        }
      }
    }

    return moved;
  }

  /// Fills empty (null) cells from the top with new random gems.
  /// Returns the number of gems spawned.
  int refill(Board board) {
    final availableTypes = GemType.values.sublist(0, gemTypeCount);
    var spawned = 0;

    for (var c = 0; c < board.cols; c++) {
      for (var r = 0; r < board.rows; r++) {
        if (board.gemAt(Position(r, c)) == null) {
          final type = availableTypes[_random.nextInt(availableTypes.length)];
          board.setGem(Position(r, c), Gem(type: type));
          spawned++;
        }
      }
    }

    return spawned;
  }
}

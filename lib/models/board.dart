import 'dart:math';

import 'gem_type.dart';
import 'position.dart';

/// Configuration for a game board level.
class BoardConfig {
  final int rows;
  final int cols;
  final int gemTypeCount;

  const BoardConfig({
    this.rows = 8,
    this.cols = 8,
    this.gemTypeCount = 6,
  })  : assert(rows > 0),
        assert(cols > 0),
        assert(gemTypeCount >= 3 && gemTypeCount <= GemType.count);
}

/// The game board holding a grid of gems.
class Board {
  final int rows;
  final int cols;
  final List<List<Gem?>> _grid;

  Board._({
    required this.rows,
    required this.cols,
    required List<List<Gem?>> grid,
  }) : _grid = grid;

  /// Creates a board filled with the given grid data (for testing).
  factory Board.fromGrid(List<List<Gem?>> grid) {
    final rows = grid.length;
    final cols = grid.isEmpty ? 0 : grid[0].length;
    // Deep copy
    final copy = List.generate(
      rows,
      (r) => List<Gem?>.from(grid[r]),
    );
    return Board._(rows: rows, cols: cols, grid: copy);
  }

  /// Creates a new board initialized with random gems, ensuring no
  /// immediate matches of 3 or more exist.
  factory Board.initialize(BoardConfig config, {Random? random}) {
    final rng = random ?? Random();
    final availableTypes = GemType.values.sublist(0, config.gemTypeCount);
    final grid = List.generate(
      config.rows,
      (_) => List<Gem?>.filled(config.cols, null),
    );

    for (var r = 0; r < config.rows; r++) {
      for (var c = 0; c < config.cols; c++) {
        final forbidden = <GemType>{};

        // Check horizontal: if the two gems to the left are the same type,
        // forbid that type.
        if (c >= 2) {
          final g1 = grid[r][c - 1];
          final g2 = grid[r][c - 2];
          if (g1 != null && g2 != null && g1.type == g2.type) {
            forbidden.add(g1.type);
          }
        }

        // Check vertical: if the two gems above are the same type,
        // forbid that type.
        if (r >= 2) {
          final g1 = grid[r - 1][c];
          final g2 = grid[r - 2][c];
          if (g1 != null && g2 != null && g1.type == g2.type) {
            forbidden.add(g1.type);
          }
        }

        final allowed =
            availableTypes.where((t) => !forbidden.contains(t)).toList();

        // Should always have at least one allowed type when gemTypeCount >= 3.
        final chosen = allowed[rng.nextInt(allowed.length)];
        grid[r][c] = Gem(type: chosen);
      }
    }

    return Board._(rows: config.rows, cols: config.cols, grid: grid);
  }

  /// Returns the gem at [pos], or null if empty or out of bounds.
  Gem? gemAt(Position pos) {
    if (!isInBounds(pos)) return null;
    return _grid[pos.row][pos.col];
  }

  /// Sets the gem at [pos]. Does nothing if out of bounds.
  void setGem(Position pos, Gem? gem) {
    if (!isInBounds(pos)) return;
    _grid[pos.row][pos.col] = gem;
  }

  /// Returns true if [pos] is within the board boundaries.
  bool isInBounds(Position pos) {
    return pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols;
  }

  /// Swaps the gems at positions [a] and [b].
  void swap(Position a, Position b) {
    final temp = _grid[a.row][a.col];
    _grid[a.row][a.col] = _grid[b.row][b.col];
    _grid[b.row][b.col] = temp;
  }

  /// Removes gems at the given positions (sets them to null).
  void removeGems(Set<Position> positions) {
    for (final pos in positions) {
      setGem(pos, null);
    }
  }

  /// Returns true if there are any null cells in the grid.
  bool get hasEmptyCells {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_grid[r][c] == null) return true;
      }
    }
    return false;
  }

  /// Creates a deep copy of this board.
  Board copy() {
    final gridCopy = List.generate(
      rows,
      (r) => List<Gem?>.from(_grid[r]),
    );
    return Board._(rows: rows, cols: cols, grid: gridCopy);
  }

  /// Checks if the board has any matches of 3+ in a row/column.
  /// Returns all positions involved in matches.
  Set<Position> findAllMatches() {
    final matched = <Position>{};

    // Horizontal matches
    for (var r = 0; r < rows; r++) {
      var runStart = 0;
      for (var c = 1; c <= cols; c++) {
        final current = c < cols ? _grid[r][c] : null;
        final prev = _grid[r][runStart];
        if (current != null && prev != null && current.type == prev.type) {
          continue;
        }
        final runLength = c - runStart;
        if (runLength >= 3 && prev != null) {
          for (var i = runStart; i < c; i++) {
            matched.add(Position(r, i));
          }
        }
        runStart = c;
      }
    }

    // Vertical matches
    for (var c = 0; c < cols; c++) {
      var runStart = 0;
      for (var r = 1; r <= rows; r++) {
        final current = r < rows ? _grid[r][c] : null;
        final prev = _grid[runStart][c];
        if (current != null && prev != null && current.type == prev.type) {
          continue;
        }
        final runLength = r - runStart;
        if (runLength >= 3 && prev != null) {
          for (var i = runStart; i < r; i++) {
            matched.add(Position(i, c));
          }
        }
        runStart = r;
      }
    }

    return matched;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final gem = _grid[r][c];
        if (gem == null) {
          buf.write('.');
        } else {
          buf.write(gem.type.name[0].toUpperCase());
        }
        if (c < cols - 1) buf.write(' ');
      }
      if (r < rows - 1) buf.writeln();
    }
    return buf.toString();
  }
}

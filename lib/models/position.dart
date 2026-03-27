/// A position on the game board.
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Returns true if this position is adjacent (up/down/left/right) to [other].
  bool isAdjacentTo(Position other) {
    final dr = (row - other.row).abs();
    final dc = (col - other.col).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  Position get up => Position(row - 1, col);
  Position get down => Position(row + 1, col);
  Position get left => Position(row, col - 1);
  Position get right => Position(row, col + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode * 31);

  @override
  String toString() => 'Position($row, $col)';
}

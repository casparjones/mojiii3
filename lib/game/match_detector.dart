import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';

/// The shape/pattern of a detected match.
enum MatchShape {
  /// 3 in a row/column
  three,

  /// 4 in a row/column
  four,

  /// 5 in a row/column
  five,

  /// L-shape (3+3 sharing a corner)
  lShape,

  /// T-shape (3+3 sharing a middle cell)
  tShape,
}

/// A detected match on the board.
class Match {
  final Set<Position> positions;
  final GemType gemType;
  final MatchShape shape;

  const Match({
    required this.positions,
    required this.gemType,
    required this.shape,
  });

  @override
  String toString() => 'Match($shape, $gemType, ${positions.length} cells)';
}

/// Detects matches on the board with pattern classification.
class MatchDetector {
  const MatchDetector();

  /// Finds all matches on the board and classifies their shapes.
  List<Match> findMatches(Board board) {
    final horizontalRuns = _findRuns(board, horizontal: true);
    final verticalRuns = _findRuns(board, horizontal: false);

    // Combine runs into classified matches
    return _classifyMatches(horizontalRuns, verticalRuns);
  }

  /// Returns all positions involved in any match.
  Set<Position> findAllMatchPositions(Board board) {
    final matches = findMatches(board);
    final result = <Position>{};
    for (final match in matches) {
      result.addAll(match.positions);
    }
    return result;
  }

  /// Find runs of 3+ same-type gems in one direction.
  List<_Run> _findRuns(Board board, {required bool horizontal}) {
    final runs = <_Run>[];
    final outerLimit = horizontal ? board.rows : board.cols;
    final innerLimit = horizontal ? board.cols : board.rows;

    for (var outer = 0; outer < outerLimit; outer++) {
      var runStart = 0;
      for (var inner = 1; inner <= innerLimit; inner++) {
        final currentPos = horizontal
            ? Position(outer, inner < innerLimit ? inner : -1)
            : Position(inner < innerLimit ? inner : -1, outer);
        final startPos =
            horizontal ? Position(outer, runStart) : Position(runStart, outer);

        final currentGem =
            inner < innerLimit ? board.gemAt(currentPos) : null;
        final startGem = board.gemAt(startPos);

        if (currentGem != null &&
            startGem != null &&
            currentGem.type == startGem.type) {
          continue;
        }

        final runLength = inner - runStart;
        if (runLength >= 3 && startGem != null) {
          final positions = <Position>{};
          for (var i = runStart; i < inner; i++) {
            positions.add(horizontal ? Position(outer, i) : Position(i, outer));
          }
          runs.add(_Run(
            positions: positions,
            gemType: startGem.type,
            horizontal: horizontal,
            length: runLength,
          ));
        }
        runStart = inner;
      }
    }

    return runs;
  }

  /// Classify runs into match shapes by checking intersections.
  List<Match> _classifyMatches(
      List<_Run> horizontalRuns, List<_Run> verticalRuns) {
    final matches = <Match>[];
    final usedH = <int>{};
    final usedV = <int>{};

    // Try to pair horizontal and vertical runs into L/T shapes
    for (var hi = 0; hi < horizontalRuns.length; hi++) {
      for (var vi = 0; vi < verticalRuns.length; vi++) {
        if (usedH.contains(hi) || usedV.contains(vi)) continue;

        final hRun = horizontalRuns[hi];
        final vRun = verticalRuns[vi];

        if (hRun.gemType != vRun.gemType) continue;

        // Check if the runs share exactly one position
        final shared = hRun.positions.intersection(vRun.positions);
        if (shared.isEmpty) continue;

        // They intersect - determine shape
        final combined = hRun.positions.union(vRun.positions);
        final shape = _classifyCombined(hRun, vRun, shared.first);

        matches.add(Match(
          positions: combined,
          gemType: hRun.gemType,
          shape: shape,
        ));
        usedH.add(hi);
        usedV.add(vi);
      }
    }

    // Add remaining unpaired horizontal runs
    for (var hi = 0; hi < horizontalRuns.length; hi++) {
      if (usedH.contains(hi)) continue;
      final run = horizontalRuns[hi];
      matches.add(Match(
        positions: run.positions,
        gemType: run.gemType,
        shape: _shapeFromLength(run.length),
      ));
    }

    // Add remaining unpaired vertical runs
    for (var vi = 0; vi < verticalRuns.length; vi++) {
      if (usedV.contains(vi)) continue;
      final run = verticalRuns[vi];
      matches.add(Match(
        positions: run.positions,
        gemType: run.gemType,
        shape: _shapeFromLength(run.length),
      ));
    }

    return matches;
  }

  MatchShape _classifyCombined(_Run hRun, _Run vRun, Position intersection) {
    // T-shape: intersection is at the middle of one of the runs
    final hPositions = hRun.positions.toList()
      ..sort((a, b) => a.col.compareTo(b.col));
    final vPositions = vRun.positions.toList()
      ..sort((a, b) => a.row.compareTo(b.row));

    final hIsMiddle =
        hPositions.length >= 3 &&
        intersection != hPositions.first &&
        intersection != hPositions.last;
    final vIsMiddle =
        vPositions.length >= 3 &&
        intersection != vPositions.first &&
        intersection != vPositions.last;

    // T-shape: intersection is at middle of at least one run
    if (hIsMiddle || vIsMiddle) {
      return MatchShape.tShape;
    }

    // L-shape: intersection is at a corner (end of both runs)
    return MatchShape.lShape;
  }

  MatchShape _shapeFromLength(int length) {
    if (length >= 5) return MatchShape.five;
    if (length >= 4) return MatchShape.four;
    return MatchShape.three;
  }
}

class _Run {
  final Set<Position> positions;
  final GemType gemType;
  final bool horizontal;
  final int length;

  const _Run({
    required this.positions,
    required this.gemType,
    required this.horizontal,
    required this.length,
  });
}

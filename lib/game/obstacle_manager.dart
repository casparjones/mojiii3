import 'dart:math';

import '../models/position.dart';
import 'level_generator.dart';

/// Runtime state of an obstacle on the board.
class Obstacle {
  final ObstacleType type;
  int hitPoints;
  final int maxHitPoints;

  Obstacle({
    required this.type,
    required this.hitPoints,
  }) : maxHitPoints = hitPoints;

  /// Whether this obstacle has been fully destroyed.
  bool get isDestroyed => hitPoints <= 0;

  /// Whether this obstacle blocks gem placement in its cell.
  bool get blocksCell => type == ObstacleType.stone && !isDestroyed;

  /// Whether gems can fall through this cell.
  bool get blocksFalling => blocksCell;

  /// Whether a gem underneath is locked (can't be swapped).
  bool get locksGem =>
      !isDestroyed && (type == ObstacleType.chain || type == ObstacleType.ice);

  /// Whether this obstacle spreads to adjacent cells.
  bool get spreads => type == ObstacleType.slime && !isDestroyed;

  /// Apply a hit to this obstacle. Returns true if destroyed.
  bool hit() {
    if (isDestroyed) return false;
    hitPoints--;
    return isDestroyed;
  }

  /// Create a copy of this obstacle.
  Obstacle copy() => Obstacle(type: type, hitPoints: hitPoints);

  @override
  String toString() {
    final hp = isDestroyed ? 'destroyed' : '$hitPoints/$maxHitPoints';
    return 'Obstacle(${type.name}, $hp)';
  }
}

/// Result of processing obstacles after matches.
class ObstacleProcessResult {
  /// Positions where obstacles were destroyed.
  final Set<Position> destroyed;

  /// Positions where obstacles were damaged but not destroyed.
  final Set<Position> damaged;

  /// Positions where slime spread to.
  final Set<Position> slimeSpread;

  /// Total obstacles destroyed this step.
  int get destroyedCount => destroyed.length;

  const ObstacleProcessResult({
    this.destroyed = const {},
    this.damaged = const {},
    this.slimeSpread = const {},
  });
}

/// Manages obstacles on the game board.
class ObstacleManager {
  final Map<Position, Obstacle> _obstacles = {};

  /// All current obstacles.
  Map<Position, Obstacle> get obstacles => Map.unmodifiable(_obstacles);

  /// Number of active (non-destroyed) obstacles.
  int get activeCount => _obstacles.values.where((o) => !o.isDestroyed).length;

  /// Total obstacles (including destroyed).
  int get totalCount => _obstacles.length;

  /// Whether a position has an active obstacle.
  bool hasObstacle(Position pos) =>
      _obstacles.containsKey(pos) && !_obstacles[pos]!.isDestroyed;

  /// Get the obstacle at a position, if any.
  Obstacle? obstacleAt(Position pos) => _obstacles[pos];

  /// Whether a position blocks gem placement.
  bool blocksCell(Position pos) {
    final obs = _obstacles[pos];
    return obs != null && obs.blocksCell;
  }

  /// Whether a gem at this position is locked (can't be swapped).
  bool isLocked(Position pos) {
    final obs = _obstacles[pos];
    return obs != null && obs.locksGem;
  }

  /// Initialize obstacles from level config placements.
  void initialize(List<ObstaclePlacement> placements) {
    _obstacles.clear();
    for (final p in placements) {
      _obstacles[p.position] = Obstacle(
        type: p.type,
        hitPoints: p.hitPoints,
      );
    }
  }

  /// Place a single obstacle.
  void place(Position pos, ObstacleType type, {int hitPoints = 1}) {
    _obstacles[pos] = Obstacle(type: type, hitPoints: hitPoints);
  }

  /// Process obstacles after matches have been found.
  ///
  /// - Ice: destroyed by adjacent matches
  /// - Chain: destroyed when the gem at its position is matched
  /// - Stone: damaged by adjacent matches (2 hits to destroy)
  /// - Slime: destroyed by adjacent matches
  ObstacleProcessResult processMatches(
    Set<Position> matchedPositions,
    int boardRows,
    int boardCols,
  ) {
    final destroyed = <Position>{};
    final damaged = <Position>{};

    // Collect all positions adjacent to matches.
    final adjacentToMatch = <Position>{};
    for (final pos in matchedPositions) {
      for (final adj in _adjacentPositions(pos, boardRows, boardCols)) {
        adjacentToMatch.add(adj);
      }
    }

    for (final entry in _obstacles.entries.toList()) {
      final pos = entry.key;
      final obs = entry.value;
      if (obs.isDestroyed) continue;

      switch (obs.type) {
        case ObstacleType.ice:
          // Destroyed by adjacent match.
          if (adjacentToMatch.contains(pos) || matchedPositions.contains(pos)) {
            if (obs.hit()) {
              destroyed.add(pos);
            } else {
              damaged.add(pos);
            }
          }
          break;

        case ObstacleType.chain:
          // Destroyed when its gem is directly matched.
          if (matchedPositions.contains(pos)) {
            obs.hit();
            destroyed.add(pos);
          }
          break;

        case ObstacleType.stone:
          // Damaged by adjacent matches.
          if (adjacentToMatch.contains(pos)) {
            if (obs.hit()) {
              destroyed.add(pos);
            } else {
              damaged.add(pos);
            }
          }
          break;

        case ObstacleType.slime:
          // Destroyed by adjacent matches.
          if (adjacentToMatch.contains(pos) || matchedPositions.contains(pos)) {
            obs.hit();
            destroyed.add(pos);
          }
          break;
      }
    }

    return ObstacleProcessResult(
      destroyed: destroyed,
      damaged: damaged,
    );
  }

  /// Process slime spreading. Called after each turn.
  /// Slime spreads to one random adjacent empty cell per slime cell.
  ObstacleProcessResult processSlimeSpread(
    int boardRows,
    int boardCols, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final slimeSpread = <Position>{};

    final slimeCells = _obstacles.entries
        .where((e) => e.value.type == ObstacleType.slime && !e.value.isDestroyed)
        .map((e) => e.key)
        .toList();

    for (final pos in slimeCells) {
      final adjacent = _adjacentPositions(pos, boardRows, boardCols)
          .where((p) => !_obstacles.containsKey(p))
          .toList();

      if (adjacent.isNotEmpty) {
        final target = adjacent[rng.nextInt(adjacent.length)];
        place(target, ObstacleType.slime);
        slimeSpread.add(target);
      }
    }

    return ObstacleProcessResult(slimeSpread: slimeSpread);
  }

  /// Remove destroyed obstacles from the map.
  void cleanupDestroyed() {
    _obstacles.removeWhere((_, obs) => obs.isDestroyed);
  }

  /// Clear all obstacles.
  void clear() {
    _obstacles.clear();
  }

  List<Position> _adjacentPositions(Position pos, int rows, int cols) {
    final result = <Position>[];
    if (pos.row > 0) result.add(pos.up);
    if (pos.row < rows - 1) result.add(pos.down);
    if (pos.col > 0) result.add(pos.left);
    if (pos.col < cols - 1) result.add(pos.right);
    return result;
  }
}

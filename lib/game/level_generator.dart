import 'dart:math';

import '../models/gem_type.dart';
import '../models/position.dart';

/// The type of objective for a level.
enum LevelObjectiveType {
  /// Reach a target score within move limit.
  score,

  /// Collect a certain number of specific gem colors.
  collectGems,

  /// Destroy a number of obstacles.
  destroyObstacles,
}

/// The time constraint type.
enum LevelConstraintType {
  /// Limited number of moves.
  moves,

  /// Time limit in seconds.
  timed,
}

/// An obstacle placed on the board.
enum ObstacleType {
  /// Ice: one hit to destroy, gem underneath.
  ice,

  /// Stone: blocks the cell, 2 hits to destroy.
  stone,

  /// Chain: gem is locked, must match to free.
  chain,

  /// Slime: spreads each turn, must be matched adjacent.
  slime,
}

/// Defines an obstacle at a specific position.
class ObstaclePlacement {
  final Position position;
  final ObstacleType type;
  final int hitPoints;

  const ObstaclePlacement({
    required this.position,
    required this.type,
    this.hitPoints = 1,
  });

  @override
  String toString() => 'Obstacle(${type.name} at $position, hp: $hitPoints)';
}

/// Objective for a level.
class LevelObjective {
  final LevelObjectiveType type;

  /// Target score (for score objective).
  final int targetScore;

  /// Target gem counts (for collectGems objective).
  final Map<GemType, int> targetGems;

  /// Target obstacles to destroy (for destroyObstacles objective).
  final int targetObstacles;

  /// 2-star score threshold.
  final int twoStarScore;

  /// 3-star score threshold.
  final int threeStarScore;

  const LevelObjective({
    required this.type,
    this.targetScore = 0,
    this.targetGems = const {},
    this.targetObstacles = 0,
    this.twoStarScore = 0,
    this.threeStarScore = 0,
  });
}

/// Complete level configuration generated from a level number.
class LevelConfig {
  final int levelNumber;
  final int rows;
  final int cols;
  final int gemTypeCount;
  final LevelObjective objective;
  final LevelConstraintType constraintType;
  final int moveLimit;
  final int timeLimitSeconds;
  final List<ObstaclePlacement> obstacles;

  /// Difficulty factor (0.0 = easiest, 1.0 = hardest).
  final double difficulty;

  const LevelConfig({
    required this.levelNumber,
    required this.rows,
    required this.cols,
    required this.gemTypeCount,
    required this.objective,
    required this.constraintType,
    required this.moveLimit,
    this.timeLimitSeconds = 0,
    this.obstacles = const [],
    required this.difficulty,
  });
}

/// Procedural level generator that creates deterministic levels from a number.
class LevelGenerator {
  const LevelGenerator();

  /// Generate a level config from a level number.
  /// Same level number always produces the same config.
  LevelConfig generate(int levelNumber) {
    // Deterministic random based on level number.
    final rng = Random(levelNumber * 7919 + 31337);

    final difficulty = _calculateDifficulty(levelNumber);
    final boardSize = _calculateBoardSize(levelNumber, difficulty);
    final gemTypeCount = _calculateGemTypeCount(levelNumber, difficulty);
    final constraintType = _calculateConstraintType(levelNumber, rng);
    final moveLimit = _calculateMoveLimit(levelNumber, difficulty, constraintType);
    final timeLimitSeconds = constraintType == LevelConstraintType.timed
        ? _calculateTimeLimit(levelNumber, difficulty)
        : 0;
    final objective = _calculateObjective(levelNumber, difficulty, rng, gemTypeCount);
    final obstacles = _generateObstacles(
      levelNumber, difficulty, rng, boardSize[0], boardSize[1],
    );

    return LevelConfig(
      levelNumber: levelNumber,
      rows: boardSize[0],
      cols: boardSize[1],
      gemTypeCount: gemTypeCount,
      objective: objective,
      constraintType: constraintType,
      moveLimit: moveLimit,
      timeLimitSeconds: timeLimitSeconds,
      obstacles: obstacles,
      difficulty: difficulty,
    );
  }

  /// Difficulty scales from 0.0 to 1.0 over the first 200 levels,
  /// then stays at 1.0.
  double _calculateDifficulty(int level) {
    return (level / 200.0).clamp(0.0, 1.0);
  }

  /// Board size: starts at 7x7, grows to 9x9 at high levels.
  List<int> _calculateBoardSize(int level, double difficulty) {
    if (level <= 5) return [7, 7];
    if (level <= 20) return [8, 7];
    if (level <= 50) return [8, 8];
    if (level <= 100) return [9, 8];
    return [9, 9];
  }

  /// Gem types: starts with 4, scales up to 6.
  int _calculateGemTypeCount(int level, double difficulty) {
    if (level <= 3) return 4;
    if (level <= 10) return 5;
    return 6;
  }

  /// Most levels are move-based; timed levels appear occasionally.
  LevelConstraintType _calculateConstraintType(int level, Random rng) {
    if (level < 10) return LevelConstraintType.moves;
    // Every 10th level starting from 10 is timed.
    if (level % 10 == 0) return LevelConstraintType.timed;
    return LevelConstraintType.moves;
  }

  /// Move limit decreases with difficulty.
  int _calculateMoveLimit(
    int level,
    double difficulty,
    LevelConstraintType constraint,
  ) {
    if (constraint == LevelConstraintType.timed) {
      return 0; // No move limit for timed levels.
    }
    // Starts generous (30), decreases to minimum (15).
    final base = 30 - (difficulty * 15).round();
    return base.clamp(15, 30);
  }

  /// Time limit for timed levels.
  int _calculateTimeLimit(int level, double difficulty) {
    // Starts at 120s, decreases to 60s.
    final base = 120 - (difficulty * 60).round();
    return base.clamp(60, 120);
  }

  /// Generate level objective.
  LevelObjective _calculateObjective(
    int level,
    double difficulty,
    Random rng,
    int gemTypeCount,
  ) {
    final type = _selectObjectiveType(level, rng);

    switch (type) {
      case LevelObjectiveType.score:
        final target = _calculateTargetScore(level, difficulty);
        return LevelObjective(
          type: LevelObjectiveType.score,
          targetScore: target,
          twoStarScore: (target * 1.5).round(),
          threeStarScore: (target * 2.5).round(),
        );

      case LevelObjectiveType.collectGems:
        final gemCount = 2 + (difficulty * 3).round();
        final availableTypes = GemType.values.sublist(0, gemTypeCount);
        final targets = <GemType, int>{};
        for (int i = 0; i < gemCount.clamp(1, availableTypes.length); i++) {
          final type = availableTypes[rng.nextInt(availableTypes.length)];
          targets[type] = (targets[type] ?? 0) + (10 + (difficulty * 20).round());
        }
        final totalTarget = targets.values.fold(0, (a, b) => a + b);
        return LevelObjective(
          type: LevelObjectiveType.collectGems,
          targetGems: targets,
          targetScore: totalTarget * 50,
          twoStarScore: totalTarget * 75,
          threeStarScore: totalTarget * 125,
        );

      case LevelObjectiveType.destroyObstacles:
        final target = (5 + difficulty * 15).round();
        return LevelObjective(
          type: LevelObjectiveType.destroyObstacles,
          targetObstacles: target,
          targetScore: target * 100,
          twoStarScore: target * 150,
          threeStarScore: target * 250,
        );
    }
  }

  LevelObjectiveType _selectObjectiveType(int level, Random rng) {
    if (level <= 5) return LevelObjectiveType.score;
    if (level <= 10) {
      return level % 2 == 0
          ? LevelObjectiveType.collectGems
          : LevelObjectiveType.score;
    }
    // After level 10, mix all types.
    final roll = rng.nextInt(100);
    if (roll < 40) return LevelObjectiveType.score;
    if (roll < 70) return LevelObjectiveType.collectGems;
    return LevelObjectiveType.destroyObstacles;
  }

  int _calculateTargetScore(int level, double difficulty) {
    // Base target scales with level.
    final base = 500 + level * 100;
    final scaled = (base * (1.0 + difficulty * 0.5)).round();
    // Round to nearest 100.
    return ((scaled + 50) ~/ 100) * 100;
  }

  /// Generate obstacle placements based on difficulty.
  List<ObstaclePlacement> _generateObstacles(
    int level,
    double difficulty,
    Random rng,
    int rows,
    int cols,
  ) {
    if (level < 8) return []; // No obstacles in early levels.

    final obstacles = <ObstaclePlacement>[];
    final usedPositions = <Position>{};
    final obstacleCount = (difficulty * 12).round().clamp(1, 15);
    final availableTypes = _availableObstacleTypes(level);

    for (int i = 0; i < obstacleCount; i++) {
      // Don't place in top 2 rows (spawn area) or corners.
      int attempts = 0;
      while (attempts < 20) {
        final row = 2 + rng.nextInt(rows - 2);
        final col = rng.nextInt(cols);
        final pos = Position(row, col);

        if (!usedPositions.contains(pos)) {
          usedPositions.add(pos);
          final type = availableTypes[rng.nextInt(availableTypes.length)];
          final hp = type == ObstacleType.stone ? 2 : 1;
          obstacles.add(ObstaclePlacement(
            position: pos,
            type: type,
            hitPoints: hp,
          ));
          break;
        }
        attempts++;
      }
    }

    return obstacles;
  }

  List<ObstacleType> _availableObstacleTypes(int level) {
    if (level < 15) return [ObstacleType.ice];
    if (level < 30) return [ObstacleType.ice, ObstacleType.chain];
    if (level < 50) {
      return [ObstacleType.ice, ObstacleType.chain, ObstacleType.stone];
    }
    return ObstacleType.values;
  }
}

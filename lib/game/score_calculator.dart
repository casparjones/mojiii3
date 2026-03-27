import 'match_detector.dart';

/// Configuration for score and coin calculations.
class ScoreConfig {
  /// Base points per gem in a match-3.
  final int basePoints;

  /// Bonus points per additional gem beyond 3.
  final int bonusPerExtraGem;

  /// Multiplier for each cascade level (level 1 = 1.0, level 2 = 1.0 + this, etc.)
  final double cascadeMultiplierStep;

  /// Extra multiplier for special match shapes.
  final double lShapeBonus;
  final double tShapeBonus;
  final double match4Bonus;
  final double match5Bonus;

  /// Percentage of score converted to coins.
  final double coinConversionRate;

  /// Bonus coins for completing a level with 3 stars.
  final int threeStarBonusCoins;

  /// Bonus coins for completing a level with 2 stars.
  final int twoStarBonusCoins;

  /// Daily login coin reward.
  final int dailyLoginCoins;

  /// Multiplier for consecutive day login streak.
  final double streakMultiplier;

  /// Maximum streak multiplier.
  final double maxStreakMultiplier;

  const ScoreConfig({
    this.basePoints = 50,
    this.bonusPerExtraGem = 25,
    this.cascadeMultiplierStep = 0.5,
    this.lShapeBonus = 1.5,
    this.tShapeBonus = 2.0,
    this.match4Bonus = 1.5,
    this.match5Bonus = 3.0,
    this.coinConversionRate = 0.01,
    this.threeStarBonusCoins = 50,
    this.twoStarBonusCoins = 25,
    this.dailyLoginCoins = 100,
    this.streakMultiplier = 0.1,
    this.maxStreakMultiplier = 3.0,
  });
}

/// Result of scoring a single match.
class MatchScore {
  final int baseScore;
  final double shapeMultiplier;
  final double cascadeMultiplier;
  final int totalScore;
  final int gemsMatched;
  final MatchShape shape;

  const MatchScore({
    required this.baseScore,
    required this.shapeMultiplier,
    required this.cascadeMultiplier,
    required this.totalScore,
    required this.gemsMatched,
    required this.shape,
  });

  @override
  String toString() =>
      'MatchScore($totalScore pts, ${shape.name}, x${cascadeMultiplier.toStringAsFixed(1)} cascade)';
}

/// Result of scoring a complete cascade step (one round of matches).
class CascadeStepScore {
  final List<MatchScore> matchScores;
  final int cascadeLevel;
  final int stepTotal;

  const CascadeStepScore({
    required this.matchScores,
    required this.cascadeLevel,
    required this.stepTotal,
  });
}

/// Result of scoring an entire move (all cascades).
class MoveScore {
  final List<CascadeStepScore> stepScores;
  final int totalScore;
  final int totalGems;
  final int coinsEarned;
  final int maxCascade;

  const MoveScore({
    required this.stepScores,
    required this.totalScore,
    required this.totalGems,
    required this.coinsEarned,
    required this.maxCascade,
  });
}

/// Result of level completion scoring.
class LevelScore {
  final int moveScore;
  final int movesRemaining;
  final int remainingMovesBonus;
  final int totalScore;
  final int stars;
  final int coinsEarned;

  const LevelScore({
    required this.moveScore,
    required this.movesRemaining,
    required this.remainingMovesBonus,
    required this.totalScore,
    required this.stars,
    required this.coinsEarned,
  });
}

/// Calculates scores, coins, and multipliers.
class ScoreCalculator {
  final ScoreConfig config;

  const ScoreCalculator({this.config = const ScoreConfig()});

  /// Score a single match.
  MatchScore scoreMatch(Match match, {int cascadeLevel = 1}) {
    final gemCount = match.positions.length;
    final baseScore =
        config.basePoints + (gemCount - 3) * config.bonusPerExtraGem;

    final shapeMultiplier = _shapeMultiplier(match.shape);
    final cascadeMultiplier =
        1.0 + (cascadeLevel - 1) * config.cascadeMultiplierStep;

    final totalScore =
        (baseScore * shapeMultiplier * cascadeMultiplier).round();

    return MatchScore(
      baseScore: baseScore,
      shapeMultiplier: shapeMultiplier,
      cascadeMultiplier: cascadeMultiplier,
      totalScore: totalScore,
      gemsMatched: gemCount,
      shape: match.shape,
    );
  }

  /// Score all matches in a cascade step.
  CascadeStepScore scoreCascadeStep(
    List<Match> matches, {
    required int cascadeLevel,
  }) {
    final matchScores = matches
        .map((m) => scoreMatch(m, cascadeLevel: cascadeLevel))
        .toList();

    final stepTotal = matchScores.fold(0, (sum, ms) => sum + ms.totalScore);

    return CascadeStepScore(
      matchScores: matchScores,
      cascadeLevel: cascadeLevel,
      stepTotal: stepTotal,
    );
  }

  /// Score an entire move with multiple cascade steps.
  MoveScore scoreMove(List<List<Match>> cascadeSteps) {
    final stepScores = <CascadeStepScore>[];
    int totalScore = 0;
    int totalGems = 0;

    for (int i = 0; i < cascadeSteps.length; i++) {
      final step = scoreCascadeStep(
        cascadeSteps[i],
        cascadeLevel: i + 1,
      );
      stepScores.add(step);
      totalScore += step.stepTotal;

      for (final ms in step.matchScores) {
        totalGems += ms.gemsMatched;
      }
    }

    final coinsEarned = (totalScore * config.coinConversionRate).round();

    return MoveScore(
      stepScores: stepScores,
      totalScore: totalScore,
      totalGems: totalGems,
      coinsEarned: coinsEarned,
      maxCascade: cascadeSteps.length,
    );
  }

  /// Calculate level completion score.
  LevelScore scoreLevelComplete({
    required int totalMoveScore,
    required int movesRemaining,
    required int targetScore,
    required int twoStarScore,
    required int threeStarScore,
  }) {
    // Remaining moves bonus: each remaining move is worth some points.
    final remainingMovesBonus = movesRemaining * config.basePoints * 2;
    final totalScore = totalMoveScore + remainingMovesBonus;

    // Determine stars.
    int stars;
    if (totalScore >= threeStarScore) {
      stars = 3;
    } else if (totalScore >= twoStarScore) {
      stars = 2;
    } else if (totalScore >= targetScore) {
      stars = 1;
    } else {
      stars = 0;
    }

    // Calculate coins.
    int coinsEarned = (totalScore * config.coinConversionRate).round();
    if (stars == 3) {
      coinsEarned += config.threeStarBonusCoins;
    } else if (stars == 2) {
      coinsEarned += config.twoStarBonusCoins;
    }

    return LevelScore(
      moveScore: totalMoveScore,
      movesRemaining: movesRemaining,
      remainingMovesBonus: remainingMovesBonus,
      totalScore: totalScore,
      stars: stars,
      coinsEarned: coinsEarned,
    );
  }

  /// Calculate daily login coins with streak bonus.
  int dailyLoginReward({required int consecutiveDays}) {
    if (consecutiveDays <= 0) return 0;
    final streakMult =
        (1.0 + (consecutiveDays - 1) * config.streakMultiplier)
            .clamp(1.0, config.maxStreakMultiplier);
    return (config.dailyLoginCoins * streakMult).round();
  }

  double _shapeMultiplier(MatchShape shape) {
    switch (shape) {
      case MatchShape.three:
        return 1.0;
      case MatchShape.four:
        return config.match4Bonus;
      case MatchShape.five:
        return config.match5Bonus;
      case MatchShape.lShape:
        return config.lShapeBonus;
      case MatchShape.tShape:
        return config.tShapeBonus;
    }
  }
}

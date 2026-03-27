import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/match_detector.dart';
import 'package:match3/game/score_calculator.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

void main() {
  late ScoreCalculator calculator;

  setUp(() {
    calculator = const ScoreCalculator();
  });

  group('ScoreConfig', () {
    test('has sensible defaults', () {
      const config = ScoreConfig();
      expect(config.basePoints, 50);
      expect(config.bonusPerExtraGem, 25);
      expect(config.cascadeMultiplierStep, 0.5);
      expect(config.coinConversionRate, 0.01);
      expect(config.dailyLoginCoins, 100);
    });

    test('can be customized', () {
      const config = ScoreConfig(basePoints: 100, coinConversionRate: 0.05);
      expect(config.basePoints, 100);
      expect(config.coinConversionRate, 0.05);
    });
  });

  group('scoreMatch', () {
    test('match-3 scores base points', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.three,
      );

      final score = calculator.scoreMatch(match);
      expect(score.baseScore, 50); // 50 + (3-3)*25 = 50
      expect(score.shapeMultiplier, 1.0);
      expect(score.cascadeMultiplier, 1.0);
      expect(score.totalScore, 50);
      expect(score.gemsMatched, 3);
    });

    test('match-4 gives bonus points and shape multiplier', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
          const Position(0, 3),
        },
        gemType: GemType.blue,
        shape: MatchShape.four,
      );

      final score = calculator.scoreMatch(match);
      expect(score.baseScore, 75); // 50 + 1*25 = 75
      expect(score.shapeMultiplier, 1.5); // match4Bonus
      expect(score.totalScore, (75 * 1.5).round());
    });

    test('match-5 gives high multiplier', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
          const Position(0, 3),
          const Position(0, 4),
        },
        gemType: GemType.green,
        shape: MatchShape.five,
      );

      final score = calculator.scoreMatch(match);
      expect(score.baseScore, 100); // 50 + 2*25 = 100
      expect(score.shapeMultiplier, 3.0); // match5Bonus
      expect(score.totalScore, 300);
    });

    test('L-shape gets L bonus', () {
      final match = Match(
        positions: {
          const Position(0, 0), const Position(0, 1), const Position(0, 2),
          const Position(1, 2), const Position(2, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.lShape,
      );

      final score = calculator.scoreMatch(match);
      expect(score.shapeMultiplier, 1.5);
    });

    test('T-shape gets T bonus', () {
      final match = Match(
        positions: {
          const Position(0, 0), const Position(0, 1), const Position(0, 2),
          const Position(1, 1), const Position(2, 1),
        },
        gemType: GemType.red,
        shape: MatchShape.tShape,
      );

      final score = calculator.scoreMatch(match);
      expect(score.shapeMultiplier, 2.0);
    });

    test('cascade level increases multiplier', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.three,
      );

      final level1 = calculator.scoreMatch(match, cascadeLevel: 1);
      final level2 = calculator.scoreMatch(match, cascadeLevel: 2);
      final level3 = calculator.scoreMatch(match, cascadeLevel: 3);

      expect(level1.cascadeMultiplier, 1.0);
      expect(level2.cascadeMultiplier, 1.5);
      expect(level3.cascadeMultiplier, 2.0);

      expect(level2.totalScore, greaterThan(level1.totalScore));
      expect(level3.totalScore, greaterThan(level2.totalScore));
    });

    test('toString contains score info', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      final score = calculator.scoreMatch(match);
      expect(score.toString(), contains('50'));
    });
  });

  group('scoreCascadeStep', () {
    test('scores multiple matches in a step', () {
      final matches = [
        Match(
          positions: {
            const Position(0, 0),
            const Position(0, 1),
            const Position(0, 2),
          },
          gemType: GemType.red,
          shape: MatchShape.three,
        ),
        Match(
          positions: {
            const Position(2, 0),
            const Position(2, 1),
            const Position(2, 2),
          },
          gemType: GemType.blue,
          shape: MatchShape.three,
        ),
      ];

      final step = calculator.scoreCascadeStep(matches, cascadeLevel: 1);
      expect(step.matchScores.length, 2);
      expect(step.stepTotal, 100); // 50 + 50
      expect(step.cascadeLevel, 1);
    });

    test('cascade level applies to all matches', () {
      final matches = [
        Match(
          positions: {
            const Position(0, 0),
            const Position(0, 1),
            const Position(0, 2),
          },
          gemType: GemType.red,
          shape: MatchShape.three,
        ),
      ];

      final step1 = calculator.scoreCascadeStep(matches, cascadeLevel: 1);
      final step2 = calculator.scoreCascadeStep(matches, cascadeLevel: 2);

      expect(step2.stepTotal, greaterThan(step1.stepTotal));
    });
  });

  group('scoreMove', () {
    test('scores single cascade step', () {
      final cascadeSteps = [
        [
          Match(
            positions: {
              const Position(0, 0),
              const Position(0, 1),
              const Position(0, 2),
            },
            gemType: GemType.red,
            shape: MatchShape.three,
          ),
        ],
      ];

      final result = calculator.scoreMove(cascadeSteps);
      expect(result.totalScore, 50);
      expect(result.totalGems, 3);
      expect(result.maxCascade, 1);
      expect(result.coinsEarned, 1); // 50 * 0.01 = 0.5, rounded to 1
    });

    test('scores multiple cascade steps with increasing multipliers', () {
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.three,
      );

      final cascadeSteps = [
        [match],
        [match],
        [match],
      ];

      final result = calculator.scoreMove(cascadeSteps);
      // Level 1: 50*1.0=50, Level 2: 50*1.5=75, Level 3: 50*2.0=100
      expect(result.totalScore, 225);
      expect(result.totalGems, 9);
      expect(result.maxCascade, 3);
    });

    test('coins calculated from total score', () {
      final cascadeSteps = [
        [
          Match(
            positions: {
              const Position(0, 0),
              const Position(0, 1),
              const Position(0, 2),
              const Position(0, 3),
              const Position(0, 4),
            },
            gemType: GemType.red,
            shape: MatchShape.five,
          ),
        ],
      ];

      final result = calculator.scoreMove(cascadeSteps);
      // baseScore = 50 + 2*25 = 100, shape = 3.0, cascade = 1.0 => 300
      expect(result.totalScore, 300);
      expect(result.coinsEarned, 3); // 300 * 0.01 = 3
    });

    test('empty cascade steps', () {
      final result = calculator.scoreMove([]);
      expect(result.totalScore, 0);
      expect(result.totalGems, 0);
      expect(result.coinsEarned, 0);
    });
  });

  group('scoreLevelComplete', () {
    test('1 star for reaching target score', () {
      final result = calculator.scoreLevelComplete(
        totalMoveScore: 1000,
        movesRemaining: 0,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      expect(result.stars, 1);
      expect(result.totalScore, 1000);
      expect(result.remainingMovesBonus, 0);
    });

    test('2 stars gives bonus coins', () {
      final result = calculator.scoreLevelComplete(
        totalMoveScore: 2000,
        movesRemaining: 0,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      expect(result.stars, 2);
      expect(result.coinsEarned, greaterThan(0));
    });

    test('3 stars gives maximum bonus coins', () {
      final result = calculator.scoreLevelComplete(
        totalMoveScore: 3000,
        movesRemaining: 0,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      expect(result.stars, 3);
      // Coins = 3000 * 0.01 + 50 = 80
      expect(result.coinsEarned, 80);
    });

    test('0 stars when below target', () {
      final result = calculator.scoreLevelComplete(
        totalMoveScore: 100,
        movesRemaining: 0,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      expect(result.stars, 0);
    });

    test('remaining moves add bonus', () {
      final withMoves = calculator.scoreLevelComplete(
        totalMoveScore: 1000,
        movesRemaining: 5,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      final withoutMoves = calculator.scoreLevelComplete(
        totalMoveScore: 1000,
        movesRemaining: 0,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      expect(withMoves.totalScore, greaterThan(withoutMoves.totalScore));
      expect(withMoves.remainingMovesBonus, 500); // 5 * 50 * 2
    });

    test('remaining moves can push to higher star tier', () {
      final result = calculator.scoreLevelComplete(
        totalMoveScore: 1400,
        movesRemaining: 3,
        targetScore: 500,
        twoStarScore: 1500,
        threeStarScore: 2500,
      );

      // 1400 + 3*100 = 1700 >= 1500 => 2 stars
      expect(result.stars, 2);
    });
  });

  group('dailyLoginReward', () {
    test('day 1 gives base coins', () {
      final coins = calculator.dailyLoginReward(consecutiveDays: 1);
      expect(coins, 100);
    });

    test('streak increases reward', () {
      final day1 = calculator.dailyLoginReward(consecutiveDays: 1);
      final day5 = calculator.dailyLoginReward(consecutiveDays: 5);
      expect(day5, greaterThan(day1));
    });

    test('streak multiplier is capped', () {
      final day100 = calculator.dailyLoginReward(consecutiveDays: 100);
      // maxStreakMultiplier = 3.0, so max = 100 * 3 = 300
      expect(day100, 300);
    });

    test('day 0 returns 0', () {
      expect(calculator.dailyLoginReward(consecutiveDays: 0), 0);
    });

    test('negative days returns 0', () {
      expect(calculator.dailyLoginReward(consecutiveDays: -1), 0);
    });

    test('specific streak values', () {
      // Day 2: 1.0 + 0.1 = 1.1 => 110
      expect(calculator.dailyLoginReward(consecutiveDays: 2), 110);
      // Day 5: 1.0 + 0.4 = 1.4 => 140
      expect(calculator.dailyLoginReward(consecutiveDays: 5), 140);
      // Day 11: 1.0 + 1.0 = 2.0 => 200
      expect(calculator.dailyLoginReward(consecutiveDays: 11), 200);
    });
  });

  group('custom ScoreConfig', () {
    test('higher base points', () {
      final calc = const ScoreCalculator(
        config: ScoreConfig(basePoints: 100),
      );
      final match = Match(
        positions: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      expect(calc.scoreMatch(match).totalScore, 100);
    });

    test('higher coin conversion rate', () {
      final calc = const ScoreCalculator(
        config: ScoreConfig(coinConversionRate: 0.1),
      );
      final result = calc.scoreMove([
        [
          Match(
            positions: {
              const Position(0, 0),
              const Position(0, 1),
              const Position(0, 2),
            },
            gemType: GemType.red,
            shape: MatchShape.three,
          ),
        ],
      ]);
      expect(result.coinsEarned, 5); // 50 * 0.1 = 5
    });
  });
}

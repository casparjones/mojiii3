import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

void main() {
  late LevelGenerator generator;

  setUp(() {
    generator = const LevelGenerator();
  });

  group('LevelGenerator determinism', () {
    test('same level number produces identical config', () {
      final config1 = generator.generate(42);
      final config2 = generator.generate(42);

      expect(config1.levelNumber, config2.levelNumber);
      expect(config1.rows, config2.rows);
      expect(config1.cols, config2.cols);
      expect(config1.gemTypeCount, config2.gemTypeCount);
      expect(config1.moveLimit, config2.moveLimit);
      expect(config1.difficulty, config2.difficulty);
      expect(config1.obstacles.length, config2.obstacles.length);
    });

    test('different level numbers produce different configs', () {
      final config1 = generator.generate(1);
      final config2 = generator.generate(100);

      // They should differ in at least some aspect.
      final allSame = config1.rows == config2.rows &&
          config1.cols == config2.cols &&
          config1.gemTypeCount == config2.gemTypeCount &&
          config1.moveLimit == config2.moveLimit;
      expect(allSame, false);
    });
  });

  group('difficulty scaling', () {
    test('level 1 has low difficulty', () {
      final config = generator.generate(1);
      expect(config.difficulty, lessThan(0.1));
    });

    test('level 100 has medium difficulty', () {
      final config = generator.generate(100);
      expect(config.difficulty, closeTo(0.5, 0.01));
    });

    test('level 200+ has maximum difficulty', () {
      final config = generator.generate(200);
      expect(config.difficulty, 1.0);

      final config300 = generator.generate(300);
      expect(config300.difficulty, 1.0);
    });

    test('difficulty increases monotonically', () {
      double prevDifficulty = 0;
      for (int level = 1; level <= 200; level += 10) {
        final config = generator.generate(level);
        expect(config.difficulty, greaterThanOrEqualTo(prevDifficulty));
        prevDifficulty = config.difficulty;
      }
    });
  });

  group('board size', () {
    test('early levels have small boards', () {
      final config = generator.generate(1);
      expect(config.rows, 7);
      expect(config.cols, 7);
    });

    test('board grows with level', () {
      final early = generator.generate(1);
      final late_ = generator.generate(150);

      expect(late_.rows * late_.cols,
          greaterThanOrEqualTo(early.rows * early.cols));
    });

    test('board never exceeds 9x9', () {
      for (int level = 1; level <= 300; level += 20) {
        final config = generator.generate(level);
        expect(config.rows, lessThanOrEqualTo(9));
        expect(config.cols, lessThanOrEqualTo(9));
      }
    });

    test('board is always at least 7x7', () {
      for (int level = 1; level <= 300; level += 20) {
        final config = generator.generate(level);
        expect(config.rows, greaterThanOrEqualTo(7));
        expect(config.cols, greaterThanOrEqualTo(7));
      }
    });
  });

  group('gem type count', () {
    test('starts with fewer gem types', () {
      final config = generator.generate(1);
      expect(config.gemTypeCount, 4);
    });

    test('scales up to 6', () {
      final config = generator.generate(50);
      expect(config.gemTypeCount, 6);
    });

    test('never exceeds GemType.count', () {
      for (int level = 1; level <= 300; level += 20) {
        final config = generator.generate(level);
        expect(config.gemTypeCount, lessThanOrEqualTo(GemType.count));
      }
    });

    test('always at least 3', () {
      for (int level = 1; level <= 300; level += 20) {
        final config = generator.generate(level);
        expect(config.gemTypeCount, greaterThanOrEqualTo(3));
      }
    });
  });

  group('constraints', () {
    test('early levels are move-based', () {
      final config = generator.generate(1);
      expect(config.constraintType, LevelConstraintType.moves);
    });

    test('level 10 is timed', () {
      final config = generator.generate(10);
      expect(config.constraintType, LevelConstraintType.timed);
    });

    test('timed levels have time limit and no move limit', () {
      final config = generator.generate(10);
      expect(config.timeLimitSeconds, greaterThan(0));
      expect(config.moveLimit, 0);
    });

    test('move limit decreases with difficulty', () {
      final easy = generator.generate(1);
      final hard = generator.generate(150);

      if (easy.constraintType == LevelConstraintType.moves &&
          hard.constraintType == LevelConstraintType.moves) {
        expect(hard.moveLimit, lessThanOrEqualTo(easy.moveLimit));
      }
    });

    test('move limit never below 15', () {
      for (int level = 1; level <= 300; level++) {
        final config = generator.generate(level);
        if (config.constraintType == LevelConstraintType.moves) {
          expect(config.moveLimit, greaterThanOrEqualTo(15));
        }
      }
    });

    test('time limit never below 60 seconds', () {
      for (int level = 10; level <= 300; level += 10) {
        final config = generator.generate(level);
        if (config.constraintType == LevelConstraintType.timed) {
          expect(config.timeLimitSeconds, greaterThanOrEqualTo(60));
        }
      }
    });
  });

  group('objectives', () {
    test('early levels have score objective', () {
      for (int level = 1; level <= 5; level++) {
        final config = generator.generate(level);
        expect(config.objective.type, LevelObjectiveType.score);
      }
    });

    test('score objective has valid thresholds', () {
      final config = generator.generate(1);
      final obj = config.objective;
      expect(obj.targetScore, greaterThan(0));
      expect(obj.twoStarScore, greaterThan(obj.targetScore));
      expect(obj.threeStarScore, greaterThan(obj.twoStarScore));
    });

    test('collectGems objective appears after level 5', () {
      bool found = false;
      for (int level = 6; level <= 20; level++) {
        final config = generator.generate(level);
        if (config.objective.type == LevelObjectiveType.collectGems) {
          found = true;
          expect(config.objective.targetGems, isNotEmpty);
          break;
        }
      }
      expect(found, true);
    });

    test('destroyObstacles objective appears in later levels', () {
      bool found = false;
      for (int level = 11; level <= 100; level++) {
        final config = generator.generate(level);
        if (config.objective.type == LevelObjectiveType.destroyObstacles) {
          found = true;
          expect(config.objective.targetObstacles, greaterThan(0));
          break;
        }
      }
      expect(found, true);
    });

    test('target score increases with level', () {
      // Compare level 1 and level 100 score objectives.
      final config1 = generator.generate(1);
      // Find a high-level score objective.
      int highScore = 0;
      for (int level = 100; level <= 110; level++) {
        final config = generator.generate(level);
        if (config.objective.type == LevelObjectiveType.score) {
          highScore = config.objective.targetScore;
          break;
        }
      }
      if (highScore > 0) {
        expect(highScore, greaterThan(config1.objective.targetScore));
      }
    });
  });

  group('obstacles', () {
    test('no obstacles before level 8', () {
      for (int level = 1; level <= 7; level++) {
        final config = generator.generate(level);
        expect(config.obstacles, isEmpty,
            reason: 'Level $level should have no obstacles');
      }
    });

    test('obstacles appear from level 8', () {
      bool found = false;
      for (int level = 8; level <= 20; level++) {
        final config = generator.generate(level);
        if (config.obstacles.isNotEmpty) {
          found = true;
          break;
        }
      }
      expect(found, true);
    });

    test('early obstacle levels only have ice', () {
      for (int level = 8; level <= 14; level++) {
        final config = generator.generate(level);
        for (final obs in config.obstacles) {
          expect(obs.type, ObstacleType.ice,
              reason: 'Level $level should only have ice obstacles');
        }
      }
    });

    test('obstacle count increases with difficulty', () {
      int earlyCount = 0;
      int lateCount = 0;

      for (int level = 8; level <= 15; level++) {
        earlyCount += generator.generate(level).obstacles.length;
      }
      for (int level = 180; level <= 190; level++) {
        lateCount += generator.generate(level).obstacles.length;
      }

      expect(lateCount, greaterThan(earlyCount));
    });

    test('obstacles are within board bounds', () {
      for (int level = 8; level <= 200; level += 5) {
        final config = generator.generate(level);
        for (final obs in config.obstacles) {
          expect(obs.position.row, greaterThanOrEqualTo(0));
          expect(obs.position.row, lessThan(config.rows));
          expect(obs.position.col, greaterThanOrEqualTo(0));
          expect(obs.position.col, lessThan(config.cols));
        }
      }
    });

    test('no duplicate obstacle positions', () {
      for (int level = 8; level <= 200; level += 10) {
        final config = generator.generate(level);
        final positions = config.obstacles.map((o) => o.position).toSet();
        expect(positions.length, config.obstacles.length,
            reason: 'Level $level has duplicate obstacle positions');
      }
    });

    test('stone obstacles have 2 hit points', () {
      for (int level = 50; level <= 100; level++) {
        final config = generator.generate(level);
        for (final obs in config.obstacles) {
          if (obs.type == ObstacleType.stone) {
            expect(obs.hitPoints, 2);
          }
        }
      }
    });

    test('obstacle types unlock progressively', () {
      // Level 15-29: ice + chain
      for (int level = 15; level <= 29; level++) {
        final config = generator.generate(level);
        for (final obs in config.obstacles) {
          expect(
            [ObstacleType.ice, ObstacleType.chain].contains(obs.type),
            true,
            reason: 'Level $level should only have ice/chain, got ${obs.type}',
          );
        }
      }
    });

    test('obstacles not placed in top 2 rows', () {
      for (int level = 8; level <= 200; level += 10) {
        final config = generator.generate(level);
        for (final obs in config.obstacles) {
          expect(obs.position.row, greaterThanOrEqualTo(2),
              reason: 'Level $level has obstacle in spawn area at ${obs.position}');
        }
      }
    });
  });

  group('ObstaclePlacement', () {
    test('toString contains useful info', () {
      const obs = ObstaclePlacement(
        position: Position(3, 4),
        type: ObstacleType.ice,
      );
      expect(obs.toString(), contains('ice'));
      expect(obs.toString(), contains('3'));
    });
  });

  group('edge cases', () {
    test('level 0 generates without error', () {
      final config = generator.generate(0);
      expect(config.levelNumber, 0);
    });

    test('very high level generates without error', () {
      final config = generator.generate(10000);
      expect(config.levelNumber, 10000);
      expect(config.difficulty, 1.0);
    });

    test('negative level generates without error', () {
      final config = generator.generate(-1);
      expect(config.levelNumber, -1);
    });
  });
}

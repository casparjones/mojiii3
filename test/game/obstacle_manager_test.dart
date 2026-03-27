import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/level_generator.dart';
import 'package:match3/game/obstacle_manager.dart';
import 'package:match3/models/position.dart';

void main() {
  late ObstacleManager manager;

  setUp(() {
    manager = ObstacleManager();
  });

  group('Obstacle', () {
    test('creates with correct state', () {
      final obs = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      expect(obs.type, ObstacleType.ice);
      expect(obs.hitPoints, 1);
      expect(obs.maxHitPoints, 1);
      expect(obs.isDestroyed, false);
    });

    test('hit reduces hitPoints', () {
      final obs = Obstacle(type: ObstacleType.stone, hitPoints: 2);
      expect(obs.hit(), false); // Not destroyed yet.
      expect(obs.hitPoints, 1);
      expect(obs.hit(), true); // Now destroyed.
      expect(obs.isDestroyed, true);
    });

    test('hit on destroyed obstacle returns false', () {
      final obs = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      obs.hit();
      expect(obs.hit(), false);
    });

    test('blocksCell for stone only', () {
      final stone = Obstacle(type: ObstacleType.stone, hitPoints: 2);
      expect(stone.blocksCell, true);

      final ice = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      expect(ice.blocksCell, false);
    });

    test('blocksCell false for destroyed stone', () {
      final stone = Obstacle(type: ObstacleType.stone, hitPoints: 1);
      stone.hit();
      expect(stone.blocksCell, false);
    });

    test('locksGem for chain and ice', () {
      final chain = Obstacle(type: ObstacleType.chain, hitPoints: 1);
      expect(chain.locksGem, true);

      final ice = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      expect(ice.locksGem, true);

      final slime = Obstacle(type: ObstacleType.slime, hitPoints: 1);
      expect(slime.locksGem, false);

      final stone = Obstacle(type: ObstacleType.stone, hitPoints: 2);
      expect(stone.locksGem, false);
    });

    test('spreads only for active slime', () {
      final slime = Obstacle(type: ObstacleType.slime, hitPoints: 1);
      expect(slime.spreads, true);

      slime.hit();
      expect(slime.spreads, false);

      final ice = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      expect(ice.spreads, false);
    });

    test('copy creates independent clone', () {
      final obs = Obstacle(type: ObstacleType.stone, hitPoints: 2);
      final copy = obs.copy();
      obs.hit();
      expect(obs.hitPoints, 1);
      expect(copy.hitPoints, 2);
    });

    test('toString contains type name', () {
      final obs = Obstacle(type: ObstacleType.ice, hitPoints: 1);
      expect(obs.toString(), contains('ice'));
    });
  });

  group('ObstacleManager initialization', () {
    test('starts empty', () {
      expect(manager.activeCount, 0);
      expect(manager.totalCount, 0);
    });

    test('initialize from placements', () {
      manager.initialize([
        const ObstaclePlacement(
          position: Position(3, 3),
          type: ObstacleType.ice,
        ),
        const ObstaclePlacement(
          position: Position(4, 4),
          type: ObstacleType.stone,
          hitPoints: 2,
        ),
      ]);

      expect(manager.activeCount, 2);
      expect(manager.hasObstacle(const Position(3, 3)), true);
      expect(manager.hasObstacle(const Position(4, 4)), true);
      expect(manager.hasObstacle(const Position(0, 0)), false);
    });

    test('place adds single obstacle', () {
      manager.place(const Position(2, 3), ObstacleType.chain);
      expect(manager.activeCount, 1);
      expect(manager.hasObstacle(const Position(2, 3)), true);
    });

    test('obstacleAt returns correct obstacle', () {
      manager.place(const Position(2, 3), ObstacleType.ice);
      final obs = manager.obstacleAt(const Position(2, 3));
      expect(obs, isNotNull);
      expect(obs!.type, ObstacleType.ice);
    });

    test('obstacleAt returns null for empty position', () {
      expect(manager.obstacleAt(const Position(0, 0)), isNull);
    });
  });

  group('ObstacleManager blocksCell and isLocked', () {
    test('stone blocks cell', () {
      manager.place(const Position(3, 3), ObstacleType.stone, hitPoints: 2);
      expect(manager.blocksCell(const Position(3, 3)), true);
    });

    test('ice does not block cell', () {
      manager.place(const Position(3, 3), ObstacleType.ice);
      expect(manager.blocksCell(const Position(3, 3)), false);
    });

    test('chain locks gem', () {
      manager.place(const Position(3, 3), ObstacleType.chain);
      expect(manager.isLocked(const Position(3, 3)), true);
    });

    test('slime does not lock gem', () {
      manager.place(const Position(3, 3), ObstacleType.slime);
      expect(manager.isLocked(const Position(3, 3)), false);
    });

    test('empty position is not blocked or locked', () {
      expect(manager.blocksCell(const Position(0, 0)), false);
      expect(manager.isLocked(const Position(0, 0)), false);
    });
  });

  group('processMatches - Ice', () {
    test('ice destroyed by adjacent match', () {
      manager.place(const Position(3, 3), ObstacleType.ice);

      final result = manager.processMatches(
        {const Position(3, 2), const Position(3, 1), const Position(3, 0)},
        8, 8,
      );

      expect(result.destroyed, contains(const Position(3, 3)));
      expect(result.destroyedCount, 1);
    });

    test('ice destroyed by direct match', () {
      manager.place(const Position(3, 3), ObstacleType.ice);

      final result = manager.processMatches(
        {const Position(3, 3), const Position(3, 4), const Position(3, 5)},
        8, 8,
      );

      expect(result.destroyed, contains(const Position(3, 3)));
    });

    test('ice not affected by distant match', () {
      manager.place(const Position(3, 3), ObstacleType.ice);

      final result = manager.processMatches(
        {const Position(0, 0), const Position(0, 1), const Position(0, 2)},
        8, 8,
      );

      expect(result.destroyed, isEmpty);
      expect(manager.hasObstacle(const Position(3, 3)), true);
    });
  });

  group('processMatches - Chain', () {
    test('chain destroyed only by direct match', () {
      manager.place(const Position(3, 3), ObstacleType.chain);

      // Adjacent match should NOT destroy chain.
      final result1 = manager.processMatches(
        {const Position(3, 2), const Position(3, 1), const Position(3, 0)},
        8, 8,
      );
      expect(result1.destroyed, isEmpty);

      // Direct match should destroy chain.
      final result2 = manager.processMatches(
        {const Position(3, 3), const Position(3, 4), const Position(3, 5)},
        8, 8,
      );
      expect(result2.destroyed, contains(const Position(3, 3)));
    });
  });

  group('processMatches - Stone', () {
    test('stone takes 2 hits to destroy', () {
      manager.place(const Position(3, 3), ObstacleType.stone, hitPoints: 2);

      // First adjacent match: damages but doesn't destroy.
      final result1 = manager.processMatches(
        {const Position(3, 2), const Position(3, 1), const Position(3, 0)},
        8, 8,
      );
      expect(result1.damaged, contains(const Position(3, 3)));
      expect(result1.destroyed, isEmpty);
      expect(manager.hasObstacle(const Position(3, 3)), true);

      // Second adjacent match: destroys.
      final result2 = manager.processMatches(
        {const Position(3, 4), const Position(3, 5), const Position(3, 6)},
        8, 8,
      );
      expect(result2.destroyed, contains(const Position(3, 3)));
    });
  });

  group('processMatches - Slime', () {
    test('slime destroyed by adjacent match', () {
      manager.place(const Position(3, 3), ObstacleType.slime);

      final result = manager.processMatches(
        {const Position(3, 2), const Position(3, 1), const Position(3, 0)},
        8, 8,
      );

      expect(result.destroyed, contains(const Position(3, 3)));
    });
  });

  group('processSlimeSpread', () {
    test('slime spreads to adjacent cell', () {
      manager.place(const Position(3, 3), ObstacleType.slime);

      final result = manager.processSlimeSpread(8, 8, random: Random(42));

      expect(result.slimeSpread, isNotEmpty);
      expect(result.slimeSpread.length, 1);

      // New slime cell should be adjacent to original.
      final newPos = result.slimeSpread.first;
      expect(newPos.isAdjacentTo(const Position(3, 3)), true);

      // Should now have 2 slime cells.
      expect(manager.activeCount, 2);
    });

    test('slime does not spread to occupied cells', () {
      manager.place(const Position(3, 3), ObstacleType.slime);
      manager.place(const Position(3, 2), ObstacleType.ice);
      manager.place(const Position(3, 4), ObstacleType.ice);
      manager.place(const Position(2, 3), ObstacleType.ice);
      manager.place(const Position(4, 3), ObstacleType.ice);

      final result = manager.processSlimeSpread(8, 8);
      expect(result.slimeSpread, isEmpty);
    });

    test('destroyed slime does not spread', () {
      manager.place(const Position(3, 3), ObstacleType.slime);
      manager.obstacleAt(const Position(3, 3))!.hit(); // Destroy it.

      final result = manager.processSlimeSpread(8, 8);
      expect(result.slimeSpread, isEmpty);
    });

    test('multiple slime cells each spread', () {
      manager.place(const Position(3, 3), ObstacleType.slime);
      manager.place(const Position(5, 5), ObstacleType.slime);

      final result = manager.processSlimeSpread(8, 8, random: Random(42));
      expect(result.slimeSpread.length, 2);
    });
  });

  group('cleanup and clear', () {
    test('cleanupDestroyed removes destroyed obstacles', () {
      manager.place(const Position(3, 3), ObstacleType.ice);
      manager.place(const Position(4, 4), ObstacleType.ice);

      manager.obstacleAt(const Position(3, 3))!.hit();
      manager.cleanupDestroyed();

      expect(manager.totalCount, 1);
      expect(manager.hasObstacle(const Position(3, 3)), false);
      expect(manager.hasObstacle(const Position(4, 4)), true);
    });

    test('clear removes all obstacles', () {
      manager.place(const Position(3, 3), ObstacleType.ice);
      manager.place(const Position(4, 4), ObstacleType.stone, hitPoints: 2);

      manager.clear();
      expect(manager.totalCount, 0);
      expect(manager.activeCount, 0);
    });
  });

  group('ObstacleProcessResult', () {
    test('destroyedCount returns correct count', () {
      final result = ObstacleProcessResult(
        destroyed: {const Position(0, 0), const Position(1, 1)},
        damaged: {const Position(2, 2)},
      );
      expect(result.destroyedCount, 2);
    });

    test('empty result', () {
      const result = ObstacleProcessResult();
      expect(result.destroyedCount, 0);
      expect(result.damaged, isEmpty);
      expect(result.slimeSpread, isEmpty);
    });
  });

  group('integration with LevelGenerator obstacles', () {
    test('can initialize from generated level', () {
      const generator = LevelGenerator();
      final levelConfig = generator.generate(50);

      manager.initialize(levelConfig.obstacles);

      expect(manager.activeCount, levelConfig.obstacles.length);

      // All obstacles should be at their specified positions.
      for (final placement in levelConfig.obstacles) {
        expect(manager.hasObstacle(placement.position), true);
        expect(manager.obstacleAt(placement.position)!.type, placement.type);
      }
    });
  });
}

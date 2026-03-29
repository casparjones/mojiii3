import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/combo_bomb_dropper.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

void main() {
  group('ComboBombDropper', () {
    test('returns null for cascadeLevel < 2', () {
      final dropper = ComboBombDropper(random: Random(42));
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ]);
      final result = dropper.tryDrop(
        cascadeLevel: 1,
        board: board,
        emptyPositions: [const Position(0, 0)],
      );
      expect(result, isNull);
    });

    test('returns null for empty positions list', () {
      final dropper = ComboBombDropper(random: Random(42));
      final board = Board.fromGrid([
        [const Gem(type: GemType.red)],
      ]);
      final result = dropper.tryDrop(
        cascadeLevel: 3,
        board: board,
        emptyPositions: [],
      );
      expect(result, isNull);
    });

    test('cascadeLevel 2 only produces crossBomb when dropping', () {
      // Run many times to verify only crossBomb at level 2
      var crossBombCount = 0;
      var bombCount = 0;
      var nullCount = 0;
      for (var seed = 0; seed < 1000; seed++) {
        final dropper = ComboBombDropper(random: Random(seed));
        final board = Board.fromGrid([
          [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        ]);
        final result = dropper.tryDrop(
          cascadeLevel: 2,
          board: board,
          emptyPositions: [const Position(0, 0), const Position(0, 1)],
        );
        if (result == null) {
          nullCount++;
        } else if (result.gem.special == SpecialType.crossBomb) {
          crossBombCount++;
        } else if (result.gem.special == SpecialType.bomb) {
          bombCount++;
        }
      }
      // At 5% chance, expect roughly 50 drops out of 1000
      expect(crossBombCount, greaterThan(0));
      expect(bombCount, 0, reason: 'Level 2 should only produce crossBomb');
      expect(nullCount, greaterThan(800),
          reason: '5% chance means most should be null');
    });

    test('cascadeLevel 3 can produce both crossBomb and bomb', () {
      var crossBombCount = 0;
      var bombCount = 0;
      for (var seed = 0; seed < 5000; seed++) {
        final dropper = ComboBombDropper(random: Random(seed));
        final board = Board.fromGrid([
          [const Gem(type: GemType.red)],
        ]);
        final result = dropper.tryDrop(
          cascadeLevel: 3,
          board: board,
          emptyPositions: [const Position(0, 0)],
        );
        if (result == null) continue;
        if (result.gem.special == SpecialType.crossBomb) {
          crossBombCount++;
        } else if (result.gem.special == SpecialType.bomb) {
          bombCount++;
        }
      }
      expect(crossBombCount, greaterThan(0),
          reason: 'Level 3 should produce cross bombs');
      expect(bombCount, greaterThan(0),
          reason: 'Level 3 should produce area bombs');
    });

    test('cascadeLevel 4+ has higher drop rate and prefers bomb', () {
      var crossBombCount = 0;
      var bombCount = 0;
      var totalDrops = 0;
      for (var seed = 0; seed < 5000; seed++) {
        final dropper = ComboBombDropper(random: Random(seed));
        final board = Board.fromGrid([
          [const Gem(type: GemType.red)],
        ]);
        final result = dropper.tryDrop(
          cascadeLevel: 5,
          board: board,
          emptyPositions: [const Position(0, 0)],
        );
        if (result == null) continue;
        totalDrops++;
        if (result.gem.special == SpecialType.crossBomb) {
          crossBombCount++;
        } else if (result.gem.special == SpecialType.bomb) {
          bombCount++;
        }
      }
      // 30% drop rate -> ~1500 drops out of 5000
      expect(totalDrops, greaterThan(1000));
      // 70% area bomb weighting
      expect(bombCount, greaterThan(crossBombCount),
          reason: 'Level 4+ should favor area bombs');
    });

    test('dropped bomb has a valid gem type and position', () {
      // Use a seed that we know produces a drop
      for (var seed = 0; seed < 100; seed++) {
        final dropper = ComboBombDropper(random: Random(seed));
        final board = Board.fromGrid([
          [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        ]);
        final positions = [const Position(0, 0), const Position(0, 1)];
        final result = dropper.tryDrop(
          cascadeLevel: 4,
          board: board,
          emptyPositions: positions,
        );
        if (result != null) {
          expect(GemType.values, contains(result.gem.type));
          expect(positions, contains(result.position));
          expect(
            result.gem.special == SpecialType.bomb ||
                result.gem.special == SpecialType.crossBomb,
            isTrue,
          );
          return; // Found a valid drop, test passes
        }
      }
      fail('Expected at least one drop in 100 attempts at 30% chance');
    });
  });

  group('ComboBombDrop', () {
    test('stores position and gem correctly', () {
      const drop = ComboBombDrop(
        position: Position(2, 3),
        gem: Gem(type: GemType.green, special: SpecialType.crossBomb),
      );
      expect(drop.position, const Position(2, 3));
      expect(drop.gem.type, GemType.green);
      expect(drop.gem.special, SpecialType.crossBomb);
    });
  });
}

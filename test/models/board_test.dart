import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

void main() {
  group('BoardConfig', () {
    test('default values', () {
      const config = BoardConfig();
      expect(config.rows, 8);
      expect(config.cols, 8);
      expect(config.gemTypeCount, 6);
    });

    test('custom values', () {
      const config = BoardConfig(rows: 10, cols: 7, gemTypeCount: 4);
      expect(config.rows, 10);
      expect(config.cols, 7);
      expect(config.gemTypeCount, 4);
    });
  });

  group('Board.initialize', () {
    test('creates board with correct dimensions', () {
      const config = BoardConfig(rows: 6, cols: 7);
      final board = Board.initialize(config, random: Random(42));
      expect(board.rows, 6);
      expect(board.cols, 7);
    });

    test('fills all cells', () {
      const config = BoardConfig(rows: 8, cols: 8);
      final board = Board.initialize(config, random: Random(42));
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          expect(board.gemAt(Position(r, c)), isNotNull,
              reason: 'Cell ($r, $c) should not be null');
        }
      }
    });

    test('has no initial matches', () {
      // Run multiple times with different seeds
      for (var seed = 0; seed < 20; seed++) {
        const config = BoardConfig(rows: 8, cols: 8);
        final board = Board.initialize(config, random: Random(seed));
        final matches = board.findAllMatches();
        expect(matches, isEmpty,
            reason: 'Seed $seed produced initial matches');
      }
    });

    test('only uses allowed gem types', () {
      const config = BoardConfig(rows: 8, cols: 8, gemTypeCount: 3);
      final board = Board.initialize(config, random: Random(42));
      final allowedTypes = {GemType.red, GemType.blue, GemType.green};
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          final gem = board.gemAt(Position(r, c));
          expect(allowedTypes.contains(gem!.type), isTrue,
              reason: 'Cell ($r, $c) has disallowed type ${gem.type}');
        }
      }
    });

    test('all gems are non-special', () {
      const config = BoardConfig();
      final board = Board.initialize(config, random: Random(42));
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          expect(board.gemAt(Position(r, c))!.special, SpecialType.none);
        }
      }
    });
  });

  group('Board.fromGrid', () {
    test('creates board from grid data', () {
      final grid = [
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        [const Gem(type: GemType.green), const Gem(type: GemType.yellow)],
      ];
      final board = Board.fromGrid(grid);
      expect(board.rows, 2);
      expect(board.cols, 2);
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(1, 1))!.type, GemType.yellow);
    });

    test('is a deep copy', () {
      final grid = [
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ];
      final board = Board.fromGrid(grid);
      grid[0][0] = const Gem(type: GemType.green);
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
    });
  });

  group('Board operations', () {
    late Board board;

    setUp(() {
      board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue), const Gem(type: GemType.green)],
        [const Gem(type: GemType.yellow), const Gem(type: GemType.purple), const Gem(type: GemType.orange)],
        [const Gem(type: GemType.red), const Gem(type: GemType.blue), const Gem(type: GemType.green)],
      ]);
    });

    test('gemAt returns correct gem', () {
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(1, 2))!.type, GemType.orange);
    });

    test('gemAt returns null for out of bounds', () {
      expect(board.gemAt(const Position(-1, 0)), isNull);
      expect(board.gemAt(const Position(0, 3)), isNull);
      expect(board.gemAt(const Position(3, 0)), isNull);
    });

    test('isInBounds works', () {
      expect(board.isInBounds(const Position(0, 0)), isTrue);
      expect(board.isInBounds(const Position(2, 2)), isTrue);
      expect(board.isInBounds(const Position(-1, 0)), isFalse);
      expect(board.isInBounds(const Position(3, 0)), isFalse);
      expect(board.isInBounds(const Position(0, 3)), isFalse);
    });

    test('setGem works', () {
      board.setGem(const Position(0, 0), const Gem(type: GemType.purple));
      expect(board.gemAt(const Position(0, 0))!.type, GemType.purple);
    });

    test('setGem with null', () {
      board.setGem(const Position(0, 0), null);
      expect(board.gemAt(const Position(0, 0)), isNull);
    });

    test('swap exchanges two gems', () {
      board.swap(const Position(0, 0), const Position(0, 1));
      expect(board.gemAt(const Position(0, 0))!.type, GemType.blue);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.red);
    });

    test('removeGems sets positions to null', () {
      board.removeGems({const Position(0, 0), const Position(1, 1)});
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 1)), isNull);
      expect(board.gemAt(const Position(0, 1)), isNotNull);
    });

    test('hasEmptyCells detects null cells', () {
      expect(board.hasEmptyCells, isFalse);
      board.setGem(const Position(1, 1), null);
      expect(board.hasEmptyCells, isTrue);
    });

    test('copy creates independent board', () {
      final copy = board.copy();
      copy.setGem(const Position(0, 0), const Gem(type: GemType.purple));
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(copy.gemAt(const Position(0, 0))!.type, GemType.purple);
    });
  });

  group('Board.findAllMatches', () {
    test('detects horizontal match of 3', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
        [const Gem(type: GemType.blue), const Gem(type: GemType.green), const Gem(type: GemType.yellow)],
      ]);
      final matches = board.findAllMatches();
      expect(matches, containsAll([
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
      ]));
    });

    test('detects vertical match of 3', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        [const Gem(type: GemType.red), const Gem(type: GemType.green)],
        [const Gem(type: GemType.red), const Gem(type: GemType.yellow)],
      ]);
      final matches = board.findAllMatches();
      expect(matches, containsAll([
        const Position(0, 0),
        const Position(1, 0),
        const Position(2, 0),
      ]));
    });

    test('detects match of 4', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
      ]);
      final matches = board.findAllMatches();
      expect(matches.length, 4);
    });

    test('detects match of 5', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
      ]);
      final matches = board.findAllMatches();
      expect(matches.length, 5);
    });

    test('no matches returns empty set', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue), const Gem(type: GemType.green)],
        [const Gem(type: GemType.blue), const Gem(type: GemType.green), const Gem(type: GemType.red)],
      ]);
      expect(board.findAllMatches(), isEmpty);
    });

    test('detects multiple simultaneous matches', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        [const Gem(type: GemType.green), const Gem(type: GemType.blue), const Gem(type: GemType.blue), const Gem(type: GemType.blue)],
      ]);
      final matches = board.findAllMatches();
      expect(matches.length, 6);
    });
  });
}

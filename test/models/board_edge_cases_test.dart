import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

void main() {
  group('Board edge cases', () {
    test('1x1 board initializes without matches', () {
      const config = BoardConfig(rows: 1, cols: 1, gemTypeCount: 3);
      final board = Board.initialize(config, random: Random(0));
      expect(board.rows, 1);
      expect(board.cols, 1);
      expect(board.gemAt(const Position(0, 0)), isNotNull);
      expect(board.findAllMatches(), isEmpty);
    });

    test('2x2 board initializes without matches', () {
      const config = BoardConfig(rows: 2, cols: 2, gemTypeCount: 3);
      final board = Board.initialize(config, random: Random(0));
      expect(board.findAllMatches(), isEmpty);
    });

    test('1xN board (single row) has no initial matches', () {
      for (var seed = 0; seed < 10; seed++) {
        const config = BoardConfig(rows: 1, cols: 10, gemTypeCount: 4);
        final board = Board.initialize(config, random: Random(seed));
        expect(board.findAllMatches(), isEmpty,
            reason: 'Seed $seed produced match on 1xN board');
      }
    });

    test('Nx1 board (single column) has no initial matches', () {
      for (var seed = 0; seed < 10; seed++) {
        const config = BoardConfig(rows: 10, cols: 1, gemTypeCount: 4);
        final board = Board.initialize(config, random: Random(seed));
        expect(board.findAllMatches(), isEmpty,
            reason: 'Seed $seed produced match on Nx1 board');
      }
    });

    test('minimum gem types (3) still prevents matches', () {
      for (var seed = 0; seed < 20; seed++) {
        const config = BoardConfig(rows: 8, cols: 8, gemTypeCount: 3);
        final board = Board.initialize(config, random: Random(seed));
        expect(board.findAllMatches(), isEmpty,
            reason: 'Seed $seed with 3 gem types produced initial matches');
      }
    });

    test('large board (15x15) has no initial matches', () {
      const config = BoardConfig(rows: 15, cols: 15, gemTypeCount: 6);
      final board = Board.initialize(config, random: Random(42));
      expect(board.findAllMatches(), isEmpty);
      // Verify all cells filled
      for (var r = 0; r < 15; r++) {
        for (var c = 0; c < 15; c++) {
          expect(board.gemAt(Position(r, c)), isNotNull);
        }
      }
    });

    test('rectangular board (3x10) has no initial matches', () {
      const config = BoardConfig(rows: 3, cols: 10, gemTypeCount: 5);
      final board = Board.initialize(config, random: Random(42));
      expect(board.findAllMatches(), isEmpty);
    });

    test('Board.fromGrid with empty grid', () {
      final board = Board.fromGrid([]);
      expect(board.rows, 0);
      expect(board.cols, 0);
      expect(board.findAllMatches(), isEmpty);
      expect(board.hasEmptyCells, isFalse);
    });

    test('setGem out of bounds is no-op', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ]);
      // Should not throw
      board.setGem(const Position(-1, 0), const Gem(type: GemType.green));
      board.setGem(const Position(0, 5), const Gem(type: GemType.green));
      board.setGem(const Position(10, 10), const Gem(type: GemType.green));
      // Original values unchanged
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.blue);
    });

    test('swap with null cells works', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), null],
      ]);
      board.swap(const Position(0, 0), const Position(0, 1));
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.red);
    });

    test('removeGems with out-of-bounds positions is safe', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ]);
      // Should not throw - out of bounds positions ignored via setGem
      board.removeGems({const Position(0, 0), const Position(5, 5)});
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.blue);
    });

    test('removeGems with empty set does nothing', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red)],
      ]);
      board.removeGems({});
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
    });
  });

  group('Board.findAllMatches edge cases', () {
    test('L-shaped match detected as both horizontal and vertical', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
        [const Gem(type: GemType.red), const Gem(type: GemType.blue), const Gem(type: GemType.green)],
        [const Gem(type: GemType.red), const Gem(type: GemType.green), const Gem(type: GemType.blue)],
      ]);
      final matches = board.findAllMatches();
      // Horizontal: (0,0), (0,1), (0,2)
      // Vertical: (0,0), (1,0), (2,0)
      expect(matches, contains(const Position(0, 0)));
      expect(matches, contains(const Position(0, 1)));
      expect(matches, contains(const Position(0, 2)));
      expect(matches, contains(const Position(1, 0)));
      expect(matches, contains(const Position(2, 0)));
      expect(matches.length, 5); // (0,0) counted once
    });

    test('T-shaped match detected', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
        [const Gem(type: GemType.blue), const Gem(type: GemType.red), const Gem(type: GemType.green)],
        [const Gem(type: GemType.green), const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ]);
      final matches = board.findAllMatches();
      // Horizontal: (0,0), (0,1), (0,2)
      // Vertical: (0,1), (1,1), (2,1)
      expect(matches, contains(const Position(0, 0)));
      expect(matches, contains(const Position(0, 1)));
      expect(matches, contains(const Position(0, 2)));
      expect(matches, contains(const Position(1, 1)));
      expect(matches, contains(const Position(2, 1)));
      expect(matches.length, 5);
    });

    test('match with null gaps does not bridge', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), null, const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.red)],
      ]);
      final matches = board.findAllMatches();
      // Only (0,2), (0,3), (0,4) should match; the null breaks the run
      expect(matches.length, 3);
      expect(matches, contains(const Position(0, 2)));
      expect(matches, contains(const Position(0, 3)));
      expect(matches, contains(const Position(0, 4)));
    });

    test('vertical match with null gap does not bridge', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red)],
        [null],
        [const Gem(type: GemType.red)],
        [const Gem(type: GemType.red)],
        [const Gem(type: GemType.red)],
      ]);
      final matches = board.findAllMatches();
      expect(matches.length, 3);
      expect(matches, contains(const Position(2, 0)));
      expect(matches, contains(const Position(3, 0)));
      expect(matches, contains(const Position(4, 0)));
    });

    test('full board of same type is one big match', () {
      final grid = List.generate(
        4,
        (_) => List.generate(4, (_) => const Gem(type: GemType.red)),
      );
      final board = Board.fromGrid(grid);
      final matches = board.findAllMatches();
      // Every cell should be matched
      expect(matches.length, 16);
    });

    test('exactly 2 in a row is not a match', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.red), const Gem(type: GemType.blue)],
      ]);
      expect(board.findAllMatches(), isEmpty);
    });

    test('board with all nulls returns no matches', () {
      final board = Board.fromGrid([
        [null, null, null],
        [null, null, null],
      ]);
      expect(board.findAllMatches(), isEmpty);
    });
  });

  group('Board.toString', () {
    test('renders grid correctly', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        [const Gem(type: GemType.green), null],
      ]);
      final str = board.toString();
      expect(str, contains('R'));
      expect(str, contains('B'));
      expect(str, contains('G'));
      expect(str, contains('.'));
    });
  });

  group('Board.copy deep independence', () {
    test('copy does not share grid references', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red), const Gem(type: GemType.blue)],
        [const Gem(type: GemType.green), const Gem(type: GemType.yellow)],
      ]);
      final copy = board.copy();

      // Modify copy extensively
      copy.setGem(const Position(0, 0), null);
      copy.setGem(const Position(0, 1), null);
      copy.setGem(const Position(1, 0), null);
      copy.setGem(const Position(1, 1), null);

      // Original should be fully intact
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.blue);
      expect(board.gemAt(const Position(1, 0))!.type, GemType.green);
      expect(board.gemAt(const Position(1, 1))!.type, GemType.yellow);
    });
  });
}

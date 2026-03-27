import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/match_detector.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);
const _y = Gem(type: GemType.yellow);
const _p = Gem(type: GemType.purple);

void main() {
  const detector = MatchDetector();

  group('MatchDetector - horizontal matches', () {
    test('detects 3 in a row', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _b],
        [_b, _g, _y, _p],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.three);
      expect(matches[0].gemType, GemType.red);
      expect(matches[0].positions.length, 3);
    });

    test('detects 4 in a row', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _r],
        [_b, _g, _y, _p],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.four);
      expect(matches[0].positions.length, 4);
    });

    test('detects 5 in a row', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _r, _r],
        [_b, _g, _y, _p, _b],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.five);
      expect(matches[0].positions.length, 5);
    });
  });

  group('MatchDetector - vertical matches', () {
    test('detects 3 in a column', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_r, _g],
        [_r, _y],
        [_b, _p],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.three);
      expect(matches[0].gemType, GemType.red);
    });

    test('detects 4 in a column', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_r, _g],
        [_r, _y],
        [_r, _p],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.four);
    });

    test('detects 5 in a column', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_r, _g],
        [_r, _y],
        [_r, _p],
        [_r, _b],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.five);
    });
  });

  group('MatchDetector - L-shape', () {
    test('detects L-shape (bottom-right corner)', () {
      // R R R
      // B G B
      // R B B
      // with R at bottom-left forming an L with top row
      // Actually let's make a clear L:
      // R B B
      // R B B
      // R R R
      final board = Board.fromGrid([
        [_r, _b, _g, _b],
        [_r, _g, _b, _g],
        [_r, _r, _r, _b],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.lShape);
      expect(matches[0].positions.length, 5); // 3 vertical + 3 horizontal - 1 shared
    });

    test('detects L-shape (top-right corner)', () {
      // R R R
      // B B R
      // B G R  -- wait, that would be T not L
      // Let me do:
      // B B R
      // B G R
      // R R R
      // Actually:
      // R R R
      // B G R
      // B B R  -- but R at col2 is 3 vertical, R at row0 is 3 horizontal, sharing (0,2)
      final board = Board.fromGrid([
        [_r, _r, _r, _b],
        [_b, _g, _r, _g],
        [_b, _b, _r, _b],
      ]);
      final matches = detector.findMatches(board);
      // Should find an L-shape: horizontal row0 + vertical col2, sharing (0,2)
      final lMatches = matches.where((m) => m.shape == MatchShape.lShape);
      expect(lMatches.isNotEmpty, isTrue);
    });
  });

  group('MatchDetector - T-shape', () {
    test('detects T-shape (vertical through middle of horizontal)', () {
      // B R B
      // R R R
      // B R B
      final board = Board.fromGrid([
        [_b, _r, _b],
        [_r, _r, _r],
        [_b, _r, _b],
      ]);
      final matches = detector.findMatches(board);
      // horizontal: row 1 (R R R)
      // vertical: col 1 (R R R)
      // They share (1,1) which is middle of both => T-shape
      final tMatches = matches.where((m) => m.shape == MatchShape.tShape);
      expect(tMatches.isNotEmpty, isTrue);
      final t = tMatches.first;
      expect(t.positions.length, 5); // 3+3-1
    });

    test('detects T-shape (horizontal through middle of vertical)', () {
      // B R B B
      // R R R R ... no, let me be precise:
      // B B R B
      // B R R R  -- but that's only a corner
      // Actually the T is when intersection is at middle of one run:
      // R B B
      // R R R
      // R B B
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_r, _r, _r],
        [_r, _b, _g],
      ]);
      final matches = detector.findMatches(board);
      final tMatches = matches.where((m) => m.shape == MatchShape.tShape);
      expect(tMatches.isNotEmpty, isTrue);
    });
  });

  group('MatchDetector - no matches', () {
    test('returns empty for no matches', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_b, _g, _r],
        [_g, _r, _b],
      ]);
      final matches = detector.findMatches(board);
      expect(matches, isEmpty);
    });

    test('two in a row is not a match', () {
      final board = Board.fromGrid([
        [_r, _r, _b],
        [_b, _g, _r],
      ]);
      final matches = detector.findMatches(board);
      expect(matches, isEmpty);
    });
  });

  group('MatchDetector - multiple matches', () {
    test('detects two separate matches', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _b, _b, _b],
        [_g, _y, _g, _y, _g, _y],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 2);
    });
  });

  group('MatchDetector - findAllMatchPositions', () {
    test('returns all positions from all matches', () {
      final board = Board.fromGrid([
        [_r, _r, _r],
        [_b, _g, _y],
      ]);
      final positions = detector.findAllMatchPositions(board);
      expect(positions.length, 3);
      expect(positions, contains(const Position(0, 0)));
      expect(positions, contains(const Position(0, 1)));
      expect(positions, contains(const Position(0, 2)));
    });
  });
}

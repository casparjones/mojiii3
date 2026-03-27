import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/match_detector.dart';
import 'package:match3/game/special_gem_handler.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);
const _y = Gem(type: GemType.yellow);
const _p = Gem(type: GemType.purple);

void main() {
  const handler = SpecialGemHandler();

  group('SpecialGemHandler.determineSpecialGem', () {
    test('match-3 returns null (no special)', () {
      final match = Match(
        positions: {Position(0, 0), Position(0, 1), Position(0, 2)},
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      expect(handler.determineSpecialGem(match), isNull);
    });

    test('match-4 horizontal returns striped vertical', () {
      final match = Match(
        positions: {
          Position(0, 0),
          Position(0, 1),
          Position(0, 2),
          Position(0, 3),
        },
        gemType: GemType.red,
        shape: MatchShape.four,
      );
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
      expect(gem!.special, SpecialType.stripedVertical);
      expect(gem.type, GemType.red);
    });

    test('match-4 vertical returns striped horizontal', () {
      final match = Match(
        positions: {
          Position(0, 0),
          Position(1, 0),
          Position(2, 0),
          Position(3, 0),
        },
        gemType: GemType.blue,
        shape: MatchShape.four,
      );
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
      expect(gem!.special, SpecialType.stripedHorizontal);
    });

    test('match-5 returns rainbow', () {
      final match = Match(
        positions: {
          Position(0, 0),
          Position(0, 1),
          Position(0, 2),
          Position(0, 3),
          Position(0, 4),
        },
        gemType: GemType.green,
        shape: MatchShape.five,
      );
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
      expect(gem!.special, SpecialType.rainbow);
    });

    test('L-shape returns bomb', () {
      final match = Match(
        positions: {
          Position(0, 0),
          Position(1, 0),
          Position(2, 0),
          Position(2, 1),
          Position(2, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.lShape,
      );
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
      expect(gem!.special, SpecialType.bomb);
    });

    test('T-shape returns bomb', () {
      final match = Match(
        positions: {
          Position(0, 1),
          Position(1, 0),
          Position(1, 1),
          Position(1, 2),
          Position(2, 1),
        },
        gemType: GemType.purple,
        shape: MatchShape.tShape,
      );
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
      expect(gem!.special, SpecialType.bomb);
    });
  });

  group('SpecialGemHandler.bestPlacement', () {
    test('prefers swap position if in match', () {
      final match = Match(
        positions: {Position(0, 0), Position(0, 1), Position(0, 2)},
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      final pos =
          handler.bestPlacement(match, swapPosition: const Position(0, 1));
      expect(pos, const Position(0, 1));
    });

    test('falls back to center if swap not in match', () {
      final match = Match(
        positions: {Position(0, 0), Position(0, 1), Position(0, 2)},
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      final pos =
          handler.bestPlacement(match, swapPosition: const Position(1, 1));
      expect(pos, const Position(0, 1)); // center of sorted list
    });

    test('falls back to center if no swap position', () {
      final match = Match(
        positions: {Position(0, 0), Position(0, 1), Position(0, 2)},
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      final pos = handler.bestPlacement(match);
      expect(pos, const Position(0, 1));
    });
  });

  group('SpecialGemHandler.activate', () {
    test('striped horizontal clears entire row', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.stripedHorizontal), _b, _g, _y],
        [_p, _r, _b, _g],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      expect(cleared.length, 4);
      for (var c = 0; c < 4; c++) {
        expect(cleared, contains(Position(0, c)));
      }
    });

    test('striped vertical clears entire column', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.stripedVertical), _b],
        [_p, _r],
        [_g, _y],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      expect(cleared.length, 3);
      for (var r = 0; r < 3; r++) {
        expect(cleared, contains(Position(r, 0)));
      }
    });

    test('bomb clears 3x3 area', () {
      final board = Board.fromGrid([
        [_r, _b, _g, _y],
        [_p, const Gem(type: GemType.red, special: SpecialType.bomb), _b, _g],
        [_g, _y, _p, _r],
        [_b, _r, _g, _y],
      ]);
      final cleared = handler.activate(board, const Position(1, 1));
      // 3x3 around (1,1): rows 0-2, cols 0-2
      expect(cleared.length, 9);
      for (var r = 0; r <= 2; r++) {
        for (var c = 0; c <= 2; c++) {
          expect(cleared, contains(Position(r, c)));
        }
      }
    });

    test('bomb at corner clips to board bounds', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.bomb), _b, _g],
        [_p, _r, _b],
        [_g, _y, _p],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      // Only (0,0), (0,1), (1,0), (1,1) since row-1 and col-1 are out of bounds
      expect(cleared.length, 4);
      expect(cleared, contains(const Position(0, 0)));
      expect(cleared, contains(const Position(0, 1)));
      expect(cleared, contains(const Position(1, 0)));
      expect(cleared, contains(const Position(1, 1)));
    });

    test('rainbow clears all gems of same type', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.rainbow), _b, _r],
        [_g, _r, _b],
        [_r, _y, _g],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      // All red gems: (0,0), (0,2), (1,1), (2,0)
      expect(cleared, contains(const Position(0, 0)));
      expect(cleared, contains(const Position(0, 2)));
      expect(cleared, contains(const Position(1, 1)));
      expect(cleared, contains(const Position(2, 0)));
      expect(cleared.length, 4);
    });

    test('normal gem returns just its position', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _y],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      expect(cleared, {const Position(0, 0)});
    });

    test('null cell returns empty set', () {
      final board = Board.fromGrid([
        [null, _b],
        [_g, _y],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      expect(cleared, isEmpty);
    });
  });
}

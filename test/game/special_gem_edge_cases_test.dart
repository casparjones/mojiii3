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

void main() {
  const handler = SpecialGemHandler();

  group('SpecialGemHandler.activate edge cases', () {
    test('bomb at bottom-right corner clips correctly', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_y, _r, _b],
        [_g, _y, const Gem(type: GemType.red, special: SpecialType.bomb)],
      ]);
      final cleared = handler.activate(board, const Position(2, 2));
      // 3x3 around (2,2): only (1,1),(1,2),(2,1),(2,2) are in bounds
      expect(cleared.length, 4);
      expect(cleared, contains(const Position(1, 1)));
      expect(cleared, contains(const Position(1, 2)));
      expect(cleared, contains(const Position(2, 1)));
      expect(cleared, contains(const Position(2, 2)));
    });

    test('bomb on edge (middle of top row) clips top', () {
      final board = Board.fromGrid([
        [_r, const Gem(type: GemType.red, special: SpecialType.bomb), _g],
        [_y, _r, _b],
        [_g, _y, _r],
      ]);
      final cleared = handler.activate(board, const Position(0, 1));
      // Row -1 is out of bounds, so we get 6 cells: (0,0-2) and (1,0-2)
      expect(cleared.length, 6);
    });

    test('striped horizontal on 1-column board clears just one cell', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.stripedHorizontal)],
        [_b],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      expect(cleared.length, 1);
      expect(cleared, contains(const Position(0, 0)));
    });

    test('striped vertical on 1-row board clears just one cell', () {
      final board = Board.fromGrid([
        [_b, const Gem(type: GemType.red, special: SpecialType.stripedVertical), _g],
      ]);
      final cleared = handler.activate(board, const Position(0, 1));
      expect(cleared.length, 1);
      expect(cleared, contains(const Position(0, 1)));
    });

    test('rainbow with no other gems of same type clears only itself', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.rainbow), _b, _g],
        [_y, _b, _g],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      // Only (0,0) because no other red gems
      expect(cleared.length, 1);
      expect(cleared, contains(const Position(0, 0)));
    });

    test('rainbow clears all gems of type including specials', () {
      final board = Board.fromGrid([
        [const Gem(type: GemType.red, special: SpecialType.rainbow), _b, _g],
        [_y, const Gem(type: GemType.red, special: SpecialType.bomb), _g],
        [_r, _b, _r],
      ]);
      final cleared = handler.activate(board, const Position(0, 0));
      // All red gems: (0,0), (1,1), (2,0), (2,2)
      expect(cleared.length, 4);
      expect(cleared, contains(const Position(0, 0)));
      expect(cleared, contains(const Position(1, 1)));
      expect(cleared, contains(const Position(2, 0)));
      expect(cleared, contains(const Position(2, 2)));
    });

    test('activate out of bounds returns empty', () {
      final board = Board.fromGrid([
        [_r, _b],
      ]);
      final cleared = handler.activate(board, const Position(5, 5));
      expect(cleared, isEmpty);
    });
  });

  group('SpecialGemHandler.determineSpecialGem edge cases', () {
    test('special gem preserves base gem type', () {
      for (final gemType in GemType.values) {
        final match5 = Match(
          positions: {
            Position(0, 0), Position(0, 1), Position(0, 2),
            Position(0, 3), Position(0, 4),
          },
          gemType: gemType,
          shape: MatchShape.five,
        );
        final gem = handler.determineSpecialGem(match5);
        expect(gem!.type, gemType,
            reason: 'Rainbow should preserve $gemType');
      }
    });

    test('match-4 direction detection: single position is treated as horizontal', () {
      // Edge case: single-position match (shouldn't happen in practice)
      final match = Match(
        positions: {Position(0, 0)},
        gemType: GemType.red,
        shape: MatchShape.four,
      );
      // Should not throw
      final gem = handler.determineSpecialGem(match);
      expect(gem, isNotNull);
    });
  });

  group('SpecialGemHandler.bestPlacement edge cases', () {
    test('single position match returns that position', () {
      final match = Match(
        positions: {const Position(3, 3)},
        gemType: GemType.red,
        shape: MatchShape.three,
      );
      final pos = handler.bestPlacement(match);
      expect(pos, const Position(3, 3));
    });

    test('bestPlacement with L-shape picks center element', () {
      final match = Match(
        positions: {
          Position(0, 0), Position(1, 0), Position(2, 0),
          Position(2, 1), Position(2, 2),
        },
        gemType: GemType.red,
        shape: MatchShape.lShape,
      );
      final pos = handler.bestPlacement(match);
      // Sorted: (0,0),(1,0),(2,0),(2,1),(2,2) -- middle index 2 => (2,0)
      expect(pos, const Position(2, 0));
    });

    test('bestPlacement prefers swap over center', () {
      final match = Match(
        positions: {
          Position(0, 0), Position(0, 1), Position(0, 2),
          Position(0, 3), Position(0, 4),
        },
        gemType: GemType.red,
        shape: MatchShape.five,
      );
      final pos = handler.bestPlacement(match, swapPosition: const Position(0, 4));
      expect(pos, const Position(0, 4));
    });
  });

  group('Integration: MatchDetector + SpecialGemHandler', () {
    test('detected 4-in-a-row produces correct special gem', () {
      const detector = MatchDetector();
      final board = Board.fromGrid([
        [_r, _r, _r, _r, _b],
        [_b, _g, _y, _b, _g],
      ]);
      final matches = detector.findMatches(board);
      expect(matches.length, 1);
      expect(matches[0].shape, MatchShape.four);

      final gem = handler.determineSpecialGem(matches[0]);
      expect(gem!.special, SpecialType.stripedVertical);
    });

    test('detected L-shape produces bomb', () {
      const detector = MatchDetector();
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_r, _g, _b],
        [_r, _r, _r],
      ]);
      final matches = detector.findMatches(board);
      final lMatches = matches.where((m) => m.shape == MatchShape.lShape || m.shape == MatchShape.tShape);
      expect(lMatches.isNotEmpty, isTrue);

      final gem = handler.determineSpecialGem(lMatches.first);
      expect(gem!.special, SpecialType.bomb);
    });
  });
}

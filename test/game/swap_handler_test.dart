import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/swap_handler.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);
const _y = Gem(type: GemType.yellow);
const _p = Gem(type: GemType.purple);

void main() {
  const handler = SwapHandler();

  group('SwapHandler - valid swaps', () {
    test('successful swap that creates a match', () {
      // Before swap:  R B R R
      // Swap (0,0) with (0,1) => B R R R => match!
      final board = Board.fromGrid([
        [_b, _r, _r, _r],
      ]);
      // Actually this already has a match. Let me set up properly:
      // R B R R  -- swap (0,0)<->(0,1) => B R R R => match at col 1,2,3
      final board2 = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _g],
      ]);
      // No, swap col0<->col1 => B R R R, but that's only 3 R at col1,2,3. Wait,
      // after swap: B at (0,0), R at (0,1), R at (0,2), R at (0,3) => match!
      final result = handler.trySwap(board2, const Position(0, 0), const Position(0, 1));
      expect(result, SwapResult.success);
      // After success, the swap stays
      expect(board2.gemAt(const Position(0, 0))!.type, GemType.blue);
      expect(board2.gemAt(const Position(0, 1))!.type, GemType.red);
    });

    test('swap that creates vertical match', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_r, _g],
        [_b, _r],  // swap (2,0)<->(2,1) => R at col0 becomes 3 vertical
      ]);
      // Wait, (2,0) is B, (2,1) is R. After swap: (2,0)=R, (2,1)=B
      // col 0: R,R,R => match!
      final result = handler.trySwap(board, const Position(2, 0), const Position(2, 1));
      expect(result, SwapResult.success);
    });
  });

  group('SwapHandler - invalid swaps', () {
    test('swap with no match reverts', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_g, _y, _p],
        [_p, _r, _b],
      ]);
      final original00 = board.gemAt(const Position(0, 0))!.type;
      final original01 = board.gemAt(const Position(0, 1))!.type;

      final result = handler.trySwap(board, const Position(0, 0), const Position(0, 1));
      expect(result, SwapResult.noMatch);

      // Board should be reverted
      expect(board.gemAt(const Position(0, 0))!.type, original00);
      expect(board.gemAt(const Position(0, 1))!.type, original01);
    });

    test('non-adjacent swap rejected', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_g, _y, _p],
      ]);
      final result = handler.trySwap(board, const Position(0, 0), const Position(0, 2));
      expect(result, SwapResult.notAdjacent);
    });

    test('diagonal swap rejected', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _y],
      ]);
      final result = handler.trySwap(board, const Position(0, 0), const Position(1, 1));
      expect(result, SwapResult.notAdjacent);
    });

    test('out of bounds swap rejected', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _y],
      ]);
      final result = handler.trySwap(board, const Position(0, 0), const Position(-1, 0));
      expect(result, SwapResult.invalid);
    });

    test('swap with null cell rejected', () {
      final board = Board.fromGrid([
        [_r, null],
        [_g, _y],
      ]);
      final result = handler.trySwap(board, const Position(0, 0), const Position(0, 1));
      expect(result, SwapResult.invalid);
    });
  });

  group('SwapHandler - forceSwap', () {
    test('forces swap without validation', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _y],
      ]);
      handler.forceSwap(board, const Position(0, 0), const Position(0, 1));
      expect(board.gemAt(const Position(0, 0))!.type, GemType.blue);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.red);
    });
  });
}

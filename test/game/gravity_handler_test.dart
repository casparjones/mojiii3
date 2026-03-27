import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/gravity_handler.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);

void main() {
  group('GravityHandler.applyGravity', () {
    late GravityHandler handler;

    setUp(() {
      handler = GravityHandler(random: Random(42));
    });

    test('gems fall down to fill gaps', () {
      final board = Board.fromGrid([
        [_r, _b],
        [null, _g],
        [null, _r],
      ]);
      final moved = handler.applyGravity(board);
      expect(moved, 1);
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0)), isNull);
      expect(board.gemAt(const Position(2, 0))!.type, GemType.red);
    });

    test('multiple gems fall in same column', () {
      final board = Board.fromGrid([
        [_r, _b],
        [null, _g],
        [_g, _r],
        [null, _b],
      ]);
      handler.applyGravity(board);
      // Column 0: R, null, G, null => null, null, R, G
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0)), isNull);
      expect(board.gemAt(const Position(2, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(3, 0))!.type, GemType.green);
    });

    test('no movement when no gaps', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _r],
      ]);
      final moved = handler.applyGravity(board);
      expect(moved, 0);
    });

    test('all null column stays null', () {
      final board = Board.fromGrid([
        [null, _b],
        [null, _g],
      ]);
      handler.applyGravity(board);
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0)), isNull);
    });

    test('gap in middle is filled from above', () {
      final board = Board.fromGrid([
        [_r],
        [_b],
        [null],
        [_g],
      ]);
      handler.applyGravity(board);
      // R, B, null, G => null, R, B, G
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(2, 0))!.type, GemType.blue);
      expect(board.gemAt(const Position(3, 0))!.type, GemType.green);
    });
  });

  group('GravityHandler.refill', () {
    late GravityHandler handler;

    setUp(() {
      handler = GravityHandler(gemTypeCount: 3, random: Random(42));
    });

    test('fills null cells with random gems', () {
      final board = Board.fromGrid([
        [null, _b],
        [_g, null],
      ]);
      final spawned = handler.refill(board);
      expect(spawned, 2);
      expect(board.gemAt(const Position(0, 0)), isNotNull);
      expect(board.gemAt(const Position(1, 1)), isNotNull);
    });

    test('does not change existing gems', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, null],
      ]);
      handler.refill(board);
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(0, 1))!.type, GemType.blue);
      expect(board.gemAt(const Position(1, 0))!.type, GemType.green);
    });

    test('returns 0 when board is full', () {
      final board = Board.fromGrid([
        [_r, _b],
        [_g, _r],
      ]);
      final spawned = handler.refill(board);
      expect(spawned, 0);
    });

    test('only uses allowed gem types', () {
      final board = Board.fromGrid([
        [null, null, null, null],
        [null, null, null, null],
      ]);
      handler.refill(board);
      final allowedTypes = {GemType.red, GemType.blue, GemType.green};
      for (var r = 0; r < 2; r++) {
        for (var c = 0; c < 4; c++) {
          expect(allowedTypes.contains(board.gemAt(Position(r, c))!.type),
              isTrue);
        }
      }
    });
  });
}

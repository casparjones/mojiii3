import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/cascade_engine.dart';
import 'package:match3/game/gravity_handler.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/models/position.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);
const _y = Gem(type: GemType.yellow);
const _p = Gem(type: GemType.purple);
const _o = Gem(type: GemType.orange);

void main() {
  group('GravityHandler edge cases', () {
    late GravityHandler handler;

    setUp(() {
      handler = GravityHandler(gemTypeCount: 6, random: Random(42));
    });

    test('empty board (no rows)', () {
      final board = Board.fromGrid([]);
      final moved = handler.applyGravity(board);
      expect(moved, 0);
      final spawned = handler.refill(board);
      expect(spawned, 0);
    });

    test('single cell board with gem stays unchanged', () {
      final board = Board.fromGrid([
        [_r],
      ]);
      final moved = handler.applyGravity(board);
      expect(moved, 0);
      expect(board.gemAt(const Position(0, 0))!.type, GemType.red);
    });

    test('single cell board with null gets refilled', () {
      final board = Board.fromGrid([
        [null],
      ]);
      handler.applyGravity(board);
      handler.refill(board);
      expect(board.gemAt(const Position(0, 0)), isNotNull);
    });

    test('gravity preserves column independence', () {
      final board = Board.fromGrid([
        [_r, null],
        [null, _b],
      ]);
      handler.applyGravity(board);
      // Col 0: R falls to row 1
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0))!.type, GemType.red);
      // Col 1: B stays at row 1
      expect(board.gemAt(const Position(1, 1))!.type, GemType.blue);
    });

    test('gravity with bottom null and gem above', () {
      final board = Board.fromGrid([
        [null],
        [null],
        [_r],
        [null],
      ]);
      handler.applyGravity(board);
      // R should fall to row 3
      expect(board.gemAt(const Position(3, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(2, 0)), isNull);
    });

    test('gravity with alternating null/gem pattern', () {
      final board = Board.fromGrid([
        [_r],
        [null],
        [_b],
        [null],
        [_g],
        [null],
      ]);
      handler.applyGravity(board);
      // All gems should compact to bottom
      expect(board.gemAt(const Position(3, 0))!.type, GemType.red);
      expect(board.gemAt(const Position(4, 0))!.type, GemType.blue);
      expect(board.gemAt(const Position(5, 0))!.type, GemType.green);
      expect(board.gemAt(const Position(0, 0)), isNull);
      expect(board.gemAt(const Position(1, 0)), isNull);
      expect(board.gemAt(const Position(2, 0)), isNull);
    });

    test('refill fills entire empty board', () {
      final board = Board.fromGrid([
        [null, null, null],
        [null, null, null],
        [null, null, null],
      ]);
      final spawned = handler.refill(board);
      expect(spawned, 9);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(board.gemAt(Position(r, c)), isNotNull,
              reason: 'Cell ($r,$c) should be filled');
        }
      }
    });

    test('gravity returns correct moved count for full column drop', () {
      final board = Board.fromGrid([
        [_r],
        [_b],
        [_g],
        [null],
        [null],
        [null],
      ]);
      final moved = handler.applyGravity(board);
      expect(moved, 3); // All 3 gems move down
    });
  });

  group('CascadeEngine edge cases', () {
    test('cascade with no matches returns empty result', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_g, _r, _b],
        [_b, _g, _r],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);
      expect(result.hadMatches, isFalse);
      expect(result.cascadeCount, 0);
      expect(result.totalGemsCleared, 0);
    });

    test('cascade clears board and refills completely', () {
      // Board entirely of one type -- massive match
      final grid = List.generate(
        4,
        (_) => List.generate(4, (_) => _r),
      );
      final board = Board.fromGrid(grid);
      final engine = CascadeEngine(gemTypeCount: 6, random: Random(42));
      final result = engine.resolve(board);

      expect(result.hadMatches, isTrue);
      expect(result.totalGemsCleared, greaterThanOrEqualTo(16));
      expect(board.hasEmptyCells, isFalse);
    });

    test('CascadeResult.totalGemsCleared sums across steps', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _b, _b, _b],
        [_g, _y, _p, _o, _g, _y],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);

      var manualTotal = 0;
      for (final step in result.steps) {
        manualTotal += step.gemsCleared;
      }
      expect(result.totalGemsCleared, manualTotal);
    });

    test('CascadeStep.gemsCleared deduplicates overlapping matches', () {
      // L/T shaped match where positions overlap
      final board = Board.fromGrid([
        [_r, _r, _r],
        [_b, _r, _g],
        [_b, _r, _g],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);

      expect(result.hadMatches, isTrue);
      // The L/T match has 5 unique positions, not 6 (shared corner)
      expect(result.steps[0].gemsCleared, 5);
    });

    test('cascade terminates within maxCascades', () {
      // Even worst case should terminate
      final board = Board.fromGrid([
        [_r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r],
      ]);
      final engine = CascadeEngine(gemTypeCount: 6, random: Random(42));
      final result = engine.resolve(board);

      // Should terminate and leave a valid board
      expect(result.steps.length, lessThanOrEqualTo(CascadeEngine.maxCascades));
      expect(board.hasEmptyCells, isFalse);
    });

    test('cascade multiplier progression is correct', () {
      // Create a scenario likely to cascade multiple times
      final board = Board.fromGrid([
        [_r, _r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r, _r],
        [_r, _r, _r, _r, _r, _r],
      ]);
      final engine = CascadeEngine(gemTypeCount: 6, random: Random(42));
      final result = engine.resolve(board);

      for (var i = 0; i < result.steps.length; i++) {
        final expected = 1.0 + i * 0.5;
        expect(result.steps[i].multiplier, expected,
            reason: 'Step ${i + 1} multiplier should be $expected');
      }
    });

    test('single column board cascades correctly', () {
      final board = Board.fromGrid([
        [_r],
        [_r],
        [_r],
        [_b],
      ]);
      final engine = CascadeEngine(gemTypeCount: 6, random: Random(42));
      final result = engine.resolve(board);

      expect(result.hadMatches, isTrue);
      expect(result.steps[0].gemsCleared, 3);
      expect(board.hasEmptyCells, isFalse);
    });
  });
}

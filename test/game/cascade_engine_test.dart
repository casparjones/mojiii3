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
  group('CascadeEngine', () {
    test('resolves single match', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _b],
        [_b, _g, _y, _p],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);

      expect(result.hadMatches, isTrue);
      expect(result.steps.isNotEmpty, isTrue);
      expect(result.steps[0].cascadeLevel, 1);
      expect(result.steps[0].gemsCleared, 3);
      // After resolution, board should be full
      expect(board.hasEmptyCells, isFalse);
    });

    test('no matches returns empty result', () {
      final board = Board.fromGrid([
        [_r, _b, _g],
        [_b, _g, _r],
        [_g, _r, _b],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);

      expect(result.hadMatches, isFalse);
      expect(result.cascadeCount, 0);
      expect(result.totalGemsCleared, 0);
    });

    test('cascade multiplier increases per level', () {
      // Create a board that will cascade
      final board = Board.fromGrid([
        [_r, _r, _r, _b],
        [_b, _g, _y, _p],
      ]);
      final engine = CascadeEngine(random: Random(42));
      final result = engine.resolve(board);

      if (result.steps.isNotEmpty) {
        expect(result.steps[0].multiplier, 1.0);
      }
      if (result.steps.length > 1) {
        expect(result.steps[1].multiplier, 1.5);
      }
    });

    test('board is full after cascade resolution', () {
      final board = Board.fromGrid([
        [_r, _r, _r, _b, _g],
        [_b, _g, _y, _p, _o],
        [_g, _y, _b, _r, _p],
      ]);
      final engine = CascadeEngine(random: Random(42));
      engine.resolve(board);

      for (var r = 0; r < board.rows; r++) {
        for (var c = 0; c < board.cols; c++) {
          expect(board.gemAt(Position(r, c)), isNotNull,
              reason: 'Cell ($r, $c) should not be null after cascade');
        }
      }
    });

    test('resolves eventually (does not loop forever)', () {
      // Even with bad random seeds, should terminate
      final board = Board.fromGrid([
        [_r, _r, _r],
        [_r, _r, _r],
        [_r, _r, _r],
      ]);
      final engine = CascadeEngine(gemTypeCount: 6, random: Random(42));
      final result = engine.resolve(board);

      // Should have resolved
      expect(result.hadMatches, isTrue);
      expect(board.hasEmptyCells, isFalse);
    });
  });

  group('CascadeStep', () {
    test('multiplier formula is correct', () {
      // Level 1 => 1.0, level 2 => 1.5, level 3 => 2.0
      const step1 = CascadeStep(matches: [], cascadeLevel: 1);
      const step2 = CascadeStep(matches: [], cascadeLevel: 2);
      const step3 = CascadeStep(matches: [], cascadeLevel: 3);

      expect(step1.multiplier, 1.0);
      expect(step2.multiplier, 1.5);
      expect(step3.multiplier, 2.0);
    });
  });
}

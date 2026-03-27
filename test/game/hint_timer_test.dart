import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/hint_timer.dart';
import 'package:match3/game/deadlock_detector.dart';
import 'package:match3/models/board.dart';
import 'package:match3/models/gem_type.dart';

const _r = Gem(type: GemType.red);
const _b = Gem(type: GemType.blue);
const _g = Gem(type: GemType.green);
const _y = Gem(type: GemType.yellow);
const _p = Gem(type: GemType.purple);
const _o = Gem(type: GemType.orange);

void main() {
  group('HintTimer', () {
    test('showHintNow returns hint when moves exist', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      final timer = HintTimer();
      final hint = timer.showHintNow(board);
      expect(hint, isNotNull);
      expect(timer.currentHint, isNotNull);
    });

    test('onHint callback fires when hint found', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      Hint? received;
      final timer = HintTimer(onHint: (h) => received = h);
      timer.showHintNow(board);
      expect(received, isNotNull);
    });

    test('dispose clears hint and stops timer', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      final timer = HintTimer(
        inactivityDuration: const Duration(seconds: 1),
      );
      timer.resetTimer(board);
      expect(timer.isRunning, isTrue);

      timer.dispose();
      expect(timer.isRunning, isFalse);
      expect(timer.currentHint, isNull);
    });

    test('resetTimer starts the timer', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      final timer = HintTimer(
        inactivityDuration: const Duration(seconds: 5),
      );
      timer.resetTimer(board);
      expect(timer.isRunning, isTrue);
      timer.dispose();
    });

    test('resetTimer clears previous hint', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      final timer = HintTimer();
      timer.showHintNow(board);
      expect(timer.currentHint, isNotNull);

      timer.resetTimer(board);
      expect(timer.currentHint, isNull);
      timer.dispose();
    });

    test('showHintNow cancels running timer', () {
      final board = Board.fromGrid([
        [_r, _b, _r, _r],
        [_g, _y, _p, _o],
      ]);
      final timer = HintTimer(
        inactivityDuration: const Duration(seconds: 10),
      );
      timer.resetTimer(board);
      expect(timer.isRunning, isTrue);

      timer.showHintNow(board);
      expect(timer.isRunning, isFalse);
      timer.dispose();
    });
  });
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';

void main() {
  group('SaveState bonusMoves and regeneration', () {
    test('bonusMoves defaults to 0', () {
      final save = SaveState();
      expect(save.bonusMoves, 0);
    });

    test('lastMoveRegenTime defaults to null', () {
      final save = SaveState();
      expect(save.lastMoveRegenTime, isNull);
    });

    test('regenerateMoves initializes lastMoveRegenTime on first call', () {
      final save = SaveState();
      expect(save.lastMoveRegenTime, isNull);
      final result = save.regenerateMoves();
      expect(result, 0);
      expect(save.lastMoveRegenTime, isNotNull);
    });

    test('regenerateMoves adds 1 move per 5 minutes', () {
      final save = SaveState();
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 15),
      );
      final result = save.regenerateMoves();
      expect(result, 3);
      expect(save.bonusMoves, 3);
    });

    test('regenerateMoves caps at maxBonusMoves (60)', () {
      final save = SaveState();
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(hours: 10),
      );
      final result = save.regenerateMoves();
      expect(result, 60);
      expect(save.bonusMoves, 60);
    });

    test('regenerateMoves respects existing bonusMoves', () {
      final save = SaveState(bonusMoves: 58);
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 25),
      );
      final result = save.regenerateMoves();
      expect(result, 2); // Can only add 2 more (58 + 2 = 60)
      expect(save.bonusMoves, 60);
    });

    test('regenerateMoves returns 0 if less than 5 minutes elapsed', () {
      final save = SaveState();
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 4),
      );
      final result = save.regenerateMoves();
      expect(result, 0);
      expect(save.bonusMoves, 0);
    });

    test('regenerateMoves returns 0 if already at max', () {
      final save = SaveState(bonusMoves: 60);
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 30),
      );
      final result = save.regenerateMoves();
      expect(result, 0);
      expect(save.bonusMoves, 60);
    });

    test('consumeBonusMoves returns count and resets to 0', () {
      final save = SaveState(bonusMoves: 7);
      final consumed = save.consumeBonusMoves();
      expect(consumed, 7);
      expect(save.bonusMoves, 0);
    });

    test('consumeBonusMoves returns 0 when none stored', () {
      final save = SaveState();
      final consumed = save.consumeBonusMoves();
      expect(consumed, 0);
    });

    test('bonusMoves serializes to JSON', () {
      final save = SaveState(bonusMoves: 5);
      save.lastMoveRegenTime = DateTime(2025, 6, 15, 10, 30);
      final json = save.toJson();
      expect(json['bonusMoves'], 5);
      expect(json['lastMoveRegenTime'], '2025-06-15T10:30:00.000');
    });

    test('bonusMoves deserializes from JSON', () {
      final json = {
        'bonusMoves': 3,
        'lastMoveRegenTime': '2025-06-15T10:30:00.000',
      };
      final save = SaveState.fromJson(json);
      expect(save.bonusMoves, 3);
      expect(save.lastMoveRegenTime, DateTime(2025, 6, 15, 10, 30));
    });

    test('bonusMoves defaults when missing from JSON', () {
      final save = SaveState.fromJson({});
      expect(save.bonusMoves, 0);
      expect(save.lastMoveRegenTime, isNull);
    });

    test('round-trip serialization preserves bonusMoves', () {
      final save = SaveState(bonusMoves: 4);
      save.lastMoveRegenTime = DateTime(2025, 1, 1, 12, 0);
      final jsonStr = save.toJsonString();
      final restored = SaveState.fromJsonString(jsonStr);
      expect(restored.bonusMoves, 4);
      expect(restored.lastMoveRegenTime, DateTime(2025, 1, 1, 12, 0));
    });
  });
}

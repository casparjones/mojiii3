import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';

void main() {
  group('SaveState Power-Up Inventory', () {
    test('powerUpCount returns 0 for unowned power-ups', () {
      final state = SaveState();
      expect(state.powerUpCount('powerup_extra_moves'), 0);
      expect(state.powerUpCount('powerup_shuffle'), 0);
      expect(state.powerUpCount('powerup_color_bomb'), 0);
    });

    test('addPowerUp increases count', () {
      final state = SaveState();
      state.addPowerUp('powerup_extra_moves');
      expect(state.powerUpCount('powerup_extra_moves'), 1);
      state.addPowerUp('powerup_extra_moves', count: 3);
      expect(state.powerUpCount('powerup_extra_moves'), 4);
    });

    test('usePowerUp decrements and returns true when available', () {
      final state = SaveState();
      state.addPowerUp('powerup_shuffle', count: 2);
      expect(state.usePowerUp('powerup_shuffle'), true);
      expect(state.powerUpCount('powerup_shuffle'), 1);
      expect(state.usePowerUp('powerup_shuffle'), true);
      expect(state.powerUpCount('powerup_shuffle'), 0);
    });

    test('usePowerUp returns false when none available', () {
      final state = SaveState();
      expect(state.usePowerUp('powerup_extra_moves'), false);
      expect(state.powerUpCount('powerup_extra_moves'), 0);
    });

    test('usePowerUp returns false when count is zero', () {
      final state = SaveState();
      state.addPowerUp('powerup_color_bomb', count: 1);
      expect(state.usePowerUp('powerup_color_bomb'), true);
      expect(state.usePowerUp('powerup_color_bomb'), false);
    });

    test('powerUpInventory serializes to JSON and back', () {
      final state = SaveState();
      state.addPowerUp('powerup_extra_moves', count: 3);
      state.addPowerUp('powerup_shuffle', count: 1);
      state.addPowerUp('powerup_color_bomb', count: 2);
      state.tutorialShown = true;

      final json = state.toJson();
      final restored = SaveState.fromJson(json);

      expect(restored.powerUpCount('powerup_extra_moves'), 3);
      expect(restored.powerUpCount('powerup_shuffle'), 1);
      expect(restored.powerUpCount('powerup_color_bomb'), 2);
      expect(restored.tutorialShown, true);
    });

    test('powerUpInventory round-trips through JSON string', () {
      final state = SaveState();
      state.addPowerUp('powerup_extra_moves', count: 5);

      final jsonString = state.toJsonString();
      final restored = SaveState.fromJsonString(jsonString);

      expect(restored.powerUpCount('powerup_extra_moves'), 5);
    });

    test('tutorialShown defaults to false', () {
      final state = SaveState();
      expect(state.tutorialShown, false);
    });

    test('tutorialShown deserializes from JSON', () {
      final state = SaveState.fromJson({'tutorialShown': true});
      expect(state.tutorialShown, true);
    });

    test('missing powerUpInventory in JSON defaults to empty', () {
      final state = SaveState.fromJson({});
      expect(state.powerUpCount('powerup_extra_moves'), 0);
      expect(state.tutorialShown, false);
    });
  });
}

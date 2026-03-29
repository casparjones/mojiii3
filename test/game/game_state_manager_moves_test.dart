import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';

void main() {
  group('GameStateManager bonus moves', () {
    test('regenerateMoves delegates to saveState', () {
      final save = SaveState(bonusMoves: 0);
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 10),
      );
      final gsm = GameStateManager(saveState: save);

      final result = gsm.regenerateMoves();
      expect(result, 2);
      expect(save.bonusMoves, 2);
    });

    test('regenerateMoves returns 0 when nothing to regenerate', () {
      final save = SaveState(bonusMoves: 0);
      save.lastMoveRegenTime = DateTime.now().subtract(
        const Duration(minutes: 4),
      );
      final gsm = GameStateManager(saveState: save);

      final result = gsm.regenerateMoves();
      expect(result, 0);
    });

    test('persistState notifies listeners', () {
      final gsm = GameStateManager();
      int notifyCount = 0;
      gsm.addListener(() => notifyCount++);

      gsm.persistState();
      expect(notifyCount, 1);
    });
  });

  group('GameStateManager shop power-ups', () {
    test('mega moves power-up can be added and used via saveState', () {
      final save = SaveState();
      save.addPowerUp('powerup_mega_moves', count: 2);
      expect(save.powerUpCount('powerup_mega_moves'), 2);

      final used = save.usePowerUp('powerup_mega_moves');
      expect(used, true);
      expect(save.powerUpCount('powerup_mega_moves'), 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/audio_manager.dart';
import 'package:match3/game/game_state_manager.dart';

void main() {
  group('AudioManager edge cases', () {
    test('lastPlayedSound updates to most recent sound', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playMatch();
      expect(audio.lastPlayedSound, 'match');
      audio.playSwap();
      expect(audio.lastPlayedSound, 'swap');
      audio.playTap();
      expect(audio.lastPlayedSound, 'tap');
    });

    test('lastPlayedSound does not change when sound is disabled', () {
      final settings = GameSettings(soundEnabled: true);
      final audio = AudioManager(settingsProvider: () => settings);

      audio.playMatch();
      expect(audio.lastPlayedSound, 'match');

      settings.soundEnabled = false;
      audio.playSwap();
      // Should still show 'match' since swap was not played
      expect(audio.lastPlayedSound, 'match');
    });

    test('all 6 sound types produce correct sound names', () {
      final audio = AudioManager.alwaysEnabled();
      final expectedSounds = {
        'match': audio.playMatch,
        'swap': audio.playSwap,
        'combo': audio.playCombo,
        'win': audio.playWin,
        'lose': audio.playLose,
        'tap': audio.playTap,
      };

      for (final entry in expectedSounds.entries) {
        entry.value();
        expect(audio.lastPlayedSound, entry.key);
      }
      expect(audio.playCount, 6);
    });

    test('rapid successive plays all count', () {
      final audio = AudioManager.alwaysEnabled();
      for (int i = 0; i < 100; i++) {
        audio.playTap();
      }
      expect(audio.playCount, 100);
    });

    test('debugLog does not throw with enabled logging', () {
      final audio = AudioManager.alwaysEnabled(debugLog: true);
      expect(() => audio.playMatch(), returnsNormally);
      expect(() => audio.playSwap(), returnsNormally);
      expect(() => audio.playCombo(), returnsNormally);
    });

    test('custom settingsProvider is called each time', () {
      int callCount = 0;
      final settings = GameSettings(soundEnabled: true);
      final audio = AudioManager(
        settingsProvider: () {
          callCount++;
          return settings;
        },
      );

      audio.playMatch();
      audio.playSwap();
      audio.playCombo();
      expect(callCount, 3);
    });

    test('dispose can be called multiple times without error', () {
      final audio = AudioManager.alwaysEnabled();
      audio.dispose();
      audio.dispose();
      // Should not throw
    });

    test('sounds work after dispose is called', () {
      final audio = AudioManager.alwaysEnabled();
      audio.dispose();
      // Since dispose is a stub, sounds should still work
      audio.playMatch();
      expect(audio.lastPlayedSound, 'match');
    });

    test('toggling sound multiple times during usage', () {
      final settings = GameSettings(soundEnabled: true);
      final audio = AudioManager(settingsProvider: () => settings);

      audio.playMatch(); // plays
      settings.soundEnabled = false;
      audio.playSwap(); // skipped
      settings.soundEnabled = true;
      audio.playCombo(); // plays
      settings.soundEnabled = false;
      audio.playWin(); // skipped
      audio.playLose(); // skipped
      settings.soundEnabled = true;
      audio.playTap(); // plays

      expect(audio.playCount, 3);
      expect(audio.lastPlayedSound, 'tap');
    });
  });
}

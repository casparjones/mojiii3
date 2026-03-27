import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/audio_manager.dart';
import 'package:match3/game/game_state_manager.dart';

void main() {
  group('AudioManager', () {
    test('plays sound when sound is enabled', () {
      final audio = AudioManager.alwaysEnabled();
      expect(audio.isSoundEnabled, true);

      audio.playMatch();
      expect(audio.lastPlayedSound, 'match');
      expect(audio.playCount, 1);
    });

    test('does not play sound when sound is disabled', () {
      final audio = AudioManager.disabled();
      expect(audio.isSoundEnabled, false);

      audio.playMatch();
      expect(audio.lastPlayedSound, isNull);
      expect(audio.playCount, 0);
    });

    test('playMatch sets lastPlayedSound to match', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playMatch();
      expect(audio.lastPlayedSound, 'match');
    });

    test('playSwap sets lastPlayedSound to swap', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playSwap();
      expect(audio.lastPlayedSound, 'swap');
    });

    test('playCombo sets lastPlayedSound to combo', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playCombo();
      expect(audio.lastPlayedSound, 'combo');
    });

    test('playWin sets lastPlayedSound to win', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playWin();
      expect(audio.lastPlayedSound, 'win');
    });

    test('playLose sets lastPlayedSound to lose', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playLose();
      expect(audio.lastPlayedSound, 'lose');
    });

    test('playTap sets lastPlayedSound to tap', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playTap();
      expect(audio.lastPlayedSound, 'tap');
    });

    test('playCount increments for each sound played', () {
      final audio = AudioManager.alwaysEnabled();
      audio.playMatch();
      audio.playSwap();
      audio.playCombo();
      expect(audio.playCount, 3);
    });

    test('playCount does not increment when sound is disabled', () {
      final audio = AudioManager.disabled();
      audio.playMatch();
      audio.playSwap();
      expect(audio.playCount, 0);
    });

    test('respects dynamic settings changes', () {
      final settings = GameSettings(soundEnabled: true);
      final audio = AudioManager(settingsProvider: () => settings);

      audio.playMatch();
      expect(audio.playCount, 1);

      settings.soundEnabled = false;
      audio.playSwap();
      expect(audio.playCount, 1); // Should not increment

      settings.soundEnabled = true;
      audio.playCombo();
      expect(audio.playCount, 2);
    });

    test('lastPlayedSound is null initially', () {
      final audio = AudioManager.alwaysEnabled();
      expect(audio.lastPlayedSound, isNull);
    });

    test('dispose does not throw', () {
      final audio = AudioManager.alwaysEnabled();
      expect(() => audio.dispose(), returnsNormally);
    });

    test('alwaysEnabled factory creates enabled audio manager', () {
      final audio = AudioManager.alwaysEnabled();
      expect(audio.isSoundEnabled, true);
    });

    test('disabled factory creates disabled audio manager', () {
      final audio = AudioManager.disabled();
      expect(audio.isSoundEnabled, false);
    });
  });
}

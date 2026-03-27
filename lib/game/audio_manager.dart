import 'package:flutter/foundation.dart';

import 'game_state_manager.dart';

/// Manages sound effects for the game.
///
/// Currently implemented as a stub that logs sound events but does not
/// actually play audio. When real audio is needed, integrate the
/// `audioplayers` package and replace the stub implementations.
///
/// Usage:
/// ```dart
/// final audio = AudioManager(settingsProvider: () => gameStateManager.settings);
/// audio.playMatch();
/// ```
class AudioManager {
  /// Provider function that returns the current [GameSettings].
  /// Used to check whether sound is enabled before playing.
  final GameSettings Function() settingsProvider;

  /// If true, logs sound events to debugPrint (useful for testing/debugging).
  final bool debugLog;

  /// Tracks the last played sound (useful for testing).
  String? _lastPlayedSound;

  /// How many sounds have been played in total.
  int _playCount = 0;

  AudioManager({
    required this.settingsProvider,
    this.debugLog = false,
  });

  /// Creates an AudioManager that always has sound enabled (for testing).
  factory AudioManager.alwaysEnabled({bool debugLog = false}) {
    return AudioManager(
      settingsProvider: () => GameSettings(soundEnabled: true),
      debugLog: debugLog,
    );
  }

  /// Creates an AudioManager that always has sound disabled.
  factory AudioManager.disabled() {
    return AudioManager(
      settingsProvider: () => GameSettings(soundEnabled: false),
    );
  }

  /// Whether sound is currently enabled in settings.
  bool get isSoundEnabled => settingsProvider().soundEnabled;

  /// The last sound effect that was played (or null if none).
  String? get lastPlayedSound => _lastPlayedSound;

  /// Total number of sounds played.
  int get playCount => _playCount;

  /// Play the match/pling sound (when gems are matched).
  void playMatch() => _play('match');

  /// Play the swap/whoosh sound (when gems are swapped).
  void playSwap() => _play('swap');

  /// Play the combo/fanfare sound (when a cascade combo occurs).
  void playCombo() => _play('combo');

  /// Play the win/celebration sound (when a level is completed).
  void playWin() => _play('win');

  /// Play the lose/sad sound (when a level is failed).
  void playLose() => _play('lose');

  /// Play the tap/click sound (when a button is tapped).
  void playTap() => _play('tap');

  /// Internal method to play a sound by name.
  /// Checks if sound is enabled before playing.
  void _play(String soundName) {
    if (!isSoundEnabled) return;

    _lastPlayedSound = soundName;
    _playCount++;

    if (debugLog) {
      debugPrint('AudioManager: playing "$soundName"');
    }

    // TODO: Integrate audioplayers package for real sound playback.
    // Example implementation with audioplayers:
    //
    // final player = AudioPlayer();
    // await player.play(AssetSource('sounds/$soundName.mp3'));
    //
    // Or generate tones programmatically:
    // - match: 880Hz sine wave, 100ms
    // - swap: 440Hz -> 660Hz sweep, 150ms
    // - combo: 440Hz, 660Hz, 880Hz sequence, 300ms
    // - win: C major arpeggio, 500ms
    // - lose: descending minor scale, 500ms
    // - tap: 1000Hz click, 50ms
  }

  /// Dispose of any audio resources.
  void dispose() {
    // TODO: Dispose audioplayer instances when real audio is implemented.
  }
}

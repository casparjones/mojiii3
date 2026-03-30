import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_state_manager.dart';

/// Manages sound effects for the game.
///
/// Uses the audioplayers package to play WAV sound effects.
/// A pool of AudioPlayer instances enables overlapping sounds.
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

  /// If true, actually play audio via audioplayers. False for test instances.
  final bool _useAudio;

  /// Tracks the last played sound (useful for testing).
  String? _lastPlayedSound;

  /// How many sounds have been played in total.
  int _playCount = 0;

  /// Pool of AudioPlayer instances for overlapping sounds.
  List<AudioPlayer>? _players;

  /// Round-robin index into the player pool.
  int _currentPlayerIndex = 0;

  /// Whether this manager has been disposed.
  bool _disposed = false;

  AudioManager({
    required this.settingsProvider,
    this.debugLog = false,
    bool useAudio = false,
  }) : _useAudio = useAudio {
    if (_useAudio) {
      _players = List.generate(4, (_) {
        final player = AudioPlayer();
        player.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ));
        return player;
      });
    }
  }

  /// Creates an AudioManager that always has sound enabled (for testing).
  /// Does NOT initialize real audio players.
  factory AudioManager.alwaysEnabled({bool debugLog = false}) {
    return AudioManager(
      settingsProvider: () => GameSettings(soundEnabled: true),
      debugLog: debugLog,
      useAudio: false,
    );
  }

  /// Creates an AudioManager that always has sound disabled.
  /// Does NOT initialize real audio players.
  factory AudioManager.disabled() {
    return AudioManager(
      settingsProvider: () => GameSettings(soundEnabled: false),
      useAudio: false,
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

    if (_useAudio && _players != null && !_disposed) {
      final player = _players![_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players!.length;
      player.play(AssetSource('sounds/$soundName.wav'));
    }
  }

  /// Dispose of any audio resources.
  void dispose() {
    if (_useAudio && _players != null && !_disposed) {
      for (final player in _players!) {
        player.dispose();
      }
      _disposed = true;
    }
  }
}

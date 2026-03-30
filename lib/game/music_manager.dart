import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_state_manager.dart';

/// Manages background music playback for the game.
///
/// Separate from [AudioManager] which handles sound effects.
/// Uses [audioplayers] in loop mode with a low default volume
/// so the music stays pleasant and unobtrusive.
class MusicManager {
  /// Provider function that returns the current [GameSettings].
  final GameSettings Function() settingsProvider;

  AudioPlayer? _player;
  bool _isPlaying = false;
  double _volume = 0.15;

  MusicManager({required this.settingsProvider});

  /// Whether music is currently playing.
  bool get isPlaying => _isPlaying;

  /// Current volume (0.0 to 1.0).
  double get volume => _volume;

  /// Start playing the background music in a loop.
  ///
  /// If music is disabled in settings, this is a no-op.
  /// If already playing, this is also a no-op.
  Future<void> play() async {
    if (!settingsProvider().musicEnabled) return;
    if (_isPlaying) return;

    try {
      if (_player == null) {
        _player = AudioPlayer();
        await _player!.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ));
        // Fallback: restart on completion in case loop mode doesn't work on some platforms
        _player!.onPlayerComplete.listen((_) {
          if (_isPlaying) {
            _player?.play(AssetSource('sounds/background_music.mp3'));
          }
        });
      }
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(_volume);
      await _player!.play(AssetSource('sounds/background_music.mp3'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('MusicManager: Failed to play music: $e');
    }
  }

  /// Pause the music (e.g. when showing a dialog or leaving the screen).
  Future<void> pause() async {
    if (!_isPlaying) return;
    try {
      await _player?.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('MusicManager: Failed to pause music: $e');
    }
  }

  /// Resume previously paused music.
  ///
  /// Checks settings before resuming.
  Future<void> resume() async {
    if (!settingsProvider().musicEnabled) return;
    if (_isPlaying) return;

    try {
      await _player?.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('MusicManager: Failed to resume music: $e');
    }
  }

  /// Stop the music completely and release resources.
  Future<void> stop() async {
    try {
      await _player?.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('MusicManager: Failed to stop music: $e');
    }
  }

  /// Set the playback volume (0.0 to 1.0).
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_volume);
    } catch (e) {
      debugPrint('MusicManager: Failed to set volume: $e');
    }
  }

  /// Called when the music setting is toggled.
  ///
  /// Starts music if enabled, stops if disabled.
  Future<void> onMusicSettingChanged() async {
    if (settingsProvider().musicEnabled) {
      await play();
    } else {
      await stop();
    }
  }

  /// Dispose of audio resources.
  void dispose() {
    _player?.dispose();
    _player = null;
    _isPlaying = false;
  }
}

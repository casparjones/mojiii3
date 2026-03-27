import 'package:flutter/material.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/music_manager.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/main.dart';

/// Wraps a widget with [MaterialApp], [GameStateManagerProvider], and
/// [MusicManagerProvider].
///
/// The providers are placed above MaterialApp via its builder so that
/// all routes (including pushed routes) can access them.
Widget createTestApp({
  required Widget home,
  GameStateManager? gameStateManager,
  SaveState? saveState,
  GameSettings? settings,
}) {
  final gsm = gameStateManager ??
      GameStateManager(
        saveState: saveState,
        settings: settings,
      );
  final musicManager = MusicManager(
    settingsProvider: () => gsm.settings,
  );
  return GameStateManagerProvider(
    gameStateManager: gsm,
    child: MusicManagerProvider(
      musicManager: musicManager,
      child: MaterialApp(
        home: home,
      ),
    ),
  );
}

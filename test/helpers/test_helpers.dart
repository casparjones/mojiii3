import 'package:flutter/material.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';
import 'package:match3/main.dart';

/// Wraps a widget with [MaterialApp] and [GameStateManagerProvider].
///
/// The provider is placed above MaterialApp via its builder so that
/// all routes (including pushed routes) can access it.
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
  return GameStateManagerProvider(
    gameStateManager: gsm,
    child: MaterialApp(
      home: home,
    ),
  );
}

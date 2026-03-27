import 'package:flutter/material.dart';

import 'game/game_state_manager.dart';
import 'game/music_manager.dart';
import 'screens/main_menu_screen.dart';

void main() {
  runApp(const Match3App());
}

/// InheritedWidget that provides [GameStateManager] to the widget tree.
class GameStateManagerProvider extends InheritedWidget {
  final GameStateManager gameStateManager;

  const GameStateManagerProvider({
    super.key,
    required this.gameStateManager,
    required super.child,
  });

  /// Retrieve the [GameStateManager] from the nearest ancestor.
  static GameStateManager of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<GameStateManagerProvider>();
    assert(provider != null,
        'No GameStateManagerProvider found in context');
    return provider!.gameStateManager;
  }

  /// Retrieve the [GameStateManager] without registering for rebuild.
  static GameStateManager read(BuildContext context) {
    final provider = context
        .getInheritedWidgetOfExactType<GameStateManagerProvider>();
    assert(provider != null,
        'No GameStateManagerProvider found in context');
    return provider!.gameStateManager;
  }

  @override
  bool updateShouldNotify(GameStateManagerProvider oldWidget) {
    return gameStateManager != oldWidget.gameStateManager;
  }
}

/// InheritedWidget that provides [MusicManager] to the widget tree.
class MusicManagerProvider extends InheritedWidget {
  final MusicManager musicManager;

  const MusicManagerProvider({
    super.key,
    required this.musicManager,
    required super.child,
  });

  /// Retrieve the [MusicManager] from the nearest ancestor.
  /// Returns null if no provider is found (e.g. in tests).
  static MusicManager? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MusicManagerProvider>();
    return provider?.musicManager;
  }

  /// Retrieve the [MusicManager] without registering for rebuild.
  /// Returns null if no provider is found (e.g. in tests).
  static MusicManager? read(BuildContext context) {
    final provider =
        context.getInheritedWidgetOfExactType<MusicManagerProvider>();
    return provider?.musicManager;
  }

  @override
  bool updateShouldNotify(MusicManagerProvider oldWidget) {
    return musicManager != oldWidget.musicManager;
  }
}

class Match3App extends StatefulWidget {
  /// Optional [GameStateManager] for testing.
  final GameStateManager? gameStateManager;

  const Match3App({super.key, this.gameStateManager});

  @override
  State<Match3App> createState() => _Match3AppState();
}

class _Match3AppState extends State<Match3App> {
  late final GameStateManager _gameStateManager;
  late final MusicManager _musicManager;
  bool? _previousMusicEnabled;

  @override
  void initState() {
    super.initState();
    _gameStateManager = widget.gameStateManager ?? GameStateManager();
    _musicManager = MusicManager(
      settingsProvider: () => _gameStateManager.settings,
    );
    _gameStateManager.addListener(_onGameStateChanged);
    _gameStateManager.load();
  }

  void _onGameStateChanged() {
    final musicEnabled = _gameStateManager.settings.musicEnabled;
    if (_previousMusicEnabled != musicEnabled) {
      _previousMusicEnabled = musicEnabled;
      _musicManager.onMusicSettingChanged();
    }
  }

  @override
  void dispose() {
    _gameStateManager.removeListener(_onGameStateChanged);
    _musicManager.dispose();
    // Only dispose if we created it ourselves.
    if (widget.gameStateManager == null) {
      _gameStateManager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameStateManagerProvider(
      gameStateManager: _gameStateManager,
      child: MusicManagerProvider(
        musicManager: _musicManager,
        child: MaterialApp(
          title: 'Match3',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          home: const MainMenuScreen(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'game/game_state_manager.dart';
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

class Match3App extends StatefulWidget {
  /// Optional [GameStateManager] for testing.
  final GameStateManager? gameStateManager;

  const Match3App({super.key, this.gameStateManager});

  @override
  State<Match3App> createState() => _Match3AppState();
}

class _Match3AppState extends State<Match3App> {
  late final GameStateManager _gameStateManager;

  @override
  void initState() {
    super.initState();
    _gameStateManager = widget.gameStateManager ?? GameStateManager();
    _gameStateManager.load();
  }

  @override
  void dispose() {
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
    );
  }
}

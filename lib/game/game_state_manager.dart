import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/emoji_theme.dart';
import 'level_generator.dart';
import 'save_system.dart';

/// Settings the player can configure.
class GameSettings {
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  bool debugMode;

  GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.debugMode = false,
  });

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'vibrationEnabled': vibrationEnabled,
        'debugMode': debugMode,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? true,
        vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
        debugMode: json['debugMode'] as bool? ?? false,
      );
}

/// Provides the directory path for saving game data.
/// Extracted as an abstraction so tests can inject a temp directory.
abstract class DirectoryProvider {
  Future<Directory> getApplicationDocumentsDirectory();
}

/// Default implementation that uses path_provider.
class DefaultDirectoryProvider implements DirectoryProvider {
  const DefaultDirectoryProvider();

  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    return getApplicationDocumentsDirectory_();
  }
}

/// Wrapper around path_provider so we can call it without clashing names.
Future<Directory> getApplicationDocumentsDirectory_() {
  return getApplicationDocumentsDirectory();
}

/// Central game state manager that persists to a local JSON file.
///
/// Manages [SaveState], coins, current level, and [GameSettings].
/// Uses [ChangeNotifier] so widgets can listen for updates.
class GameStateManager extends ChangeNotifier {
  SaveState _saveState;
  GameSettings _settings;
  final LevelGenerator _levelGenerator;

  /// Optional custom directory provider (for testing).
  final DirectoryProvider? _directoryProvider;

  /// File name for save data.
  static const String saveFileName = 'match3_save.json';

  /// Whether data has been loaded from disk.
  bool _isLoaded = false;

  GameStateManager({
    SaveState? saveState,
    GameSettings? settings,
    LevelGenerator levelGenerator = const LevelGenerator(),
    DirectoryProvider? directoryProvider,
  })  : _saveState = saveState ?? SaveState(),
        _settings = settings ?? GameSettings(),
        _levelGenerator = levelGenerator,
        _directoryProvider = directoryProvider;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// The underlying save state.
  SaveState get saveState => _saveState;

  /// Current coins balance.
  int get coins => _saveState.coins;

  /// Current highest unlocked level.
  int get currentLevel => _saveState.currentLevel;

  /// Player statistics.
  PlayerStats get stats => _saveState.stats;

  /// Per-level records.
  Map<int, LevelRecord> get levelRecords => _saveState.levelRecords;

  /// Game settings.
  GameSettings get settings => _settings;

  /// Whether data has been loaded from disk.
  bool get isLoaded => _isLoaded;

  /// The level generator.
  LevelGenerator get levelGenerator => _levelGenerator;

  // ---------------------------------------------------------------------------
  // Level management
  // ---------------------------------------------------------------------------

  /// Generate a [LevelConfig] for a given level number.
  LevelConfig generateLevel(int levelNumber) {
    return _levelGenerator.generate(levelNumber);
  }

  /// Whether a given level is unlocked.
  bool isLevelUnlocked(int level) => _saveState.isLevelUnlocked(level);

  /// Total stars earned across all levels.
  int get totalStars => _saveState.totalStars;

  // ---------------------------------------------------------------------------
  // Coin management
  // ---------------------------------------------------------------------------

  /// Add coins to the balance.
  void addCoins(int amount) {
    if (amount <= 0) return;
    _saveState.coins += amount;
    notifyListeners();
    _scheduleSave();
  }

  /// Spend coins. Returns true if successful.
  bool spendCoins(int amount) {
    final success = _saveState.spendCoins(amount);
    if (success) {
      notifyListeners();
      _scheduleSave();
    }
    return success;
  }

  // ---------------------------------------------------------------------------
  // Level completion
  // ---------------------------------------------------------------------------

  /// Record a completed level and persist state.
  void recordLevelComplete({
    required int level,
    required int score,
    required int stars,
    required int gemsMatched,
    required int coinsEarned,
    required int maxCombo,
    required int playTimeSeconds,
  }) {
    _saveState.recordLevelComplete(
      level: level,
      score: score,
      stars: stars,
      gemsMatched: gemsMatched,
      coinsEarned: coinsEarned,
      maxCombo: maxCombo,
      playTimeSeconds: playTimeSeconds,
    );
    notifyListeners();
    _scheduleSave();
  }

  /// Record a failed level attempt and persist state.
  void recordLevelFailed({
    required int level,
    required int gemsMatched,
    required int playTimeSeconds,
  }) {
    _saveState.recordLevelFailed(
      level: level,
      gemsMatched: gemsMatched,
      playTimeSeconds: playTimeSeconds,
    );
    notifyListeners();
    _scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Toggle sound on/off.
  void toggleSound() {
    _settings.soundEnabled = !_settings.soundEnabled;
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle music on/off.
  void toggleMusic() {
    _settings.musicEnabled = !_settings.musicEnabled;
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle vibration on/off.
  void toggleVibration() {
    _settings.vibrationEnabled = !_settings.vibrationEnabled;
    notifyListeners();
    _scheduleSave();
  }

  /// Toggle debug mode on/off.
  void toggleDebugMode() {
    _settings.debugMode = !_settings.debugMode;
    notifyListeners();
    _scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Emoji theme
  // ---------------------------------------------------------------------------

  /// The currently selected emoji theme.
  EmojiTheme get activeTheme => EmojiTheme.byId(_saveState.selectedThemeId);

  /// The ID of the active theme.
  String get selectedThemeId => _saveState.selectedThemeId;

  /// Set the active emoji theme by ID and sync the global [EmojiTheme.active].
  void setTheme(String themeId) {
    _saveState.selectedThemeId = themeId;
    EmojiTheme.setActiveById(themeId);
    notifyListeners();
    _scheduleSave();
  }

  /// Sync the global [EmojiTheme.active] with the saved theme.
  /// Called after [load] to ensure the global state matches persistence.
  void _syncTheme() {
    EmojiTheme.setActiveById(_saveState.selectedThemeId);
  }

  /// Notify listeners and schedule a save.
  /// Useful when external code modifies the [saveState] directly.
  void persistState() {
    notifyListeners();
    _scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Bonus moves regeneration
  // ---------------------------------------------------------------------------

  /// Regenerate bonus moves based on elapsed time.
  /// Returns the number of new moves regenerated.
  int regenerateMoves() {
    final regen = _saveState.regenerateMoves();
    if (regen > 0) {
      notifyListeners();
      _scheduleSave();
    }
    return regen;
  }

  // ---------------------------------------------------------------------------
  // Login reward
  // ---------------------------------------------------------------------------

  /// Process daily login. Returns coins awarded (0 if already logged in today).
  int processLogin(String todayDate, {int dailyCoins = 100}) {
    final reward = _saveState.processLogin(todayDate, dailyCoins: dailyCoins);
    if (reward > 0) {
      notifyListeners();
      _scheduleSave();
    }
    return reward;
  }

  // ---------------------------------------------------------------------------
  // Daily Chest
  // ---------------------------------------------------------------------------

  /// Whether the daily chest can be claimed right now.
  bool get canClaimDailyChest {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _saveState.canClaimDailyChest(today);
  }

  /// Claim the daily chest. Returns the reward description map, or null if
  /// already claimed today.
  ///
  /// Possible rewards (weighted):
  /// - coins (50%) : 50-200 coins
  /// - powerup (25%) : 1x random powerup
  /// - theme (15%) : unlock a random locked theme
  /// - bonus_moves (10%) : 5-15 bonus moves
  Map<String, dynamic>? claimDailyChest() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!_saveState.canClaimDailyChest(today)) return null;

    _saveState.markDailyChestClaimed(today);

    final reward = _rollDailyChestReward();
    _applyReward(reward);

    notifyListeners();
    _scheduleSave();
    return reward;
  }

  Map<String, dynamic> _rollDailyChestReward() {
    final rng = DateTime.now().microsecondsSinceEpoch;
    final roll = (rng % 100);

    if (roll < 50) {
      // Coins: 50-200 in steps of 25
      final amounts = [50, 75, 100, 125, 150, 175, 200];
      final amount = amounts[(rng ~/ 100) % amounts.length];
      return {'type': 'coins', 'amount': amount};
    } else if (roll < 75) {
      // Powerup
      const powerups = [
        'powerup_extra_moves',
        'powerup_shuffle',
        'powerup_color_bomb',
      ];
      final id = powerups[(rng ~/ 100) % powerups.length];
      return {'type': 'powerup', 'id': id};
    } else if (roll < 90) {
      // Theme - pick a random theme that is not yet unlocked
      final locked = EmojiTheme.allThemes
          .where((t) =>
              t.id != 'theme_fruit' &&
              !_saveState.unlockedExtras.contains(t.id))
          .toList();
      if (locked.isNotEmpty) {
        final theme = locked[(rng ~/ 100) % locked.length];
        return {'type': 'theme', 'id': theme.id, 'name': theme.name};
      }
      // All themes unlocked -> fall back to coins
      return {'type': 'coins', 'amount': 200};
    } else {
      // Bonus moves: 5-15
      final amounts = [5, 8, 10, 12, 15];
      final amount = amounts[(rng ~/ 100) % amounts.length];
      return {'type': 'bonus_moves', 'amount': amount};
    }
  }

  void _applyReward(Map<String, dynamic> reward) {
    switch (reward['type'] as String) {
      case 'coins':
        _saveState.coins += reward['amount'] as int;
        break;
      case 'powerup':
        _saveState.addPowerUp(reward['id'] as String);
        break;
      case 'theme':
        _saveState.unlockExtra(reward['id'] as String);
        break;
      case 'bonus_moves':
        final amount = reward['amount'] as int;
        _saveState.bonusMoves =
            (_saveState.bonusMoves + amount).clamp(0, _saveState.maxBonusMoves);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Load state from the local JSON file.
  Future<void> load() async {
    try {
      final file = await _getSaveFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _saveState = SaveState.fromJson(json['saveState'] as Map<String, dynamic>? ?? {});
        _settings = GameSettings.fromJson(json['settings'] as Map<String, dynamic>? ?? {});
      }
    } catch (e) {
      // If loading fails, keep defaults.
      debugPrint('GameStateManager: Failed to load save: $e');
    }
    _isLoaded = true;
    _syncTheme();
    // Regenerate bonus moves based on offline time so the home screen shows
    // the correct value immediately.
    regenerateMoves();
    notifyListeners();
  }

  /// Save state to the local JSON file.
  Future<void> save() async {
    try {
      final file = await _getSaveFile();
      final json = {
        'saveState': _saveState.toJson(),
        'settings': _settings.toJson(),
      };
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('GameStateManager: Failed to save: $e');
    }
  }

  /// Reset all state (for testing or "new game").
  void reset() {
    _saveState = SaveState();
    _settings = GameSettings();
    _syncTheme();
    notifyListeners();
    _scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  bool _savePending = false;

  /// Debounces saves so rapid state changes don't cause excessive I/O.
  void _scheduleSave() {
    if (_savePending) return;
    _savePending = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      _savePending = false;
      save();
    });
  }

  Future<File> _getSaveFile() async {
    final Directory dir;
    if (_directoryProvider != null) {
      dir = await _directoryProvider!.getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    return File('${dir.path}/$saveFileName');
  }
}

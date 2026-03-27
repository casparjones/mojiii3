import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/game_state_manager.dart';
import 'package:match3/game/save_system.dart';

/// Test directory provider that uses a temp directory.
class TestDirectoryProvider implements DirectoryProvider {
  final Directory dir;
  const TestDirectoryProvider(this.dir);

  @override
  Future<Directory> getApplicationDocumentsDirectory() async => dir;
}

void main() {
  group('GameSettings', () {
    test('default values', () {
      final s = GameSettings();
      expect(s.soundEnabled, true);
      expect(s.musicEnabled, true);
      expect(s.vibrationEnabled, true);
    });

    test('toJson and fromJson round-trip', () {
      final s = GameSettings(
        soundEnabled: false,
        musicEnabled: true,
        vibrationEnabled: false,
      );
      final json = s.toJson();
      final restored = GameSettings.fromJson(json);
      expect(restored.soundEnabled, false);
      expect(restored.musicEnabled, true);
      expect(restored.vibrationEnabled, false);
    });

    test('fromJson with missing keys uses defaults', () {
      final restored = GameSettings.fromJson({});
      expect(restored.soundEnabled, true);
      expect(restored.musicEnabled, true);
      expect(restored.vibrationEnabled, true);
    });
  });

  group('GameStateManager', () {
    late Directory tempDir;
    late GameStateManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('match3_test_');
      manager = GameStateManager(
        directoryProvider: TestDirectoryProvider(tempDir),
      );
    });

    tearDown(() {
      manager.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initial state has default values', () {
      expect(manager.coins, 0);
      expect(manager.currentLevel, 1);
      expect(manager.isLoaded, false);
      expect(manager.settings.soundEnabled, true);
    });

    test('addCoins increases balance and notifies', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.addCoins(100);
      expect(manager.coins, 100);
      expect(notifications, 1);

      manager.addCoins(50);
      expect(manager.coins, 150);
      expect(notifications, 2);
    });

    test('addCoins with zero or negative does nothing', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.addCoins(0);
      expect(manager.coins, 0);
      expect(notifications, 0);

      manager.addCoins(-10);
      expect(manager.coins, 0);
      expect(notifications, 0);
    });

    test('spendCoins deducts and returns true', () {
      manager.addCoins(100);
      final result = manager.spendCoins(30);
      expect(result, true);
      expect(manager.coins, 70);
    });

    test('spendCoins with insufficient balance returns false', () {
      manager.addCoins(10);
      final result = manager.spendCoins(20);
      expect(result, false);
      expect(manager.coins, 10);
    });

    test('recordLevelComplete updates state', () {
      manager.recordLevelComplete(
        level: 1,
        score: 1000,
        stars: 3,
        gemsMatched: 50,
        coinsEarned: 10,
        maxCombo: 3,
        playTimeSeconds: 60,
      );

      expect(manager.currentLevel, 2);
      expect(manager.coins, 10);
      expect(manager.stats.levelsCompleted, 1);
      expect(manager.stats.threeStarCount, 1);
    });

    test('recordLevelFailed updates stats without advancing level', () {
      manager.recordLevelFailed(
        level: 1,
        gemsMatched: 20,
        playTimeSeconds: 30,
      );

      expect(manager.currentLevel, 1);
      expect(manager.stats.levelsPlayed, 1);
      expect(manager.stats.levelsCompleted, 0);
    });

    test('toggleSound flips setting and notifies', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      expect(manager.settings.soundEnabled, true);
      manager.toggleSound();
      expect(manager.settings.soundEnabled, false);
      expect(notifications, 1);
      manager.toggleSound();
      expect(manager.settings.soundEnabled, true);
      expect(notifications, 2);
    });

    test('toggleMusic flips setting', () {
      expect(manager.settings.musicEnabled, true);
      manager.toggleMusic();
      expect(manager.settings.musicEnabled, false);
    });

    test('toggleVibration flips setting', () {
      expect(manager.settings.vibrationEnabled, true);
      manager.toggleVibration();
      expect(manager.settings.vibrationEnabled, false);
    });

    test('processLogin awards coins first time', () {
      final reward = manager.processLogin('2026-03-27', dailyCoins: 100);
      expect(reward, 100);
      expect(manager.coins, 100);
    });

    test('processLogin awards 0 on same day', () {
      manager.processLogin('2026-03-27', dailyCoins: 100);
      final reward = manager.processLogin('2026-03-27', dailyCoins: 100);
      expect(reward, 0);
      expect(manager.coins, 100);
    });

    test('isLevelUnlocked', () {
      expect(manager.isLevelUnlocked(1), true);
      expect(manager.isLevelUnlocked(2), false);

      manager.recordLevelComplete(
        level: 1,
        score: 500,
        stars: 1,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );
      expect(manager.isLevelUnlocked(2), true);
    });

    test('generateLevel returns valid LevelConfig', () {
      final config = manager.generateLevel(1);
      expect(config.levelNumber, 1);
      expect(config.rows, greaterThan(0));
      expect(config.cols, greaterThan(0));
    });

    test('totalStars reflects level records', () {
      expect(manager.totalStars, 0);
      manager.recordLevelComplete(
        level: 1,
        score: 500,
        stars: 2,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );
      expect(manager.totalStars, 2);
    });

    test('reset clears all state', () {
      manager.addCoins(500);
      manager.recordLevelComplete(
        level: 1,
        score: 500,
        stars: 2,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );
      manager.toggleSound();

      manager.reset();

      expect(manager.coins, 0);
      expect(manager.currentLevel, 1);
      expect(manager.settings.soundEnabled, true);
      expect(manager.stats.levelsCompleted, 0);
    });

    test('save and load round-trip', () async {
      manager.addCoins(200);
      manager.toggleSound();
      manager.recordLevelComplete(
        level: 1,
        score: 1000,
        stars: 3,
        gemsMatched: 50,
        coinsEarned: 10,
        maxCombo: 3,
        playTimeSeconds: 60,
      );

      // Force save (bypass debounce).
      await manager.save();

      // Create a new manager and load.
      final manager2 = GameStateManager(
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      await manager2.load();

      expect(manager2.isLoaded, true);
      expect(manager2.coins, 210); // 200 + 10 from level completion
      expect(manager2.currentLevel, 2);
      expect(manager2.settings.soundEnabled, false);
      expect(manager2.stats.levelsCompleted, 1);

      manager2.dispose();
    });

    test('load with no save file uses defaults', () async {
      await manager.load();
      expect(manager.isLoaded, true);
      expect(manager.coins, 0);
      expect(manager.currentLevel, 1);
    });

    test('load with corrupted save file uses defaults', () async {
      final file = File('${tempDir.path}/${GameStateManager.saveFileName}');
      await file.writeAsString('not valid json {{{{');

      await manager.load();
      expect(manager.isLoaded, true);
      expect(manager.coins, 0);
    });

    test('constructor accepts pre-built SaveState', () {
      final customSave = SaveState(coins: 999, currentLevel: 5);
      final m = GameStateManager(
        saveState: customSave,
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      expect(m.coins, 999);
      expect(m.currentLevel, 5);
      m.dispose();
    });
  });
}

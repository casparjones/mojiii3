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
  group('GameStateManager edge cases', () {
    late Directory tempDir;
    late GameStateManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('match3_edge_test_');
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

    // -----------------------------------------------------------------------
    // Coin edge cases
    // -----------------------------------------------------------------------

    test('spendCoins with exact balance succeeds and leaves 0', () {
      manager.addCoins(50);
      final result = manager.spendCoins(50);
      expect(result, true);
      expect(manager.coins, 0);
    });

    test('spendCoins with zero amount succeeds without deducting', () {
      manager.addCoins(100);
      final result = manager.spendCoins(0);
      expect(result, true);
      expect(manager.coins, 100);
    });

    test('multiple spendCoins calls accumulate correctly', () {
      manager.addCoins(100);
      expect(manager.spendCoins(30), true);
      expect(manager.spendCoins(30), true);
      expect(manager.spendCoins(30), true);
      expect(manager.coins, 10);
      // Now insufficient
      expect(manager.spendCoins(20), false);
      expect(manager.coins, 10);
    });

    test('addCoins with very large amount works', () {
      manager.addCoins(999999999);
      expect(manager.coins, 999999999);
    });

    // -----------------------------------------------------------------------
    // Level completion edge cases
    // -----------------------------------------------------------------------

    test('replaying a lower level does not reduce currentLevel', () {
      // Complete levels 1, 2, 3
      for (int i = 1; i <= 3; i++) {
        manager.recordLevelComplete(
          level: i,
          score: 100,
          stars: 2,
          gemsMatched: 10,
          coinsEarned: 5,
          maxCombo: 1,
          playTimeSeconds: 30,
        );
      }
      expect(manager.currentLevel, 4);

      // Replay level 1
      manager.recordLevelComplete(
        level: 1,
        score: 500,
        stars: 3,
        gemsMatched: 20,
        coinsEarned: 10,
        maxCombo: 2,
        playTimeSeconds: 20,
      );
      // currentLevel should still be 4
      expect(manager.currentLevel, 4);
      // But stars for level 1 should be updated
      expect(manager.levelRecords[1]!.bestStars, 3);
      expect(manager.levelRecords[1]!.highScore, 500);
    });

    test('recordLevelComplete notifies listeners', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.recordLevelComplete(
        level: 1,
        score: 100,
        stars: 1,
        gemsMatched: 5,
        coinsEarned: 3,
        maxCombo: 1,
        playTimeSeconds: 20,
      );
      expect(notifications, 1);
    });

    test('recordLevelFailed notifies listeners', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.recordLevelFailed(
        level: 1,
        gemsMatched: 5,
        playTimeSeconds: 15,
      );
      expect(notifications, 1);
    });

    test('level records track times played and completed separately', () {
      // Fail twice
      manager.recordLevelFailed(level: 1, gemsMatched: 5, playTimeSeconds: 10);
      manager.recordLevelFailed(level: 1, gemsMatched: 3, playTimeSeconds: 8);

      // Complete once
      manager.recordLevelComplete(
        level: 1,
        score: 200,
        stars: 2,
        gemsMatched: 15,
        coinsEarned: 5,
        maxCombo: 2,
        playTimeSeconds: 30,
      );

      final record = manager.levelRecords[1]!;
      expect(record.timesPlayed, 3);
      expect(record.timesCompleted, 1);
    });

    test('totalStars accumulates across multiple levels', () {
      for (int i = 1; i <= 5; i++) {
        manager.recordLevelComplete(
          level: i,
          score: 100 * i,
          stars: (i % 3) + 1,
          gemsMatched: 10,
          coinsEarned: 5,
          maxCombo: 1,
          playTimeSeconds: 30,
        );
      }
      // Stars: 2, 3, 1, 2, 3 = 11
      expect(manager.totalStars, 11);
    });

    // -----------------------------------------------------------------------
    // Login streak edge cases
    // -----------------------------------------------------------------------

    test('processLogin builds streak on consecutive days', () {
      manager.processLogin('2026-03-25', dailyCoins: 100);
      manager.processLogin('2026-03-26', dailyCoins: 100);
      manager.processLogin('2026-03-27', dailyCoins: 100);
      expect(manager.saveState.loginStreak, 3);
      expect(manager.coins, 300);
    });

    test('processLogin resets streak on gap day', () {
      manager.processLogin('2026-03-25', dailyCoins: 100);
      manager.processLogin('2026-03-26', dailyCoins: 100);
      // Skip 27th
      manager.processLogin('2026-03-28', dailyCoins: 100);
      expect(manager.saveState.loginStreak, 1);
      expect(manager.coins, 300);
    });

    test('processLogin notifies only when reward is given', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.processLogin('2026-03-27', dailyCoins: 100);
      expect(notifications, 1);

      // Same day - no notification
      manager.processLogin('2026-03-27', dailyCoins: 100);
      expect(notifications, 1);
    });

    // -----------------------------------------------------------------------
    // Settings edge cases
    // -----------------------------------------------------------------------

    test('all settings can be toggled independently', () {
      manager.toggleSound();
      expect(manager.settings.soundEnabled, false);
      expect(manager.settings.musicEnabled, true);
      expect(manager.settings.vibrationEnabled, true);

      manager.toggleMusic();
      expect(manager.settings.soundEnabled, false);
      expect(manager.settings.musicEnabled, false);
      expect(manager.settings.vibrationEnabled, true);

      manager.toggleVibration();
      expect(manager.settings.soundEnabled, false);
      expect(manager.settings.musicEnabled, false);
      expect(manager.settings.vibrationEnabled, false);
    });

    // -----------------------------------------------------------------------
    // Persistence edge cases
    // -----------------------------------------------------------------------

    test('save and load preserves login streak', () async {
      manager.processLogin('2026-03-25', dailyCoins: 100);
      manager.processLogin('2026-03-26', dailyCoins: 100);
      manager.processLogin('2026-03-27', dailyCoins: 100);

      await manager.save();

      final manager2 = GameStateManager(
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      await manager2.load();

      expect(manager2.saveState.loginStreak, 3);
      expect(manager2.saveState.lastLoginDate, '2026-03-27');
      expect(manager2.coins, 300);

      manager2.dispose();
    });

    test('save and load preserves level records', () async {
      manager.recordLevelComplete(
        level: 1,
        score: 1000,
        stars: 3,
        gemsMatched: 50,
        coinsEarned: 10,
        maxCombo: 5,
        playTimeSeconds: 60,
      );
      manager.recordLevelFailed(level: 2, gemsMatched: 5, playTimeSeconds: 10);
      manager.recordLevelComplete(
        level: 2,
        score: 800,
        stars: 2,
        gemsMatched: 40,
        coinsEarned: 8,
        maxCombo: 3,
        playTimeSeconds: 45,
      );

      await manager.save();

      final manager2 = GameStateManager(
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      await manager2.load();

      expect(manager2.levelRecords[1]!.highScore, 1000);
      expect(manager2.levelRecords[1]!.bestStars, 3);
      expect(manager2.levelRecords[2]!.timesPlayed, 2);
      expect(manager2.levelRecords[2]!.timesCompleted, 1);

      manager2.dispose();
    });

    test('reset followed by save and load gives clean state', () async {
      manager.addCoins(500);
      manager.toggleSound();
      manager.recordLevelComplete(
        level: 1,
        score: 100,
        stars: 2,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );

      manager.reset();
      await manager.save();

      final manager2 = GameStateManager(
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      await manager2.load();

      expect(manager2.coins, 0);
      expect(manager2.currentLevel, 1);
      expect(manager2.settings.soundEnabled, true);
      expect(manager2.stats.levelsCompleted, 0);
      expect(manager2.totalStars, 0);

      manager2.dispose();
    });

    test('load with partial JSON recovers gracefully', () async {
      // Write JSON with only some fields
      final file = File('${tempDir.path}/${GameStateManager.saveFileName}');
      await file.writeAsString(jsonEncode({
        'saveState': {'coins': 42},
        // settings missing
      }));

      await manager.load();
      expect(manager.isLoaded, true);
      expect(manager.coins, 42);
      expect(manager.currentLevel, 1);
      expect(manager.settings.soundEnabled, true);
    });

    test('load with empty JSON object recovers gracefully', () async {
      final file = File('${tempDir.path}/${GameStateManager.saveFileName}');
      await file.writeAsString(jsonEncode({}));

      await manager.load();
      expect(manager.isLoaded, true);
      expect(manager.coins, 0);
      expect(manager.settings.soundEnabled, true);
    });

    test('load sets isLoaded even on failure', () async {
      final file = File('${tempDir.path}/${GameStateManager.saveFileName}');
      await file.writeAsString('{{invalid json!!');

      await manager.load();
      expect(manager.isLoaded, true);
    });

    // -----------------------------------------------------------------------
    // Stats aggregation
    // -----------------------------------------------------------------------

    test('stats accumulate across multiple completions and failures', () {
      manager.recordLevelComplete(
        level: 1,
        score: 100,
        stars: 1,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 2,
        playTimeSeconds: 30,
      );
      manager.recordLevelFailed(
        level: 2,
        gemsMatched: 5,
        playTimeSeconds: 15,
      );
      manager.recordLevelComplete(
        level: 2,
        score: 200,
        stars: 3,
        gemsMatched: 20,
        coinsEarned: 10,
        maxCombo: 4,
        playTimeSeconds: 45,
      );

      expect(manager.stats.levelsPlayed, 3);
      expect(manager.stats.levelsCompleted, 2);
      expect(manager.stats.totalGemsMatched, 35);
      expect(manager.stats.totalCoinsEarned, 15);
      expect(manager.stats.bestCombo, 4);
      expect(manager.stats.totalPlayTimeSeconds, 90);
      expect(manager.stats.threeStarCount, 1);
    });

    test('bestMoveScore tracks highest score ever', () {
      manager.recordLevelComplete(
        level: 1,
        score: 500,
        stars: 2,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );
      manager.recordLevelComplete(
        level: 2,
        score: 300,
        stars: 1,
        gemsMatched: 10,
        coinsEarned: 5,
        maxCombo: 1,
        playTimeSeconds: 30,
      );
      expect(manager.stats.bestMoveScore, 500);
    });

    // -----------------------------------------------------------------------
    // Constructor edge cases
    // -----------------------------------------------------------------------

    test('constructor with custom settings preserves them', () {
      final customSettings = GameSettings(
        soundEnabled: false,
        musicEnabled: false,
        vibrationEnabled: false,
      );
      final m = GameStateManager(
        settings: customSettings,
        directoryProvider: TestDirectoryProvider(tempDir),
      );
      expect(m.settings.soundEnabled, false);
      expect(m.settings.musicEnabled, false);
      expect(m.settings.vibrationEnabled, false);
      m.dispose();
    });

    test('reset notifies listeners', () {
      int notifications = 0;
      manager.addListener(() => notifications++);

      manager.addCoins(100);
      expect(notifications, 1);

      manager.reset();
      expect(notifications, 2);
    });
  });
}

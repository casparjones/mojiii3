import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/save_system.dart';

void main() {
  group('PlayerStats', () {
    test('starts with zero values', () {
      final stats = PlayerStats();
      expect(stats.levelsPlayed, 0);
      expect(stats.levelsCompleted, 0);
      expect(stats.bestCombo, 0);
      expect(stats.totalGemsMatched, 0);
      expect(stats.totalCoinsEarned, 0);
      expect(stats.bestMoveScore, 0);
      expect(stats.totalPlayTimeSeconds, 0);
      expect(stats.threeStarCount, 0);
    });

    test('recordLevelComplete updates all fields', () {
      final stats = PlayerStats();
      stats.recordLevelComplete(
        score: 1000,
        stars: 3,
        gemsMatched: 50,
        coinsEarned: 10,
        maxCombo: 5,
        playTimeSeconds: 120,
      );

      expect(stats.levelsPlayed, 1);
      expect(stats.levelsCompleted, 1);
      expect(stats.totalGemsMatched, 50);
      expect(stats.totalCoinsEarned, 10);
      expect(stats.bestCombo, 5);
      expect(stats.bestMoveScore, 1000);
      expect(stats.totalPlayTimeSeconds, 120);
      expect(stats.threeStarCount, 1);
    });

    test('bestCombo only updates when higher', () {
      final stats = PlayerStats();
      stats.recordLevelComplete(
        score: 500, stars: 1, gemsMatched: 20,
        coinsEarned: 5, maxCombo: 3, playTimeSeconds: 60,
      );
      stats.recordLevelComplete(
        score: 800, stars: 2, gemsMatched: 30,
        coinsEarned: 8, maxCombo: 2, playTimeSeconds: 90,
      );
      expect(stats.bestCombo, 3); // Should not decrease.
    });

    test('recordLevelFailed increments played but not completed', () {
      final stats = PlayerStats();
      stats.recordLevelFailed(gemsMatched: 10, playTimeSeconds: 45);
      expect(stats.levelsPlayed, 1);
      expect(stats.levelsCompleted, 0);
      expect(stats.totalGemsMatched, 10);
    });

    test('threeStarCount only increments for 3+ stars', () {
      final stats = PlayerStats();
      stats.recordLevelComplete(
        score: 500, stars: 2, gemsMatched: 20,
        coinsEarned: 5, maxCombo: 2, playTimeSeconds: 60,
      );
      expect(stats.threeStarCount, 0);

      stats.recordLevelComplete(
        score: 1000, stars: 3, gemsMatched: 30,
        coinsEarned: 10, maxCombo: 4, playTimeSeconds: 90,
      );
      expect(stats.threeStarCount, 1);
    });

    test('serialization roundtrip', () {
      final stats = PlayerStats(
        levelsPlayed: 10,
        levelsCompleted: 8,
        bestCombo: 7,
        totalGemsMatched: 500,
        totalCoinsEarned: 200,
        bestMoveScore: 3000,
        totalPlayTimeSeconds: 3600,
        threeStarCount: 3,
      );

      final json = stats.toJson();
      final restored = PlayerStats.fromJson(json);

      expect(restored.levelsPlayed, 10);
      expect(restored.levelsCompleted, 8);
      expect(restored.bestCombo, 7);
      expect(restored.totalGemsMatched, 500);
      expect(restored.totalCoinsEarned, 200);
      expect(restored.bestMoveScore, 3000);
      expect(restored.totalPlayTimeSeconds, 3600);
      expect(restored.threeStarCount, 3);
    });

    test('fromJson handles missing fields', () {
      final stats = PlayerStats.fromJson({});
      expect(stats.levelsPlayed, 0);
      expect(stats.bestCombo, 0);
    });
  });

  group('LevelRecord', () {
    test('starts with zero values', () {
      final record = LevelRecord(levelNumber: 1);
      expect(record.levelNumber, 1);
      expect(record.highScore, 0);
      expect(record.bestStars, 0);
      expect(record.timesPlayed, 0);
      expect(record.timesCompleted, 0);
    });

    test('recordCompletion updates fields', () {
      final record = LevelRecord(levelNumber: 1);
      record.recordCompletion(score: 1000, stars: 2);

      expect(record.highScore, 1000);
      expect(record.bestStars, 2);
      expect(record.timesPlayed, 1);
      expect(record.timesCompleted, 1);
    });

    test('highScore only updates when higher', () {
      final record = LevelRecord(levelNumber: 1);
      record.recordCompletion(score: 1000, stars: 2);
      record.recordCompletion(score: 500, stars: 1);

      expect(record.highScore, 1000);
    });

    test('bestStars only updates when higher', () {
      final record = LevelRecord(levelNumber: 1);
      record.recordCompletion(score: 1000, stars: 3);
      record.recordCompletion(score: 500, stars: 1);

      expect(record.bestStars, 3);
    });

    test('recordAttempt increments timesPlayed only', () {
      final record = LevelRecord(levelNumber: 1);
      record.recordAttempt();
      expect(record.timesPlayed, 1);
      expect(record.timesCompleted, 0);
    });

    test('serialization roundtrip', () {
      final record = LevelRecord(
        levelNumber: 5,
        highScore: 2000,
        bestStars: 3,
        timesPlayed: 10,
        timesCompleted: 7,
      );

      final json = record.toJson();
      final restored = LevelRecord.fromJson(json);

      expect(restored.levelNumber, 5);
      expect(restored.highScore, 2000);
      expect(restored.bestStars, 3);
      expect(restored.timesPlayed, 10);
      expect(restored.timesCompleted, 7);
    });
  });

  group('SaveState', () {
    test('starts with default values', () {
      final save = SaveState();
      expect(save.currentLevel, 1);
      expect(save.coins, 0);
      expect(save.loginStreak, 0);
      expect(save.lastLoginDate, '');
      expect(save.levelRecords, isEmpty);
      expect(save.unlockedExtras, isEmpty);
      expect(save.totalStars, 0);
    });

    test('isLevelUnlocked works', () {
      final save = SaveState(currentLevel: 5);
      expect(save.isLevelUnlocked(1), true);
      expect(save.isLevelUnlocked(5), true);
      expect(save.isLevelUnlocked(6), false);
    });

    test('recordLevelComplete updates all state', () {
      final save = SaveState();
      save.recordLevelComplete(
        level: 1,
        score: 1000,
        stars: 3,
        gemsMatched: 50,
        coinsEarned: 10,
        maxCombo: 4,
        playTimeSeconds: 120,
      );

      expect(save.currentLevel, 2);
      expect(save.coins, 10);
      expect(save.stats.levelsCompleted, 1);
      expect(save.levelRecords[1]!.highScore, 1000);
      expect(save.levelRecords[1]!.bestStars, 3);
      expect(save.totalStars, 3);
    });

    test('recordLevelComplete advances to next level', () {
      final save = SaveState(currentLevel: 3);
      save.recordLevelComplete(
        level: 3,
        score: 500,
        stars: 1,
        gemsMatched: 20,
        coinsEarned: 5,
        maxCombo: 2,
        playTimeSeconds: 60,
      );
      expect(save.currentLevel, 4);
    });

    test('replaying old level does not regress currentLevel', () {
      final save = SaveState(currentLevel: 10);
      save.recordLevelComplete(
        level: 3,
        score: 500,
        stars: 1,
        gemsMatched: 20,
        coinsEarned: 5,
        maxCombo: 2,
        playTimeSeconds: 60,
      );
      expect(save.currentLevel, 10); // Should not change.
    });

    test('recordLevelFailed does not advance level', () {
      final save = SaveState(currentLevel: 5);
      save.recordLevelFailed(
        level: 5,
        gemsMatched: 10,
        playTimeSeconds: 45,
      );
      expect(save.currentLevel, 5);
      expect(save.stats.levelsPlayed, 1);
      expect(save.stats.levelsCompleted, 0);
    });

    test('spendCoins works when sufficient', () {
      final save = SaveState(coins: 100);
      expect(save.spendCoins(50), true);
      expect(save.coins, 50);
    });

    test('spendCoins fails when insufficient', () {
      final save = SaveState(coins: 30);
      expect(save.spendCoins(50), false);
      expect(save.coins, 30); // Unchanged.
    });

    test('spendCoins rejects negative amount', () {
      final save = SaveState(coins: 100);
      expect(save.spendCoins(-10), false);
    });

    test('unlockExtra and isExtraUnlocked', () {
      final save = SaveState();
      expect(save.isExtraUnlocked('extraLife'), false);

      save.unlockExtra('extraLife');
      expect(save.isExtraUnlocked('extraLife'), true);
    });

    test('processLogin awards coins on first login', () {
      final save = SaveState();
      final reward = save.processLogin('2026-03-27', dailyCoins: 100);

      expect(reward, 100);
      expect(save.coins, 100);
      expect(save.loginStreak, 1);
      expect(save.lastLoginDate, '2026-03-27');
    });

    test('processLogin returns 0 for same-day login', () {
      final save = SaveState(lastLoginDate: '2026-03-27');
      final reward = save.processLogin('2026-03-27', dailyCoins: 100);

      expect(reward, 0);
    });

    test('processLogin increments streak for consecutive days', () {
      final save = SaveState(
        lastLoginDate: '2026-03-26',
        loginStreak: 3,
      );
      save.processLogin('2026-03-27', dailyCoins: 100);

      expect(save.loginStreak, 4);
    });

    test('processLogin resets streak for non-consecutive days', () {
      final save = SaveState(
        lastLoginDate: '2026-03-20',
        loginStreak: 5,
      );
      save.processLogin('2026-03-27', dailyCoins: 100);

      expect(save.loginStreak, 1);
    });

    test('totalStars sums all level records', () {
      final save = SaveState();
      save.recordLevelComplete(
        level: 1, score: 500, stars: 2, gemsMatched: 20,
        coinsEarned: 5, maxCombo: 2, playTimeSeconds: 60,
      );
      save.recordLevelComplete(
        level: 2, score: 800, stars: 3, gemsMatched: 30,
        coinsEarned: 8, maxCombo: 3, playTimeSeconds: 90,
      );

      expect(save.totalStars, 5);
    });
  });

  group('SaveState serialization', () {
    test('toJson and fromJson roundtrip', () {
      final save = SaveState(
        currentLevel: 15,
        coins: 500,
        loginStreak: 7,
        lastLoginDate: '2026-03-27',
        unlockedExtras: {'extraLife', 'doubleCoins'},
      );
      save.recordLevelComplete(
        level: 1, score: 1000, stars: 3, gemsMatched: 50,
        coinsEarned: 10, maxCombo: 5, playTimeSeconds: 120,
      );

      final json = save.toJson();
      final restored = SaveState.fromJson(json);

      expect(restored.currentLevel, save.currentLevel);
      expect(restored.coins, save.coins);
      expect(restored.loginStreak, 7);
      expect(restored.lastLoginDate, '2026-03-27');
      expect(restored.stats.levelsCompleted, 1);
      expect(restored.levelRecords[1]!.highScore, 1000);
      expect(restored.unlockedExtras, contains('extraLife'));
      expect(restored.unlockedExtras, contains('doubleCoins'));
    });

    test('toJsonString and fromJsonString roundtrip', () {
      final save = SaveState(currentLevel: 5, coins: 200);
      save.recordLevelComplete(
        level: 3, score: 800, stars: 2, gemsMatched: 30,
        coinsEarned: 8, maxCombo: 3, playTimeSeconds: 90,
      );

      final jsonStr = save.toJsonString();
      expect(jsonStr, isA<String>());

      final restored = SaveState.fromJsonString(jsonStr);
      expect(restored.currentLevel, save.currentLevel);
      expect(restored.coins, save.coins);
    });

    test('fromJson handles empty/missing data', () {
      final save = SaveState.fromJson({});
      expect(save.currentLevel, 1);
      expect(save.coins, 0);
      expect(save.loginStreak, 0);
      expect(save.stats.levelsPlayed, 0);
    });

    test('JSON is valid JSON', () {
      final save = SaveState(currentLevel: 3, coins: 100);
      final jsonStr = save.toJsonString();

      // Should parse without error.
      final parsed = jsonDecode(jsonStr);
      expect(parsed, isA<Map<String, dynamic>>());
    });

    test('level records survive serialization', () {
      final save = SaveState();
      for (int i = 1; i <= 5; i++) {
        save.recordLevelComplete(
          level: i, score: i * 100, stars: (i % 3) + 1,
          gemsMatched: i * 10, coinsEarned: i * 2,
          maxCombo: i, playTimeSeconds: i * 30,
        );
      }

      final restored = SaveState.fromJsonString(save.toJsonString());
      expect(restored.levelRecords.length, 5);
      for (int i = 1; i <= 5; i++) {
        expect(restored.levelRecords[i]!.highScore, i * 100);
      }
    });
  });

  group('SaveState edge cases', () {
    test('levelRecord creates new record if missing', () {
      final save = SaveState();
      final record = save.levelRecord(42);
      expect(record.levelNumber, 42);
      expect(record.highScore, 0);
    });

    test('multiple completions of same level', () {
      final save = SaveState();
      save.recordLevelComplete(
        level: 1, score: 500, stars: 1, gemsMatched: 20,
        coinsEarned: 5, maxCombo: 2, playTimeSeconds: 60,
      );
      save.recordLevelComplete(
        level: 1, score: 1000, stars: 3, gemsMatched: 40,
        coinsEarned: 10, maxCombo: 4, playTimeSeconds: 90,
      );

      final record = save.levelRecord(1);
      expect(record.highScore, 1000);
      expect(record.bestStars, 3);
      expect(record.timesPlayed, 2);
      expect(record.timesCompleted, 2);
    });

    test('coins accumulate correctly', () {
      final save = SaveState();
      save.recordLevelComplete(
        level: 1, score: 500, stars: 1, gemsMatched: 20,
        coinsEarned: 10, maxCombo: 2, playTimeSeconds: 60,
      );
      save.recordLevelComplete(
        level: 2, score: 800, stars: 2, gemsMatched: 30,
        coinsEarned: 20, maxCombo: 3, playTimeSeconds: 90,
      );
      save.processLogin('2026-03-27', dailyCoins: 100);

      expect(save.coins, 130); // 10 + 20 + 100
    });
  });
}

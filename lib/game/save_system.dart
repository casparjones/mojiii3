import 'dart:convert';

/// Statistics tracked for the player.
class PlayerStats {
  /// Total levels played.
  int levelsPlayed;

  /// Total levels completed (won).
  int levelsCompleted;

  /// Highest cascade combo ever achieved.
  int bestCombo;

  /// Total gems matched across all games.
  int totalGemsMatched;

  /// Total coins earned across all games.
  int totalCoinsEarned;

  /// Highest single-move score.
  int bestMoveScore;

  /// Total play time in seconds.
  int totalPlayTimeSeconds;

  /// Number of 3-star completions.
  int threeStarCount;

  PlayerStats({
    this.levelsPlayed = 0,
    this.levelsCompleted = 0,
    this.bestCombo = 0,
    this.totalGemsMatched = 0,
    this.totalCoinsEarned = 0,
    this.bestMoveScore = 0,
    this.totalPlayTimeSeconds = 0,
    this.threeStarCount = 0,
  });

  /// Update stats after a level completion.
  void recordLevelComplete({
    required int score,
    required int stars,
    required int gemsMatched,
    required int coinsEarned,
    required int maxCombo,
    required int playTimeSeconds,
  }) {
    levelsPlayed++;
    levelsCompleted++;
    totalGemsMatched += gemsMatched;
    totalCoinsEarned += coinsEarned;
    totalPlayTimeSeconds += playTimeSeconds;
    if (maxCombo > bestCombo) bestCombo = maxCombo;
    if (score > bestMoveScore) bestMoveScore = score;
    if (stars >= 3) threeStarCount++;
  }

  /// Update stats after a level failure.
  void recordLevelFailed({
    required int gemsMatched,
    required int playTimeSeconds,
  }) {
    levelsPlayed++;
    totalGemsMatched += gemsMatched;
    totalPlayTimeSeconds += playTimeSeconds;
  }

  Map<String, dynamic> toJson() => {
        'levelsPlayed': levelsPlayed,
        'levelsCompleted': levelsCompleted,
        'bestCombo': bestCombo,
        'totalGemsMatched': totalGemsMatched,
        'totalCoinsEarned': totalCoinsEarned,
        'bestMoveScore': bestMoveScore,
        'totalPlayTimeSeconds': totalPlayTimeSeconds,
        'threeStarCount': threeStarCount,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        levelsPlayed: json['levelsPlayed'] as int? ?? 0,
        levelsCompleted: json['levelsCompleted'] as int? ?? 0,
        bestCombo: json['bestCombo'] as int? ?? 0,
        totalGemsMatched: json['totalGemsMatched'] as int? ?? 0,
        totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
        bestMoveScore: json['bestMoveScore'] as int? ?? 0,
        totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
        threeStarCount: json['threeStarCount'] as int? ?? 0,
      );
}

/// Per-level completion data.
class LevelRecord {
  final int levelNumber;
  int highScore;
  int bestStars;
  int timesPlayed;
  int timesCompleted;

  LevelRecord({
    required this.levelNumber,
    this.highScore = 0,
    this.bestStars = 0,
    this.timesPlayed = 0,
    this.timesCompleted = 0,
  });

  void recordCompletion({required int score, required int stars}) {
    timesPlayed++;
    timesCompleted++;
    if (score > highScore) highScore = score;
    if (stars > bestStars) bestStars = stars;
  }

  void recordAttempt() {
    timesPlayed++;
  }

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'highScore': highScore,
        'bestStars': bestStars,
        'timesPlayed': timesPlayed,
        'timesCompleted': timesCompleted,
      };

  factory LevelRecord.fromJson(Map<String, dynamic> json) => LevelRecord(
        levelNumber: json['levelNumber'] as int? ?? 0,
        highScore: json['highScore'] as int? ?? 0,
        bestStars: json['bestStars'] as int? ?? 0,
        timesPlayed: json['timesPlayed'] as int? ?? 0,
        timesCompleted: json['timesCompleted'] as int? ?? 0,
      );
}

/// Complete save state for the player.
class SaveState {
  /// Current highest unlocked level.
  int currentLevel;

  /// Coins balance.
  int coins;

  /// Login streak (consecutive days).
  int loginStreak;

  /// Last login date (ISO 8601 string).
  String lastLoginDate;

  /// Player statistics.
  PlayerStats stats;

  /// Per-level records.
  Map<int, LevelRecord> levelRecords;

  /// Unlocked extras / power-ups.
  Set<String> unlockedExtras;

  /// Power-up inventory: maps power-up id to quantity owned.
  Map<String, int> powerUpInventory;

  /// Whether the tutorial has been shown.
  bool tutorialShown;

  /// The ID of the currently selected emoji theme.
  String selectedThemeId;

  /// Bonus moves accumulated over time (default max 60).
  int bonusMoves;

  /// Last time bonus moves were regenerated.
  DateTime? lastMoveRegenTime;

  SaveState({
    this.currentLevel = 1,
    this.coins = 0,
    this.loginStreak = 0,
    this.lastLoginDate = '',
    PlayerStats? stats,
    Map<int, LevelRecord>? levelRecords,
    Set<String>? unlockedExtras,
    Map<String, int>? powerUpInventory,
    this.tutorialShown = false,
    this.selectedThemeId = 'theme_fruit',
    this.bonusMoves = 0,
    this.maxBonusMoves = SaveState.defaultMaxBonusMoves,
    this.lastMoveRegenTime,
  })  : stats = stats ?? PlayerStats(),
        levelRecords = levelRecords ?? {},
        unlockedExtras = unlockedExtras ?? {},
        powerUpInventory = powerUpInventory ?? {};

  /// Default maximum bonus moves.
  static const int defaultMaxBonusMoves = 60;

  /// Maximum bonus moves that can be stored (upgrade-able via shop).
  int maxBonusMoves;

  /// Interval between bonus move regenerations.
  static const Duration regenInterval = Duration(minutes: 5);

  /// Minutes per regenerated move.
  static const int _regenMinutes = 5;

  /// Regenerate bonus moves based on elapsed time.
  /// Returns the number of moves regenerated.
  int regenerateMoves() {
    final now = DateTime.now();

    if (lastMoveRegenTime == null) {
      lastMoveRegenTime = now;
      return 0;
    }

    final lastRegen = lastMoveRegenTime!;
    final elapsed = now.difference(lastRegen);
    final intervals = elapsed.inSeconds ~/ (_regenMinutes * 60);

    if (intervals <= 0) return 0;

    final space = maxBonusMoves - bonusMoves;
    if (space <= 0) {
      // Already at max – keep timestamp current so we don't accumulate
      // a huge delta that gets applied later when moves are spent.
      lastMoveRegenTime = now;
      return 0;
    }

    final movesToAdd = intervals.clamp(0, space);
    bonusMoves = (bonusMoves + movesToAdd).clamp(0, maxBonusMoves);

    // Advance lastMoveRegenTime only by the consumed intervals
    // (keeps remainder for next calculation).
    lastMoveRegenTime = lastRegen.add(Duration(minutes: movesToAdd * _regenMinutes));

    return movesToAdd;
  }

  /// Consume all stored bonus moves and return the count consumed.
  int consumeBonusMoves() {
    final consumed = bonusMoves;
    bonusMoves = 0;
    return consumed;
  }

  /// Whether a given level is unlocked.
  bool isLevelUnlocked(int level) => level <= currentLevel;

  /// Get the record for a level, creating a new one if needed.
  LevelRecord levelRecord(int level) {
    return levelRecords.putIfAbsent(level, () => LevelRecord(levelNumber: level));
  }

  /// Record a level completion and update all relevant state.
  void recordLevelComplete({
    required int level,
    required int score,
    required int stars,
    required int gemsMatched,
    required int coinsEarned,
    required int maxCombo,
    required int playTimeSeconds,
  }) {
    // Update level record.
    levelRecord(level).recordCompletion(score: score, stars: stars);

    // Update stats.
    stats.recordLevelComplete(
      score: score,
      stars: stars,
      gemsMatched: gemsMatched,
      coinsEarned: coinsEarned,
      maxCombo: maxCombo,
      playTimeSeconds: playTimeSeconds,
    );

    // Add coins.
    coins += coinsEarned;

    // Unlock next level if this was the current highest.
    if (level >= currentLevel) {
      currentLevel = level + 1;
    }
  }

  /// Record a failed level attempt.
  void recordLevelFailed({
    required int level,
    required int gemsMatched,
    required int playTimeSeconds,
  }) {
    levelRecord(level).recordAttempt();
    stats.recordLevelFailed(
      gemsMatched: gemsMatched,
      playTimeSeconds: playTimeSeconds,
    );
  }

  /// Process daily login reward.
  /// Returns the coins awarded (0 if already logged in today).
  int processLogin(String todayDate, {required int dailyCoins}) {
    if (lastLoginDate == todayDate) return 0;

    // Check if consecutive day.
    if (_isConsecutiveDay(lastLoginDate, todayDate)) {
      loginStreak++;
    } else {
      loginStreak = 1;
    }

    lastLoginDate = todayDate;

    // Calculate reward with streak.
    final reward = dailyCoins;
    coins += reward;
    return reward;
  }

  /// Spend coins. Returns true if successful (enough coins).
  bool spendCoins(int amount) {
    if (amount < 0 || coins < amount) return false;
    coins -= amount;
    return true;
  }

  /// Unlock an extra / power-up.
  void unlockExtra(String extraId) {
    unlockedExtras.add(extraId);
  }

  /// Check if an extra is unlocked.
  bool isExtraUnlocked(String extraId) => unlockedExtras.contains(extraId);

  /// Get quantity of a power-up.
  int powerUpCount(String powerUpId) => powerUpInventory[powerUpId] ?? 0;

  /// Add power-ups to inventory.
  void addPowerUp(String powerUpId, {int count = 1}) {
    powerUpInventory[powerUpId] =
        (powerUpInventory[powerUpId] ?? 0) + count;
  }

  /// Use a power-up. Returns true if successful (had at least one).
  bool usePowerUp(String powerUpId) {
    final current = powerUpInventory[powerUpId] ?? 0;
    if (current <= 0) return false;
    powerUpInventory[powerUpId] = current - 1;
    return true;
  }

  /// Total stars earned across all levels.
  int get totalStars =>
      levelRecords.values.fold(0, (sum, r) => sum + r.bestStars);

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'coins': coins,
        'loginStreak': loginStreak,
        'lastLoginDate': lastLoginDate,
        'stats': stats.toJson(),
        'levelRecords': levelRecords.map(
          (k, v) => MapEntry(k.toString(), v.toJson()),
        ),
        'unlockedExtras': unlockedExtras.toList(),
        'powerUpInventory': powerUpInventory,
        'tutorialShown': tutorialShown,
        'selectedThemeId': selectedThemeId,
        'bonusMoves': bonusMoves,
        'maxBonusMoves': maxBonusMoves,
        'lastMoveRegenTime': lastMoveRegenTime?.toIso8601String(),
      };

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON map.
  factory SaveState.fromJson(Map<String, dynamic> json) {
    final levelRecordsJson =
        json['levelRecords'] as Map<String, dynamic>? ?? {};
    final levelRecords = <int, LevelRecord>{};
    for (final entry in levelRecordsJson.entries) {
      final level = int.tryParse(entry.key) ?? 0;
      levelRecords[level] =
          LevelRecord.fromJson(entry.value as Map<String, dynamic>);
    }

    final extrasJson = json['unlockedExtras'] as List<dynamic>? ?? [];

    final powerUpJson =
        json['powerUpInventory'] as Map<String, dynamic>? ?? {};
    final powerUpInventory = <String, int>{};
    for (final entry in powerUpJson.entries) {
      powerUpInventory[entry.key] = entry.value as int? ?? 0;
    }

    return SaveState(
      currentLevel: json['currentLevel'] as int? ?? 1,
      coins: json['coins'] as int? ?? 0,
      loginStreak: json['loginStreak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] as String? ?? '',
      stats: json['stats'] != null
          ? PlayerStats.fromJson(json['stats'] as Map<String, dynamic>)
          : PlayerStats(),
      levelRecords: levelRecords,
      unlockedExtras: extrasJson.map((e) => e as String).toSet(),
      powerUpInventory: powerUpInventory,
      tutorialShown: json['tutorialShown'] as bool? ?? false,
      selectedThemeId: json['selectedThemeId'] as String? ?? 'theme_fruit',
      bonusMoves: json['bonusMoves'] as int? ?? 0,
      maxBonusMoves: json['maxBonusMoves'] as int? ?? SaveState.defaultMaxBonusMoves,
      lastMoveRegenTime: json['lastMoveRegenTime'] != null
          ? DateTime.tryParse(json['lastMoveRegenTime'] as String)
          : null,
    );
  }

  /// Deserialize from JSON string.
  factory SaveState.fromJsonString(String jsonString) {
    return SaveState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Simple consecutive day check (compares ISO date strings).
  static bool _isConsecutiveDay(String lastDate, String todayDate) {
    if (lastDate.isEmpty) return false;
    try {
      final last = DateTime.parse(lastDate);
      final today = DateTime.parse(todayDate);
      final diff = today.difference(last).inDays;
      return diff == 1;
    } catch (_) {
      return false;
    }
  }
}

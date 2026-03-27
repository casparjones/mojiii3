import 'package:flutter/material.dart';

import '../game/game_state_manager.dart';
import '../game/level_generator.dart';
import '../main.dart';
import 'game_screen.dart';

/// Scrollable grid of levels showing progress, stars, and highscores.
class LevelSelectScreen extends StatefulWidget {
  /// Number of level tiles to display in the grid.
  /// Defaults to 100 levels.
  final int totalLevels;

  const LevelSelectScreen({
    super.key,
    this.totalLevels = 100,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  GameStateManager get _gsm => GameStateManagerProvider.read(context);

  void _onLevelTap(int levelNumber) {
    final gsm = _gsm;
    if (!gsm.isLevelUnlocked(levelNumber)) return;

    final config = gsm.generateLevel(levelNumber);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          levelConfig: config,
          coinBalance: gsm.coins,
          onLevelEnd: (won, score, stars, coinsEarned) {
            if (won) {
              gsm.recordLevelComplete(
                level: levelNumber,
                score: score,
                stars: stars,
                gemsMatched: 0,
                coinsEarned: coinsEarned,
                maxCombo: 0,
                playTimeSeconds: 0,
              );
            } else {
              gsm.recordLevelFailed(
                level: levelNumber,
                gemsMatched: 0,
                playTimeSeconds: 0,
              );
            }
          },
        ),
      ),
    );
  }

  /// Returns level numbers for the "New Levels" tab:
  /// unlocked levels with no completion (stars == 0), plus the next locked
  /// level as a preview.
  List<int> _newLevels(GameStateManager gsm) {
    final result = <int>[];
    int? firstLockedLevel;
    for (var i = 1; i <= widget.totalLevels; i++) {
      final unlocked = gsm.isLevelUnlocked(i);
      final record = gsm.levelRecords[i];
      final stars = record?.bestStars ?? 0;
      if (unlocked && stars == 0) {
        result.add(i);
      } else if (!unlocked && firstLockedLevel == null) {
        firstLockedLevel = i;
      }
    }
    if (firstLockedLevel != null) {
      result.add(firstLockedLevel);
    }
    return result;
  }

  /// Returns level numbers for the "Completed" tab:
  /// levels with bestStars > 0.
  List<int> _completedLevels(GameStateManager gsm) {
    final result = <int>[];
    for (var i = 1; i <= widget.totalLevels; i++) {
      final record = gsm.levelRecords[i];
      final stars = record?.bestStars ?? 0;
      if (stars > 0) {
        result.add(i);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213e),
          title: const Text(
            'Select Level',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'New Levels'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _gsm,
          builder: (context, _) {
            final gsm = _gsm;
            final newLevels = _newLevels(gsm);
            final completed = _completedLevels(gsm);
            return TabBarView(
              children: [
                _buildFilteredGrid(
                  levels: newLevels,
                  emptyMessage: 'Alle Level geschafft! \u{1F389}',
                ),
                _buildFilteredGrid(
                  levels: completed,
                  emptyMessage: 'Noch kein Level abgeschlossen',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilteredGrid({
    required List<int> levels,
    required String emptyMessage,
  }) {
    if (levels.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          return _buildLevelTile(levels[index]);
        },
      ),
    );
  }

  Widget _buildLevelTile(int levelNumber) {
    final gsm = _gsm;
    final unlocked = gsm.isLevelUnlocked(levelNumber);
    final record = gsm.levelRecords[levelNumber];
    final stars = record?.bestStars ?? 0;
    final highScore = record?.highScore ?? 0;

    return GestureDetector(
      key: Key('level_tile_$levelNumber'),
      onTap: unlocked ? () => _onLevelTap(levelNumber) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: unlocked
              ? const Color(0xFF16213e)
              : const Color(0xFF0f0f1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? (stars > 0
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.white24)
                : Colors.white10,
            width: 1.5,
          ),
          boxShadow: unlocked && stars >= 3
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Text('\u{1F512}', style: TextStyle(fontSize: 24))
            else ...[
              Text(
                '$levelNumber',
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white30,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStars(stars),
              if (highScore > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$highScore',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Text(
          i < count ? '\u2B50' : '\u2606',
          style: TextStyle(
            fontSize: 12,
            color: i < count ? Colors.amber : Colors.white30,
          ),
        );
      }),
    );
  }
}

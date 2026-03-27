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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: ListenableBuilder(
        listenable: _gsm,
        builder: (context, _) => _buildLevelGrid(),
      ),
    );
  }

  Widget _buildLevelGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.totalLevels,
        itemBuilder: (context, index) {
          final levelNumber = index + 1;
          return _buildLevelTile(levelNumber);
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
              const Text('🔒', style: TextStyle(fontSize: 24))
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
          i < count ? '⭐' : '☆',
          style: TextStyle(
            fontSize: 12,
            color: i < count ? Colors.amber : Colors.white30,
          ),
        );
      }),
    );
  }
}

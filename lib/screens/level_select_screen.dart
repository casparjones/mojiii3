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
  bool _didRegenerate = false;

  /// Whether the player has any moves available (bonus moves or extra-moves
  /// power-ups). The level's own moveLimit is always granted, but bonus moves
  /// come from regeneration / power-ups.
  bool _hasAvailableMoves(GameStateManager gsm) {
    // Regenerate once per screen visit; avoid calling during build since
    // it triggers notifyListeners which is illegal inside the build phase.
    if (!_didRegenerate) {
      _didRegenerate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        gsm.regenerateMoves();
      });
    }
    final bonus = gsm.saveState.bonusMoves;
    final extraMovesPowerUp =
        gsm.saveState.powerUpCount('powerup_extra_moves');
    return bonus > 0 || extraMovesPowerUp > 0;
  }

  /// Whether a level is already completed (has stars > 0).
  bool _isCompleted(GameStateManager gsm, int levelNumber) {
    final record = gsm.levelRecords[levelNumber];
    return (record?.bestStars ?? 0) > 0;
  }

  void _onLevelTap(int levelNumber) {
    final gsm = _gsm;
    if (!gsm.isLevelUnlocked(levelNumber)) return;

    // Block new (not yet completed) levels if the player has no moves.
    if (!_isCompleted(gsm, levelNumber) && !_hasAvailableMoves(gsm)) {
      _showNoMovesHint();
      return;
    }

    final config = gsm.generateLevel(levelNumber);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          levelConfig: config,
          coinBalance: gsm.coins,
          saveState: gsm.saveState,
          levelNumber: levelNumber,
          onPowerUpUsed: () {
            gsm.persistState();
          },
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

  void _showNoMovesHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Keine Moves! Farme Moves in abgeschlossenen Leveln!'),
        duration: Duration(seconds: 3),
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

  /// Section color tint based on level number (groups of 10).
  Color _sectionColor(int levelNumber) {
    final section = ((levelNumber - 1) ~/ 10) % 10;
    switch (section) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.lightBlue;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.pink;
      case 6:
        return const Color(0xFF1a237e); // dark blue (space)
      case 7:
        return Colors.teal;
      case 8:
        return Colors.red;
      case 9:
        return const Color(0xFF7b1fa2); // violet (crystal)
      default:
        return Colors.green;
    }
  }

  /// Section name based on level number.
  String _sectionName(int sectionIndex) {
    const names = [
      'Natur',
      'Meer',
      'Zauberwald',
      'Schnee',
      'W\u00fcste',
      'Candy',
      'Space',
      'Tiefsee',
      'Vulkan',
      'Kristall',
    ];
    return names[sectionIndex % names.length];
  }

  /// Check if all levels in a section (1-based section number) are completed.
  bool _isSectionCompleted(GameStateManager gsm, int sectionIndex) {
    final start = sectionIndex * 10 + 1;
    final end = start + 9;
    for (var i = start; i <= end && i <= widget.totalLevels; i++) {
      final record = gsm.levelRecords[i];
      if ((record?.bestStars ?? 0) == 0) return false;
    }
    return true;
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
                _buildSectionedGrid(
                  levels: newLevels,
                  emptyMessage: 'Alle Level geschafft! \u{1F389}',
                ),
                _buildSectionedGrid(
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

  /// Builds a CustomScrollView with 2-column grids grouped by section (10
  /// levels each), separated by trophy banners.
  Widget _buildSectionedGrid({
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

    final gsm = _gsm;

    // Group levels by section (0-based section index).
    final Map<int, List<int>> sections = {};
    for (final lvl in levels) {
      final sectionIdx = (lvl - 1) ~/ 10;
      sections.putIfAbsent(sectionIdx, () => []);
      sections[sectionIdx]!.add(lvl);
    }

    final sortedSectionKeys = sections.keys.toList()..sort();

    final List<Widget> slivers = [];

    // Top padding.
    slivers.add(const SliverPadding(padding: EdgeInsets.only(top: 16)));

    for (var i = 0; i < sortedSectionKeys.length; i++) {
      final sectionIdx = sortedSectionKeys[i];
      final sectionLevels = sections[sectionIdx]!;

      // Section header with theme name.
      final sColor = _sectionColor(sectionIdx * 10 + 1);
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: sColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_sectionName(sectionIdx)} (${sectionIdx * 10 + 1}-${sectionIdx * 10 + 10})',
                style: TextStyle(
                  color: sColor.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ));

      // Grid for this section's levels (2 columns).
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLevelTile(sectionLevels[index]),
            childCount: sectionLevels.length,
          ),
        ),
      ));

      // Trophy separator after this section (only if not the last section).
      if (i < sortedSectionKeys.length - 1) {
        final completed = _isSectionCompleted(gsm, sectionIdx);
        slivers.add(SliverToBoxAdapter(
          child: _buildTrophySeparator(sectionIdx, completed),
        ));
      }
    }

    // Bottom padding.
    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 24)));

    return CustomScrollView(slivers: slivers);
  }

  /// Builds a trophy separator banner between level sections.
  Widget _buildTrophySeparator(int sectionIndex, bool completed) {
    final sectionNum = sectionIndex + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: completed
                ? [
                    Colors.amber.withValues(alpha: 0.25),
                    Colors.amber.withValues(alpha: 0.10),
                  ]
                : [
                    Colors.grey.withValues(alpha: 0.15),
                    Colors.grey.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              completed ? '\u{1F3C6}' : '\u{1F512}',
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 12),
            Text(
              completed
                  ? 'Abschnitt $sectionNum abgeschlossen'
                  : 'Abschnitt $sectionNum  ???',
              style: TextStyle(
                color: completed ? Colors.amber : Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              completed ? '\u{1F3C6}' : '\u{1F512}',
              style: const TextStyle(fontSize: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTile(int levelNumber) {
    final gsm = _gsm;
    final unlocked = gsm.isLevelUnlocked(levelNumber);
    final record = gsm.levelRecords[levelNumber];
    final stars = record?.bestStars ?? 0;
    final highScore = record?.highScore ?? 0;
    final completed = stars > 0;
    // New levels are blocked when the player has no moves.
    final noMoves = unlocked && !completed && !_hasAvailableMoves(gsm);

    final sectionColor = _sectionColor(levelNumber);

    return GestureDetector(
      key: Key('level_tile_$levelNumber'),
      onTap: unlocked ? () => _onLevelTap(levelNumber) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: unlocked && !noMoves
                ? [
                    sectionColor.withValues(alpha: 0.18),
                    const Color(0xFF16213e),
                  ]
                : [
                    const Color(0xFF0f0f1a),
                    const Color(0xFF0f0f1a),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? (noMoves
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : stars > 0
                        ? Colors.amber.withValues(alpha: 0.5)
                        : sectionColor.withValues(alpha: 0.35))
                : Colors.white10,
            width: 2,
          ),
          boxShadow: unlocked && stars >= 3
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Text('\u{1F512}', style: TextStyle(fontSize: 32))
            else if (noMoves) ...[
              const Text('\u{1F512}', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              const Text(
                'Keine Moves',
                key: Key('no_moves_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text(
                '$levelNumber',
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white30,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _buildStars(stars),
              if (highScore > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$highScore',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
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
            fontSize: 18,
            color: i < count ? Colors.amber : Colors.white30,
          ),
        );
      }),
    );
  }
}

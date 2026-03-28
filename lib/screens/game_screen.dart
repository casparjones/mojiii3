import 'dart:async';

import 'package:flutter/material.dart';

import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';
import '../game/audio_manager.dart';
import '../game/board_animation_controller.dart';
import '../game/music_manager.dart';
import '../main.dart';
import '../game/deadlock_detector.dart';
import '../game/game_state_manager.dart';
import '../game/gravity_handler.dart';
import '../game/level_generator.dart';
import '../game/match_detector.dart';
import '../game/obstacle_manager.dart';
import '../game/save_system.dart';
import '../game/score_calculator.dart';
import '../game/store_config.dart';
import '../game/background_manager.dart';
import 'package:share_plus/share_plus.dart';

/// Temporary floating reward text shown above the board.
class _FloatingReward {
  final String text;
  final double x;
  final double y;
  final DateTime createdAt;

  _FloatingReward({
    required this.text,
    required this.x,
    required this.y,
  }) : createdAt = DateTime.now();

  /// Whether this reward has expired (after 1.5 seconds).
  bool get isExpired =>
      DateTime.now().difference(createdAt).inMilliseconds > 1500;
}

class GameScreen extends StatefulWidget {
  /// Optional LevelConfig. If null, plays in free/endless mode.
  final LevelConfig? levelConfig;

  /// Callback when level ends. Parameters: won, score, stars, coinsEarned.
  final void Function(bool won, int score, int stars, int coinsEarned)?
      onLevelEnd;

  /// Current coin balance to display. If null, coin display is hidden.
  final int? coinBalance;

  /// Optional SaveState for power-up inventory access.
  final SaveState? saveState;

  /// Callback when a power-up is used (to persist changes externally).
  final VoidCallback? onPowerUpUsed;

  /// Optional AudioManager for sound effects. If null, a default one is created.
  final AudioManager? audioManager;

  /// Optional level number for farming rewards on 3-star replays.
  final int? levelNumber;

  const GameScreen({
    super.key,
    this.levelConfig,
    this.onLevelEnd,
    this.coinBalance,
    this.saveState,
    this.onPowerUpUsed,
    this.audioManager,
    this.levelNumber,
  });

  @override
  State<GameScreen> createState() => GameScreenState();
}

@visibleForTesting
class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late int _rows;
  late int _cols;

  late Board _board;
  late BoardAnimationController _animController;
  late MatchDetector _matchDetector;
  late GravityHandler _gravityHandler;
  late ScoreCalculator _scoreCalculator;
  late DeadlockDetector _deadlockDetector;
  late ObstacleManager _obstacleManager;

  int _score = 0;
  int _movesUsed = 0;
  int get _movesRemaining => widget.saveState?.bonusMoves ?? 0;
  int _gemsCollected = 0;
  int _obstaclesDestroyed = 0;
  Map<GemType, int> _gemsCollectedByType = {};
  Position? _selected;
  bool _processing = false;
  Set<Position> _hintPositions = {};

  // Swipe/drag state
  Position? _swipeStart;
  double _swipeCellW = 0;
  double _swipeCellH = 0;
  Set<Position> _matchedPositions = {};
  String? _comboText;
  double _comboX = 0.5;
  double _comboY = 0.5;
  bool _levelEnded = false;
  int _maxCascade = 0;
  int _coinsEarnedThisLevel = 0;

  late AudioManager _audioManager;
  MusicManager? _musicManager;

  late AnimationController _comboAnimController;
  Timer? _comboFadeOutTimer;

  /// Whether we are in level mode (vs free/endless mode).
  bool get _isLevelMode => widget.levelConfig != null;

  LevelConfig? get _levelConfig => widget.levelConfig;

  @override
  void initState() {
    super.initState();
    _audioManager = widget.audioManager ??
        AudioManager(
          settingsProvider: () => GameSettings(soundEnabled: true),
          useAudio: true,
        );
    _matchDetector = const MatchDetector();
    _scoreCalculator = const ScoreCalculator();
    _deadlockDetector = const DeadlockDetector();
    _obstacleManager = ObstacleManager();
    _animController = BoardAnimationController(vsync: this);
    _animController.addListener(() {
      if (mounted) setState(() {});
    });
    _comboAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _comboAnimController.addListener(() {
      if (mounted) setState(() {});
    });
    _initBoard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _musicManager ??= MusicManagerProvider.read(context);
  }

  @override
  void dispose() {
    _audioManager.dispose();
    _animController.dispose();
    _comboAnimController.dispose();
    _comboFadeOutTimer?.cancel();
    super.dispose();
  }

  void _initBoard() {
    if (_isLevelMode) {
      final config = _levelConfig!;
      _rows = config.rows;
      _cols = config.cols;
      _gravityHandler = GravityHandler(gemTypeCount: config.gemTypeCount);
      _obstacleManager = ObstacleManager();
      _obstacleManager.initialize(config.obstacles);
    } else {
      _rows = 8;
      _cols = 8;
      _gravityHandler = GravityHandler();
      _obstacleManager = ObstacleManager();
    }

    _board = Board.initialize(BoardConfig(rows: _rows, cols: _cols,
        gemTypeCount: _isLevelMode ? _levelConfig!.gemTypeCount : 6));
    _score = 0;
    _movesUsed = 0;
    _gemsCollected = 0;
    _obstaclesDestroyed = 0;
    _gemsCollectedByType = {};
    _selected = null;
    _hintPositions = {};
    _matchedPositions = {};
    _dismissComboToast();
    _levelEnded = false;
    _maxCascade = 0;
    _coinsEarnedThisLevel = 0;
    _matchCount = 0;
    _farmingCoins = 0;
    _farmingMoves = 0;
    _floatingRewards.clear();

    // Regenerate moves in the global save state.
    final saveState = widget.saveState;
    if (saveState != null) {
      saveState.regenerateMoves();
    }

    // Ensure music resumes when (re)starting a level.
    _musicManager?.resume();
  }

  void _onTileTap(int row, int col) {
    if (_processing || _levelEnded) return;

    final tapped = Position(row, col);

    // Don't allow selecting cells blocked by stone obstacles.
    if (_obstacleManager.blocksCell(tapped)) return;

    // Don't allow selecting locked gems.
    if (_obstacleManager.isLocked(tapped)) {
      // We still allow selecting, but swap will be blocked if the gem is locked.
    }

    if (_selected == null) {
      _audioManager.playTap();
      setState(() {
        _selected = tapped;
        _hintPositions = {};
        _dismissComboToast();
      });
      return;
    }

    if (_selected == tapped) {
      setState(() => _selected = null);
      return;
    }

    if (!_selected!.isAdjacentTo(tapped)) {
      setState(() => _selected = tapped);
      return;
    }

    // Check if either position is locked by an obstacle.
    if (_obstacleManager.isLocked(_selected!) ||
        _obstacleManager.isLocked(tapped)) {
      setState(() => _selected = tapped);
      return;
    }

    _executeSwap(_selected!, tapped);
  }

  void _onPanStart(DragStartDetails details, double cellW, double cellH) {
    if (_processing || _levelEnded) return;
    final col = (details.localPosition.dx / cellW).floor().clamp(0, _cols - 1);
    final row = (details.localPosition.dy / cellH).floor().clamp(0, _rows - 1);
    final pos = Position(row, col);
    if (_obstacleManager.blocksCell(pos)) return;
    _swipeStart = pos;
    _swipeCellW = cellW;
    _swipeCellH = cellH;
    // Clear tap selection when starting a swipe.
    if (_selected != null) {
      setState(() {
        _selected = null;
        _hintPositions = {};
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _swipeStart = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_processing || _levelEnded || _swipeStart == null) return;

    final dx = details.localPosition.dx - (_swipeStart!.col + 0.5) * _swipeCellW;
    final dy = details.localPosition.dy - (_swipeStart!.row + 0.5) * _swipeCellH;

    // Require at least half a cell size of drag distance before triggering.
    final threshold = (_swipeCellW < _swipeCellH ? _swipeCellW : _swipeCellH) * 0.35;
    if (dx.abs() < threshold && dy.abs() < threshold) return;

    Position target;
    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      target = Position(
        _swipeStart!.row,
        (_swipeStart!.col + (dx > 0 ? 1 : -1)).clamp(0, _cols - 1),
      );
    } else {
      // Vertical swipe
      target = Position(
        (_swipeStart!.row + (dy > 0 ? 1 : -1)).clamp(0, _rows - 1),
        _swipeStart!.col,
      );
    }

    final start = _swipeStart!;
    _swipeStart = null; // Consume the swipe so it only triggers once.

    if (!start.isAdjacentTo(target)) return;
    if (_obstacleManager.blocksCell(target)) return;
    if (_obstacleManager.isLocked(start) || _obstacleManager.isLocked(target)) return;

    _executeSwap(start, target);
  }

  Future<void> _executeSwap(Position a, Position b) async {
    setState(() {
      _processing = true;
      _selected = null;
      _dismissComboToast();
      _hintPositions = {};
    });

    // Check if swap would produce a match.
    final boardCopy = _board.copy();
    boardCopy.swap(a, b);
    final wouldMatch = _matchDetector.findMatches(boardCopy).isNotEmpty;

    if (!wouldMatch) {
      await _animController.animateSwapFailed(a, b);
      setState(() => _processing = false);
      return;
    }

    // Animate the swap.
    await _animController.animateSwap(a, b);
    _audioManager.playSwap();

    // Apply the swap.
    _board.swap(a, b);
    _movesUsed++;
    if (!_isFarmingMode && _movesRemaining > 0) {
      final saveState = widget.saveState;
      if (saveState != null) {
        saveState.bonusMoves = (saveState.bonusMoves - 1).clamp(0, saveState.maxBonusMoves);
      }
    }
    setState(() {});

    // Run cascade loop with obstacle processing.
    await _runCascadeLoop();

    // Process slime spreading (after player's turn).
    if (_obstacleManager.obstacles.values
        .any((o) => o.type == ObstacleType.slime && !o.isDestroyed)) {
      final slimeResult =
          _obstacleManager.processSlimeSpread(_rows, _cols);
      if (slimeResult.slimeSpread.isNotEmpty) {
        setState(() {});
      }
    }

    // Check for deadlock.
    if (_deadlockDetector.isDeadlocked(_board)) {
      await Future.delayed(const Duration(milliseconds: 300));
      _deadlockDetector.shuffleBoard(_board);
      setState(() {});
    }

    // Check level end conditions (after cascade completes).
    if (_isLevelMode && !_levelEnded) {
      _checkLevelEnd();
    }

    // Check free mode game over (out of moves, after cascade completes).
    if (!_isLevelMode && !_levelEnded && _movesRemaining <= 0) {
      _endFreeMode();
    }

    setState(() => _processing = false);
  }

  Future<void> _runCascadeLoop() async {
    int cascadeLevel = 0;
    int totalScore = 0;

    while (true) {
      final matches = _matchDetector.findMatches(_board);
      if (matches.isEmpty) break;

      cascadeLevel++;

      final allMatchedPos = <Position>{};
      for (final m in matches) {
        allMatchedPos.addAll(m.positions);
      }

      // Track gems collected by type.
      for (final m in matches) {
        _gemsCollectedByType[m.gemType] =
            (_gemsCollectedByType[m.gemType] ?? 0) + m.positions.length;
      }

      // Farming rewards for 3-star replays.
      if (_isFarmingMode) {
        _matchCount++;
        if (_matchCount.isOdd) {
          // Odd matches: +2 coins
          _farmingCoins += 2;
          if (widget.saveState != null) {
            widget.saveState!.coins += 2;
          }
          _addFloatingReward('+2\uD83E\uDE99', allMatchedPos);
        } else {
          // Even matches: +1 bonus move
          _farmingMoves += 1;
          if (widget.saveState != null) {
            widget.saveState!.bonusMoves =
                (widget.saveState!.bonusMoves + 1).clamp(0, widget.saveState!.maxBonusMoves);
          }
          _addFloatingReward('+1\uD83D\uDC8A', allMatchedPos);
        }
      }

      // Score this step.
      final stepScore = _scoreCalculator.scoreCascadeStep(
        matches,
        cascadeLevel: cascadeLevel,
      );
      totalScore += stepScore.stepTotal;

      // Process obstacles.
      final obstacleResult = _obstacleManager.processMatches(
        allMatchedPos,
        _rows,
        _cols,
      );
      _obstaclesDestroyed += obstacleResult.destroyedCount;
      _obstacleManager.cleanupDestroyed();

      // Play sound for match/combo.
      if (cascadeLevel > 1) {
        _audioManager.playCombo();
      } else {
        _audioManager.playMatch();
      }

      // Animate match.
      setState(() => _matchedPositions = allMatchedPos);
      await _animController.animateMatch(allMatchedPos);

      // Remove matched gems.
      _board.removeGems(allMatchedPos);
      setState(() => _matchedPositions = {});

      // Calculate fall moves.
      final fallMoves = _calculateFallMoves();

      // Apply gravity.
      _gravityHandler.applyGravity(_board);

      // Animate falls.
      if (fallMoves.isNotEmpty) {
        await _animController.animateFall(fallMoves);
      }
      setState(() {});

      // Find spawn positions.
      final spawnPositions = <Position>[];
      for (var c = 0; c < _cols; c++) {
        for (var r = 0; r < _rows; r++) {
          if (_board.gemAt(Position(r, c)) == null) {
            spawnPositions.add(Position(r, c));
          }
        }
      }

      // Refill.
      _gravityHandler.refill(_board);
      setState(() {});

      // Animate spawn.
      if (spawnPositions.isNotEmpty) {
        await _animController.animateSpawn(spawnPositions);
      }

      if (cascadeLevel > 1) {
        // Compute average position of all matched gems for combo placement.
        double comboAvgCol = 0;
        double comboAvgRow = 0;
        for (final p in allMatchedPos) {
          comboAvgCol += p.col;
          comboAvgRow += p.row;
        }
        comboAvgCol /= allMatchedPos.length;
        comboAvgRow /= allMatchedPos.length;
        _showComboToast(
          '${cascadeLevel}x Combo!',
          x: comboAvgCol / _cols,
          y: comboAvgRow / _rows,
        );
      }
    }

    _gemsCollected += totalScore > 0 ? cascadeLevel : 0;
    if (cascadeLevel > _maxCascade) _maxCascade = cascadeLevel;

    // Count total gems matched from the type map.
    final totalGems =
        _gemsCollectedByType.values.fold(0, (a, b) => a + b);
    _gemsCollected = totalGems;

    // Track coins earned from this move's score.
    final moveCoins =
        (totalScore * _scoreCalculator.config.coinConversionRate).round();
    _coinsEarnedThisLevel += moveCoins;

    setState(() {
      _score += totalScore;
      if (cascadeLevel <= 1) _dismissComboToast();
    });
  }

  void _dismissComboToast() {
    _comboFadeOutTimer?.cancel();
    _comboAnimController.reset();
    _comboText = null;
  }

  void _showComboToast(String text, {double x = 0.5, double y = 0.5}) {
    _comboFadeOutTimer?.cancel();
    setState(() {
      _comboText = text;
      _comboX = x;
      _comboY = y;
    });
    _comboAnimController.forward(from: 0.0);
    _comboFadeOutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _comboAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _comboText = null;
            });
          }
        });
      }
    });
  }

  void _checkLevelEnd() {
    final config = _levelConfig!;
    final objective = config.objective;

    // Check win conditions.
    bool objectiveMet = false;
    switch (objective.type) {
      case LevelObjectiveType.score:
        objectiveMet = _score >= objective.targetScore;
        break;
      case LevelObjectiveType.collectGems:
        objectiveMet = _isGemObjectiveMet(objective.targetGems);
        break;
      case LevelObjectiveType.destroyObstacles:
        objectiveMet = _obstaclesDestroyed >= objective.targetObstacles;
        break;
    }

    if (objectiveMet) {
      _endLevel(won: true);
      return;
    }

    // Check lose condition: out of moves.
    if (config.constraintType == LevelConstraintType.moves &&
        _movesRemaining <= 0) {
      _endLevel(won: false);
      return;
    }
  }

  bool _isGemObjectiveMet(Map<GemType, int> targets) {
    for (final entry in targets.entries) {
      if ((_gemsCollectedByType[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }

  void _endLevel({required bool won}) {
    _levelEnded = true;
    _musicManager?.pause();

    int stars = 0;
    int coinsEarned = 0;

    if (won) {
      final levelScore = _scoreCalculator.scoreLevelComplete(
        totalMoveScore: _score,
        movesRemaining: _movesRemaining,
        targetScore: _levelConfig!.objective.targetScore,
        twoStarScore: _levelConfig!.objective.twoStarScore,
        threeStarScore: _levelConfig!.objective.threeStarScore,
      );
      stars = levelScore.stars;
      coinsEarned = levelScore.coinsEarned;
      _score = levelScore.totalScore;
    }

    if (won) {
      _audioManager.playWin();
    } else {
      _audioManager.playLose();
    }

    widget.onLevelEnd?.call(won, _score, stars, coinsEarned);

    // Show dialog after frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showLevelEndDialog(won, stars, coinsEarned);
      }
    });
  }

  /// End the free/endless mode game when moves run out.
  void _endFreeMode() {
    _levelEnded = true;
    _musicManager?.pause();
    _audioManager.playLose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showFreeModeGameOverDialog();
      }
    });
  }

  void _showFreeModeGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('free_mode_game_over_dialog'),
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Game Over',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            if (_coinsEarnedThisLevel > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+$_coinsEarnedThisLevel coins',
                style:
                    const TextStyle(color: Colors.amberAccent, fontSize: 16),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('free_mode_play_again_btn'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _initBoard());
              _musicManager?.resume();
            },
            child: const Text(
              'Play Again',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the current level is a trophy milestone (every 10 levels).
  bool get _isTrophyLevel {
    final lvl = widget.levelNumber;
    return lvl != null && lvl > 0 && lvl % 10 == 0;
  }

  void _shareTrophy() async {
    final lvl = widget.levelNumber ?? 0;
    final storeUrl = await StoreConfig.getStoreUrl();
    final text =
        'Ich habe Level $lvl in Match3 geschafft! Probier es auch: $storeUrl';
    await Share.share(text);
  }

  void _showLevelEndDialog(bool won, int stars, int coinsEarned) {
    final showTrophy = won && _isTrophyLevel;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          won ? 'Level Complete!' : 'Level Failed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: won ? Colors.amberAccent : Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTrophy) ...[
              const Text(
                '\uD83C\uDFC6',
                key: Key('trophy_icon'),
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 4),
              Text(
                'Meilenstein: Level ${widget.levelNumber}!',
                key: const Key('trophy_milestone_text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (won) ...[
              Text(
                _starString(stars),
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Score: $_score',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            if (won && coinsEarned > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+$coinsEarned coins',
                style:
                    const TextStyle(color: Colors.amberAccent, fontSize: 16),
              ),
            ],
            if (won && (_farmingCoins > 0 || _farmingMoves > 0)) ...[
              const SizedBox(height: 8),
              const Text(
                'Farming Bonus:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_farmingCoins > 0)
                Text(
                  '+$_farmingCoins \uD83E\uDE99 Coins',
                  key: const Key('farming_coins_summary'),
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 14),
                ),
              if (_farmingMoves > 0)
                Text(
                  '+$_farmingMoves \uD83D\uDC8A Bonus Moves',
                  key: const Key('farming_moves_summary'),
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                ),
            ],
            if (!won && widget.coinBalance != null) ...[
              const SizedBox(height: 8),
              Text(
                'Coins: ${widget.coinBalance}',
                key: const Key('level_failed_coin_balance'),
                style: const TextStyle(color: Colors.amberAccent, fontSize: 16),
              ),
              if (widget.coinBalance! < 100) ...[
                const SizedBox(height: 6),
                const Text(
                  'Spiele vorherige Level um Coins zu verdienen',
                  key: Key('low_coins_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _initBoard());
              _musicManager?.resume();
            },
            child: Text(
              won ? 'Retry' : 'Try Again',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          if (showTrophy)
            TextButton(
              key: const Key('share_trophy_btn'),
              onPressed: _shareTrophy,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, color: Colors.amberAccent, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Teilen',
                    style: TextStyle(color: Colors.amberAccent),
                  ),
                ],
              ),
            ),
          if (!won)
            TextButton(
              key: const Key('back_to_level_select_btn'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _musicManager?.resume();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Level-Auswahl',
                style: TextStyle(color: Colors.amberAccent),
              ),
            ),
          if (won)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _musicManager?.resume();
                Navigator.of(context).maybePop();
              },
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.amberAccent),
              ),
            ),
        ],
      ),
    );
  }

  String _starString(int stars) {
    const filled = '\u2B50';
    const empty = '\u2606';
    return List.generate(3, (i) => i < stars ? filled : empty).join(' ');
  }

  List<FallMove> _calculateFallMoves() {
    final moves = <FallMove>[];
    for (var c = 0; c < _cols; c++) {
      var writeRow = _rows - 1;
      for (var r = _rows - 1; r >= 0; r--) {
        // Skip cells blocked by stone obstacles.
        if (_obstacleManager.blocksCell(Position(r, c))) continue;

        final gem = _board.gemAt(Position(r, c));
        if (gem != null) {
          if (r != writeRow) {
            moves.add(
                FallMove(from: Position(r, c), to: Position(writeRow, c)));
          }
          writeRow--;
        }
      }
    }
    return moves;
  }

  void _showHint() {
    final hint = _deadlockDetector.findHint(_board);
    if (hint != null) {
      setState(() {
        _hintPositions = {hint.from, hint.to};
        _selected = null;
      });
    }
  }

  String _specialIndicator(SpecialType special) {
    switch (special) {
      case SpecialType.none:
        return '';
      case SpecialType.stripedHorizontal:
        return '\u2194';
      case SpecialType.stripedVertical:
        return '\u2195';
      case SpecialType.bomb:
        return '\uD83D\uDCA3';
      case SpecialType.rainbow:
        return '\u2728';
    }
  }

  String _obstacleEmoji(ObstacleType type) {
    switch (type) {
      case ObstacleType.ice:
        return '\u2744\uFE0F'; // ❄️
      case ObstacleType.stone:
        return '\uD83E\uDEA8'; // 🪨
      case ObstacleType.chain:
        return '\u26D3\uFE0F'; // ⛓️
      case ObstacleType.slime:
        return '\uD83D\uDFE2'; // 🟢
    }
  }

  // ---- Farming rewards state ----
  int _matchCount = 0;
  int _farmingCoins = 0;
  int _farmingMoves = 0;
  final List<_FloatingReward> _floatingRewards = [];

  /// Whether the current level is a 3-star replay (farming mode).
  bool get _isFarmingMode {
    final levelNum = widget.levelNumber;
    if (levelNum == null) return false;
    final saveState = widget.saveState;
    if (saveState == null) return false;
    return saveState.levelRecords[levelNum]?.bestStars == 3;
  }

  void _addFloatingReward(String text, Set<Position> positions) {
    // Compute average position of matched gems for placement.
    if (positions.isEmpty) return;
    double avgRow = 0;
    double avgCol = 0;
    for (final p in positions) {
      avgRow += p.row;
      avgCol += p.col;
    }
    avgRow /= positions.length;
    avgCol /= positions.length;
    _floatingRewards.add(_FloatingReward(
      text: text,
      x: avgCol / _cols,
      y: avgRow / _rows,
    ));
    // Clean up expired rewards.
    _floatingRewards.removeWhere((r) => r.isExpired);
  }

  // ---- Power-Up IDs ----
  static const String powerUpExtraMoves = 'powerup_extra_moves';
  static const String powerUpMegaMoves = 'powerup_mega_moves';
  static const String powerUpShuffle = 'powerup_shuffle';
  static const String powerUpColorBomb = 'powerup_color_bomb';

  /// Get the count of a power-up from the save state.
  int _powerUpCount(String powerUpId) {
    return widget.saveState?.powerUpCount(powerUpId) ?? 0;
  }

  /// Maximum moves allowed (from save state or fallback).
  int get _maxMoves => widget.saveState?.maxBonusMoves ?? 60;

  /// Use the Extra Moves power-up: adds up to 20 moves (capped at max).
  void _useExtraMoves() {
    if (_processing || _levelEnded) return;
    final saveState = widget.saveState;
    if (saveState == null || !saveState.usePowerUp(powerUpExtraMoves)) return;
    setState(() {
      saveState.bonusMoves = (saveState.bonusMoves + 20).clamp(0, _maxMoves);
    });
    widget.onPowerUpUsed?.call();
  }

  /// Use the Mega Moves power-up: adds up to 60 moves (capped at max).
  void _useMegaMoves() {
    if (_processing || _levelEnded) return;
    final saveState = widget.saveState;
    if (saveState == null || !saveState.usePowerUp(powerUpMegaMoves)) return;
    setState(() {
      saveState.bonusMoves = (saveState.bonusMoves + 60).clamp(0, _maxMoves);
    });
    widget.onPowerUpUsed?.call();
  }

  /// Use the Shuffle power-up: shuffles the board.
  void _useShuffle() {
    if (_processing || _levelEnded) return;
    final saveState = widget.saveState;
    if (saveState == null || !saveState.usePowerUp(powerUpShuffle)) return;
    _deadlockDetector.shuffleBoard(_board);
    setState(() {});
    widget.onPowerUpUsed?.call();
  }

  /// Use the Color Bomb power-up: shows a dialog to pick a color, then
  /// removes all gems of that color and runs cascade.
  void _useColorBomb() {
    if (_processing || _levelEnded) return;
    final saveState = widget.saveState;
    if (saveState == null || saveState.powerUpCount(powerUpColorBomb) <= 0) {
      return;
    }

    // Collect the gem types present on the board.
    final typesOnBoard = <GemType>{};
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final gem = _board.gemAt(Position(r, c));
        if (gem != null) typesOnBoard.add(gem.type);
      }
    }

    if (typesOnBoard.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choose a color to destroy',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: typesOnBoard.map((gemType) {
            return GestureDetector(
              key: Key('color_bomb_${gemType.name}'),
              onTap: () {
                Navigator.of(ctx).pop();
                _executeColorBomb(gemType);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(
                  gemType.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Execute the color bomb: remove all gems of [targetType] and cascade.
  Future<void> _executeColorBomb(GemType targetType) async {
    final saveState = widget.saveState;
    if (saveState == null || !saveState.usePowerUp(powerUpColorBomb)) return;
    widget.onPowerUpUsed?.call();

    setState(() => _processing = true);

    // Find all positions with the target gem type.
    final positions = <Position>{};
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final pos = Position(r, c);
        final gem = _board.gemAt(pos);
        if (gem != null && gem.type == targetType) {
          positions.add(pos);
        }
      }
    }

    if (positions.isNotEmpty) {
      // Track gems collected by type.
      _gemsCollectedByType[targetType] =
          (_gemsCollectedByType[targetType] ?? 0) + positions.length;

      // Animate the removal.
      setState(() => _matchedPositions = positions);
      await _animController.animateMatch(positions);

      // Remove gems.
      _board.removeGems(positions);
      setState(() => _matchedPositions = {});

      // Apply gravity + refill.
      _gravityHandler.applyGravity(_board);
      _gravityHandler.refill(_board);
      setState(() {});

      // Run cascade for any new matches created.
      await _runCascadeLoop();
    }

    // Check for deadlock.
    if (_deadlockDetector.isDeadlocked(_board)) {
      await Future.delayed(const Duration(milliseconds: 300));
      _deadlockDetector.shuffleBoard(_board);
      setState(() {});
    }

    // Check level end conditions.
    if (_isLevelMode && !_levelEnded) {
      _checkLevelEnd();
    }

    // Check free mode game over (out of moves).
    if (!_isLevelMode && !_levelEnded && _movesRemaining <= 0) {
      _endFreeMode();
    }

    setState(() => _processing = false);
  }

  // ---- Accessors for testing ----
  @visibleForTesting
  int get score => _score;
  @visibleForTesting
  int get movesRemaining => _movesRemaining;
  @visibleForTesting
  int get coinsEarnedThisLevel => _coinsEarnedThisLevel;
  @visibleForTesting
  int get movesUsed => _movesUsed;
  @visibleForTesting
  int get obstaclesDestroyed => _obstaclesDestroyed;
  @visibleForTesting
  int get gemsCollected => _gemsCollected;
  @visibleForTesting
  Map<GemType, int> get gemsCollectedByType => _gemsCollectedByType;
  @visibleForTesting
  bool get levelEnded => _levelEnded;
  @visibleForTesting
  ObstacleManager get obstacleManager => _obstacleManager;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bgPath = BackgroundManager.getBackgroundPath(
      widget.levelNumber ?? 1,
      landscape: isLandscape,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image layer
          Image.asset(
            bgPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Semi-transparent overlay for readability
          Container(color: const Color(0xAA1a1a2e)),
          // Original UI
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    if (_isLevelMode && _levelConfig!.isBossLevel)
                      _buildBossHud()
                    else if (_isLevelMode)
                      _buildObjectiveHud(),
                    Expanded(child: _buildBoard()),
                    _buildFooter(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Coin display row (if coinBalance is provided)
          if (widget.coinBalance != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '\uD83E\uDE99', // 🪙
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.coinBalance}',
                    key: const Key('coin_balance'),
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_coinsEarnedThisLevel > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(+$_coinsEarnedThisLevel)',
                      key: const Key('coins_earned_this_level'),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Main header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_levelConfig?.isBossLevel == true) ? 'DAMAGE' : 'SCORE',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$_score',
                    style: TextStyle(
                      color: (_levelConfig?.isBossLevel == true)
                          ? Colors.orangeAccent
                          : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Level indicator (if in level mode)
              if (_isLevelMode)
                Column(
                  children: [
                    Text(
                      'LEVEL ${_levelConfig!.levelNumber}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              // Moves column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isFarmingMode ? 'FARMING' : 'MOVES',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: _isFarmingMode
                            ? Colors.amberAccent
                            : _movesRemaining <= 5
                                ? Colors.redAccent
                                : Colors.lightBlueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFarmingMode
                            ? '\u221E'
                            : '$_movesRemaining/${widget.saveState?.maxBonusMoves ?? 60}',
                        style: TextStyle(
                          color: _isFarmingMode
                              ? Colors.amberAccent
                              : _movesRemaining <= 5
                                  ? Colors.redAccent
                                  : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBossHud() {
    final config = _levelConfig!;
    final bossInfo = config.bossInfo!;
    final remainingHp = (bossInfo.hp - _score).clamp(0, bossInfo.hp);
    final hpFraction = remainingHp / bossInfo.hp;

    // HP bar color: green > 50%, yellow 25-50%, red < 25%.
    final Color hpColor;
    if (hpFraction > 0.5) {
      hpColor = Colors.greenAccent;
    } else if (hpFraction > 0.25) {
      hpColor = Colors.amberAccent;
    } else {
      hpColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hpFraction <= 0
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : Colors.redAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Boss emoji
          Text(
            bossInfo.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 12),
          // Name + HP bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bossInfo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // HP bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: hpFraction.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: hpColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // HP text
                Text(
                  '$remainingHp / ${bossInfo.hp} HP',
                  style: TextStyle(
                    color: hpColor.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Damage dealt indicator
          Column(
            children: [
              const Text(
                '\u2694\uFE0F', // ⚔️
                style: TextStyle(fontSize: 18),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'DMG',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveHud() {
    final objective = _levelConfig!.objective;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildObjectiveChip(objective),
        ],
      ),
    );
  }

  Widget _buildObjectiveChip(LevelObjective objective) {
    switch (objective.type) {
      case LevelObjectiveType.score:
        final progress = _score / objective.targetScore;
        return _objectiveContainer(
          icon: '\uD83C\uDFAF', // 🎯
          label: 'Score: $_score / ${objective.targetScore}',
          progress: progress.clamp(0.0, 1.0),
        );

      case LevelObjectiveType.collectGems:
        final entries = objective.targetGems.entries.toList();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: entries.map((e) {
            final collected = _gemsCollectedByType[e.key] ?? 0;
            final target = e.value;
            final progress = collected / target;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _objectiveContainer(
                icon: e.key.emoji,
                label: '$collected/$target',
                progress: progress.clamp(0.0, 1.0),
              ),
            );
          }).toList(),
        );

      case LevelObjectiveType.destroyObstacles:
        final progress =
            _obstaclesDestroyed / objective.targetObstacles;
        return _objectiveContainer(
          icon: '\uD83D\uDCA5', // 💥
          label:
              'Destroy: $_obstaclesDestroyed / ${objective.targetObstacles}',
          progress: progress.clamp(0.0, 1.0),
        );
    }
  }

  Widget _objectiveContainer({
    required String icon,
    required String label,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress >= 1.0 ? Colors.greenAccent : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: progress >= 1.0 ? Colors.greenAccent : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboOverlay(double boardWidth, double boardHeight) {
    final animValue = _comboAnimController.value;
    // Float upward as the animation progresses.
    final yOffset = (1.0 - animValue) * 20;
    final comboLeft = _comboX * boardWidth;
    final comboTop = _comboY * boardHeight - yOffset;
    return Positioned(
      left: comboLeft,
      top: comboTop - 20,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: IgnorePointer(
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.5 + 0.5 * animValue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _comboText!,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingRewards(double boardWidth, double boardHeight) {
    // Remove expired rewards.
    _floatingRewards.removeWhere((r) => r.isExpired);
    return _floatingRewards.map((reward) {
      final age = DateTime.now().difference(reward.createdAt).inMilliseconds;
      final opacity = (1.0 - age / 1500.0).clamp(0.0, 1.0);
      final yOffset = age * 0.03; // Float upward
      return Positioned(
        left: reward.x * boardWidth - 30,
        top: reward.y * boardHeight - yOffset,
        width: 60,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Text(
              reward.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: _cols / _rows,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardWidth = constraints.maxWidth;
                final boardHeight = constraints.maxHeight;
                final cellW = boardWidth / _cols;
                final cellH = boardHeight / _rows;
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (d) => _onPanStart(d, cellW, cellH),
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ..._buildGridBackground(cellW, cellH),
                      ..._buildObstacleTiles(cellW, cellH),
                      ..._buildGemTiles(cellW, cellH),
                      if (_comboText != null)
                        _buildComboOverlay(boardWidth, boardHeight),
                      ..._buildFloatingRewards(boardWidth, boardHeight),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGridBackground(double cellW, double cellH) {
    final widgets = <Widget>[];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final pos = Position(r, c);
        final isSelected = _selected == pos;
        final isHint = _hintPositions.contains(pos);
        widgets.add(
          Positioned(
            left: c * cellW,
            top: r * cellH,
            width: cellW,
            height: cellH,
            child: GestureDetector(
              onTap: () => _onTileTap(r, c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white24
                      : isHint
                          ? Colors.amber.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : isHint
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Renders obstacle overlays on the board.
  List<Widget> _buildObstacleTiles(double cellW, double cellH) {
    final widgets = <Widget>[];
    for (final entry in _obstacleManager.obstacles.entries) {
      final pos = entry.key;
      final obs = entry.value;
      if (obs.isDestroyed) continue;
      if (pos.row < 0 || pos.row >= _rows || pos.col < 0 || pos.col >= _cols) {
        continue;
      }

      widgets.add(
        Positioned(
          left: pos.col * cellW,
          top: pos.row * cellH,
          width: cellW,
          height: cellH,
          child: IgnorePointer(
            child: Center(
              child: Text(
                _obstacleEmoji(obs.type),
                style: TextStyle(
                  fontSize: cellW * 0.35,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildGemTiles(double cellW, double cellH) {
    final widgets = <Widget>[];
    final currentAnims = _animController.currentAnimations;
    final phase = _animController.currentPhase;

    final animByFrom = <Position, GemAnimation>{};
    final animByTo = <Position, GemAnimation>{};
    for (final anim in currentAnims) {
      animByFrom[anim.from] = anim;
      animByTo[anim.to] = anim;
    }

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final pos = Position(r, c);
        final gem = _board.gemAt(pos);
        if (gem == null) continue;

        // Skip cells fully blocked by stone.
        if (_obstacleManager.blocksCell(pos)) continue;

        if (_matchedPositions.contains(pos) &&
            phase == BoardAnimationType.match) {
          final anim = animByFrom[pos];
          if (anim != null) {
            widgets.add(_buildAnimatedGem(
              gem,
              pos,
              cellW,
              cellH,
              scale: anim.scale,
              opacity: anim.opacity,
            ));
          }
          continue;
        }

        double left = c * cellW;
        double top = r * cellH;
        double scale = 1.0;
        double opacity = 1.0;

        if (phase == BoardAnimationType.swap ||
            phase == BoardAnimationType.swapFailed) {
          final anim = animByFrom[pos];
          if (anim != null) {
            final offset = anim.interpolatedOffset(cellW);
            left = offset.dx;
            top = offset.dy;
          }
        } else if (phase == BoardAnimationType.fall) {
          final anim = animByTo[pos];
          if (anim != null) {
            final fromLeft = anim.from.col * cellW;
            final fromTop = anim.from.row * cellH;
            final toLeft = anim.to.col * cellW;
            final toTop = anim.to.row * cellH;
            left = fromLeft + (toLeft - fromLeft) * anim.progress;
            top = fromTop + (toTop - fromTop) * anim.progress;
          }
        } else if (phase == BoardAnimationType.spawn) {
          final anim = animByTo[pos];
          if (anim != null) {
            opacity = anim.opacity;
            final fromTop = -1 * cellH;
            final toTop = r * cellH;
            top = fromTop + (toTop - fromTop) * anim.progress;
          }
        }

        widgets.add(_buildPositionedGem(
          gem,
          left,
          top,
          cellW,
          cellH,
          scale: scale,
          opacity: opacity,
        ));
      }
    }
    return widgets;
  }

  Widget _buildAnimatedGem(
    Gem gem,
    Position pos,
    double cellW,
    double cellH, {
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    return Positioned(
      left: pos.col * cellW,
      top: pos.row * cellH,
      width: cellW,
      height: cellH,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Center(
            child: Text(
              gem.type.emoji,
              style: TextStyle(fontSize: cellW * 0.55),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionedGem(
    Gem gem,
    double left,
    double top,
    double cellW,
    double cellH, {
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: cellW,
      height: cellH,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    gem.type.emoji,
                    style: TextStyle(fontSize: cellW * 0.55),
                  ),
                  if (gem.special != SpecialType.none)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Text(
                        _specialIndicator(gem.special),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Power-up bar (only shown if saveState is provided)
          if (widget.saveState != null) _buildPowerUpBar(),
          if (widget.saveState != null) const SizedBox(height: 8),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(
                icon: Icons.lightbulb_outline,
                label: 'Hint',
                onTap: _processing || _levelEnded ? null : _showHint,
              ),
              _buildButton(
                icon: Icons.refresh,
                label: _isLevelMode ? 'Restart' : 'New Game',
                onTap: _processing
                    ? null
                    : () => setState(() => _initBoard()),
              ),
              _buildButton(
                icon: Icons.exit_to_app,
                label: 'Exit',
                onTap: _processing ? null : _confirmExit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Spiel verlassen?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Spiel verlassen? Deine Zuege bleiben erhalten.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            key: const Key('exit_confirm_btn'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verlassen',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      widget.onPowerUpUsed?.call(); // Persist state changes.
      Navigator.pop(context);
    }
  }

  Widget _buildPowerUpBar() {
    final extraMovesCount = _powerUpCount(powerUpExtraMoves);
    final megaMovesCount = _powerUpCount(powerUpMegaMoves);
    final shuffleCount = _powerUpCount(powerUpShuffle);
    final colorBombCount = _powerUpCount(powerUpColorBomb);
    final disabled = _processing || _levelEnded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPowerUpButton(
          key: const Key('powerup_extra_moves_btn'),
          emoji: '\uD83D\uDC8A20',
          count: extraMovesCount,
          onTap: disabled || extraMovesCount <= 0 ? null : _useExtraMoves,
        ),
        _buildPowerUpButton(
          key: const Key('powerup_mega_moves_btn'),
          emoji: '\uD83D\uDC8A60',
          count: megaMovesCount,
          onTap: disabled || megaMovesCount <= 0 ? null : _useMegaMoves,
        ),
        _buildPowerUpButton(
          key: const Key('powerup_shuffle_btn'),
          emoji: '\uD83D\uDD00',
          count: shuffleCount,
          onTap: disabled || shuffleCount <= 0 ? null : _useShuffle,
        ),
        _buildPowerUpButton(
          key: const Key('powerup_color_bomb_btn'),
          emoji: '\uD83D\uDCA3',
          count: colorBombCount,
          onTap: disabled || colorBombCount <= 0 ? null : _useColorBomb,
        ),
      ],
    );
  }

  Widget _buildPowerUpButton({
    required Key key,
    required String emoji,
    required int count,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled ? Colors.white10 : Colors.amberAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 18,
                color: isDisabled ? Colors.white38 : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'x$count',
              style: TextStyle(
                color: isDisabled ? Colors.white24 : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

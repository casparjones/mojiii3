import 'dart:math';

import '../models/board.dart';
import '../models/gem_type.dart';
import '../models/position.dart';
import 'combo_bomb_dropper.dart';
import 'gravity_handler.dart';
import 'match_detector.dart';
import 'special_gem_handler.dart';

/// Result of a single cascade step.
class CascadeStep {
  final List<Match> matches;
  final int cascadeLevel;

  const CascadeStep({
    required this.matches,
    required this.cascadeLevel,
  });

  /// Total number of gems cleared in this step.
  int get gemsCleared {
    final positions = <Position>{};
    for (final match in matches) {
      positions.addAll(match.positions);
    }
    return positions.length;
  }

  /// Score multiplier for this cascade level.
  double get multiplier => 1.0 + (cascadeLevel - 1) * 0.5;
}

/// Result of a full cascade resolution.
class CascadeResult {
  final List<CascadeStep> steps;

  const CascadeResult({required this.steps});

  /// Total number of cascade steps.
  int get cascadeCount => steps.length;

  /// Total gems cleared across all steps.
  int get totalGemsCleared =>
      steps.fold(0, (sum, step) => sum + step.gemsCleared);

  /// Whether any matches were found.
  bool get hadMatches => steps.isNotEmpty;
}

/// Runs the full cascade loop: detect matches -> remove -> gravity -> refill -> repeat.
class CascadeEngine {
  final MatchDetector _matchDetector;
  final GravityHandler _gravityHandler;
  final SpecialGemHandler _specialGemHandler;
  final ComboBombDropper _comboBombDropper;

  /// Maximum cascade iterations to prevent infinite loops.
  static const int maxCascades = 100;

  CascadeEngine({
    MatchDetector matchDetector = const MatchDetector(),
    GravityHandler? gravityHandler,
    SpecialGemHandler specialGemHandler = const SpecialGemHandler(),
    ComboBombDropper? comboBombDropper,
    int gemTypeCount = 6,
    Random? random,
  })  : _matchDetector = matchDetector,
        _gravityHandler = gravityHandler ??
            GravityHandler(gemTypeCount: gemTypeCount, random: random),
        _specialGemHandler = specialGemHandler,
        _comboBombDropper = comboBombDropper ?? ComboBombDropper(random: random);

  /// Resolves all cascades on the board after a move.
  /// Modifies the board in-place and returns cascade details.
  CascadeResult resolve(Board board) {
    final steps = <CascadeStep>[];
    var cascadeLevel = 0;

    for (var i = 0; i < maxCascades; i++) {
      final matches = _matchDetector.findMatches(board);
      if (matches.isEmpty) break;

      cascadeLevel++;

      steps.add(CascadeStep(
        matches: matches,
        cascadeLevel: cascadeLevel,
      ));

      // Collect matched positions plus any expanded by special gem activation.
      final positions = <Position>{};
      for (final match in matches) {
        positions.addAll(match.positions);
      }

      // Activate special gems caught in the match.
      final expandedPositions = Set<Position>.from(positions);
      for (final pos in positions) {
        final gem = board.gemAt(pos);
        if (gem != null && gem.special != SpecialType.none) {
          expandedPositions.addAll(_specialGemHandler.activate(board, pos));
        }
      }

      board.removeGems(expandedPositions);

      // Apply gravity
      _gravityHandler.applyGravity(board);

      // Find empty positions before refill (for combo bomb placement).
      final emptyPositions = <Position>[];
      for (var c = 0; c < board.cols; c++) {
        for (var r = 0; r < board.rows; r++) {
          if (board.gemAt(Position(r, c)) == null) {
            emptyPositions.add(Position(r, c));
          }
        }
      }

      // Refill
      _gravityHandler.refill(board);

      // Combo bomb drop: chance to spawn a bomb during cascades.
      if (cascadeLevel >= 2 && emptyPositions.isNotEmpty) {
        final bombDrop = _comboBombDropper.tryDrop(
          cascadeLevel: cascadeLevel,
          board: board,
          emptyPositions: emptyPositions,
        );
        if (bombDrop != null) {
          board.setGem(bombDrop.position, bombDrop.gem);
        }
      }
    }

    return CascadeResult(steps: steps);
  }
}

import 'dart:math';

import '../models/gem_type.dart';
import '../models/position.dart';
import '../models/board.dart';

/// Determines whether a combo (cascade) should drop a bomb gem,
/// and which type of bomb to create.
///
/// Drop chances based on cascade level (combo count):
/// - 2x combo: 5% chance for a cross bomb
/// - 3x combo: 15% chance for cross bomb or area bomb (equal weight)
/// - 4x+ combo: 30% chance, higher weight for area bomb (3x3)
class ComboBombDropper {
  final Random _random;

  ComboBombDropper({Random? random}) : _random = random ?? Random();

  /// Attempts to create a bomb gem based on the current cascade level.
  /// Returns null if no bomb should be dropped.
  ///
  /// [cascadeLevel] is the current combo count (1 = first match, 2 = first cascade, etc.)
  /// [board] is used to find a valid spawn position.
  /// [emptyPositions] are positions about to be refilled where a bomb could be placed.
  ComboBombDrop? tryDrop({
    required int cascadeLevel,
    required Board board,
    required List<Position> emptyPositions,
  }) {
    if (cascadeLevel < 2 || emptyPositions.isEmpty) return null;

    final double dropChance;
    switch (cascadeLevel) {
      case 2:
        dropChance = 0.05;
        break;
      case 3:
        dropChance = 0.15;
        break;
      default: // 4+
        dropChance = 0.30;
        break;
    }

    final roll = _random.nextDouble();
    if (roll >= dropChance) return null;

    // Determine bomb type
    final SpecialType bombType;
    if (cascadeLevel == 2) {
      // Only cross bomb at 2x combo
      bombType = SpecialType.crossBomb;
    } else if (cascadeLevel == 3) {
      // Equal chance for cross bomb or area bomb
      bombType = _random.nextBool() ? SpecialType.crossBomb : SpecialType.bomb;
    } else {
      // 4x+: 70% area bomb, 30% cross bomb
      bombType =
          _random.nextDouble() < 0.7 ? SpecialType.bomb : SpecialType.crossBomb;
    }

    // Pick a random empty position for the bomb
    final pos = emptyPositions[_random.nextInt(emptyPositions.length)];

    // Pick a random gem type for the bomb's base color
    final gemType =
        GemType.values[_random.nextInt(GemType.count)];

    return ComboBombDrop(
      position: pos,
      gem: Gem(type: gemType, special: bombType),
    );
  }
}

/// Result of a successful bomb drop from a combo.
class ComboBombDrop {
  final Position position;
  final Gem gem;

  const ComboBombDrop({
    required this.position,
    required this.gem,
  });
}

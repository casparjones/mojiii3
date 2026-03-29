import 'package:flutter/material.dart';

import 'emoji_theme.dart';

/// The basic gem types available on the board.
enum GemType {
  red,
  blue,
  green,
  yellow,
  purple,
  orange;

  /// The number of basic gem types.
  static const int count = 6;

  /// Emoji representation for display, based on the active [EmojiTheme].
  String get emoji => EmojiTheme.active.emojiFor(this);

  /// The default (fruit theme) emoji for this gem type.
  /// Used as fallback when no theme mapping is found.
  String get defaultEmoji {
    switch (this) {
      case GemType.red:
        return '🍎';
      case GemType.blue:
        return '🫐';
      case GemType.green:
        return '🍋';
      case GemType.yellow:
        return '🍊';
      case GemType.purple:
        return '🍇';
      case GemType.orange:
        return '🍓';
    }
  }
}

/// Special gem abilities created by matching patterns.
enum SpecialType {
  none,

  /// Created by matching 4 in a row. Clears an entire row or column.
  stripedHorizontal,
  stripedVertical,

  /// Created by matching in L or T shape. Explodes a 3x3 area.
  bomb,

  /// Cross bomb: clears entire row AND entire column (cross shape).
  /// Dropped by combo chance during cascades.
  crossBomb,

  /// Created by matching 5 in a row. Clears all gems of a chosen color.
  rainbow,
}

/// Represents a single gem on the board.
class Gem {
  final GemType type;
  final SpecialType special;

  const Gem({
    required this.type,
    this.special = SpecialType.none,
  });

  Gem copyWith({
    GemType? type,
    SpecialType? special,
  }) {
    return Gem(
      type: type ?? this.type,
      special: special ?? this.special,
    );
  }

  /// Get the visual definition for this gem's type.
  GemVisualDef get visual => GemVisuals.forType(type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gem &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          special == other.special;

  @override
  int get hashCode => type.hashCode ^ special.hashCode;

  @override
  String toString() {
    if (special == SpecialType.none) return 'Gem($type)';
    return 'Gem($type, $special)';
  }
}

// ---------------------------------------------------------------------------
// Visual definitions for the diamond sprite system (20+ variants)
// ---------------------------------------------------------------------------

/// Rarity levels for gems, affecting score multipliers and visual effects.
enum GemRarity {
  common(1.0),
  uncommon(1.5),
  rare(2.0),
  epic(3.0),
  legendary(5.0);

  final double scoreMultiplier;
  const GemRarity(this.scoreMultiplier);
}

/// Cut style affects the shape rendered by the CustomPainter.
enum GemCut {
  round,
  princess,
  emerald,
  oval,
  marquise,
  pear,
  heart,
  cushion,
  asscher,
  radiant,
}

/// Shape category for the gem outline.
enum GemShape {
  diamond,
  circle,
  square,
  hexagon,
  triangle,
  star,
  teardrop,
}

/// Visual definition for a gem variant.
class GemVisualDef {
  final int id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glintColor;
  final GemRarity rarity;
  final GemCut cut;
  final GemShape shape;
  final int facetCount;
  final double shimmerSpeed;

  const GemVisualDef({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glintColor,
    required this.rarity,
    required this.cut,
    required this.shape,
    this.facetCount = 6,
    this.shimmerSpeed = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GemVisualDef && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GemVisualDef($id: $name)';
}

/// All visual definitions (24 variants, 4 per GemType base color).
/// Each basic GemType maps to multiple visual variants of increasing rarity.
class GemVisuals {
  GemVisuals._();

  // === RED variants ===
  static const rubyRed = GemVisualDef(
    id: 0, name: 'Ruby Red',
    primaryColor: Color(0xFFE53935), secondaryColor: Color(0xFFFF7043),
    glintColor: Color(0xFFFFCDD2),
    rarity: GemRarity.common, cut: GemCut.round, shape: GemShape.diamond,
  );
  static const garnet = GemVisualDef(
    id: 1, name: 'Garnet',
    primaryColor: Color(0xFFC62828), secondaryColor: Color(0xFFD32F2F),
    glintColor: Color(0xFFEF9A9A),
    rarity: GemRarity.uncommon, cut: GemCut.pear, shape: GemShape.teardrop,
    facetCount: 8,
  );
  static const bloodDiamond = GemVisualDef(
    id: 2, name: 'Blood Diamond',
    primaryColor: Color(0xFFB71C1C), secondaryColor: Color(0xFFE57373),
    glintColor: Color(0xFFFFCDD2),
    rarity: GemRarity.rare, cut: GemCut.princess, shape: GemShape.triangle,
    facetCount: 10, shimmerSpeed: 1.5,
  );
  static const cosmicRuby = GemVisualDef(
    id: 3, name: 'Cosmic Ruby',
    primaryColor: Color(0xFFD50000), secondaryColor: Color(0xFFFF1744),
    glintColor: Color(0xFFFF8A80),
    rarity: GemRarity.legendary, cut: GemCut.radiant, shape: GemShape.star,
    facetCount: 16, shimmerSpeed: 3.0,
  );

  // === BLUE variants ===
  static const sapphireBlue = GemVisualDef(
    id: 4, name: 'Sapphire Blue',
    primaryColor: Color(0xFF1E88E5), secondaryColor: Color(0xFF42A5F5),
    glintColor: Color(0xFFBBDEFB),
    rarity: GemRarity.common, cut: GemCut.princess, shape: GemShape.diamond,
  );
  static const aquamarine = GemVisualDef(
    id: 5, name: 'Aquamarine',
    primaryColor: Color(0xFF00BCD4), secondaryColor: Color(0xFF26C6DA),
    glintColor: Color(0xFFB2EBF2),
    rarity: GemRarity.uncommon, cut: GemCut.marquise, shape: GemShape.hexagon,
    facetCount: 8,
  );
  static const starSapphire = GemVisualDef(
    id: 6, name: 'Star Sapphire',
    primaryColor: Color(0xFF283593), secondaryColor: Color(0xFF3F51B5),
    glintColor: Color(0xFFC5CAE9),
    rarity: GemRarity.rare, cut: GemCut.round, shape: GemShape.star,
    facetCount: 10, shimmerSpeed: 1.5,
  );
  static const voidGem = GemVisualDef(
    id: 7, name: 'Void Gem',
    primaryColor: Color(0xFF1A1A2E), secondaryColor: Color(0xFF16213E),
    glintColor: Color(0xFF7C4DFF),
    rarity: GemRarity.legendary, cut: GemCut.asscher, shape: GemShape.hexagon,
    facetCount: 16, shimmerSpeed: 3.0,
  );

  // === GREEN variants ===
  static const emeraldGreen = GemVisualDef(
    id: 8, name: 'Emerald Green',
    primaryColor: Color(0xFF43A047), secondaryColor: Color(0xFF66BB6A),
    glintColor: Color(0xFFC8E6C9),
    rarity: GemRarity.common, cut: GemCut.emerald, shape: GemShape.square,
  );
  static const peridot = GemVisualDef(
    id: 9, name: 'Peridot',
    primaryColor: Color(0xFF9CCC65), secondaryColor: Color(0xFFC5E1A5),
    glintColor: Color(0xFFF1F8E9),
    rarity: GemRarity.uncommon, cut: GemCut.oval, shape: GemShape.hexagon,
    facetCount: 8,
  );
  static const alexandrite = GemVisualDef(
    id: 10, name: 'Alexandrite',
    primaryColor: Color(0xFF00695C), secondaryColor: Color(0xFF7B1FA2),
    glintColor: Color(0xFFE1BEE7),
    rarity: GemRarity.epic, cut: GemCut.marquise, shape: GemShape.hexagon,
    facetCount: 12, shimmerSpeed: 2.0,
  );
  static const jadeDragon = GemVisualDef(
    id: 11, name: 'Jade Dragon',
    primaryColor: Color(0xFF2E7D32), secondaryColor: Color(0xFF1B5E20),
    glintColor: Color(0xFFA5D6A7),
    rarity: GemRarity.legendary, cut: GemCut.cushion, shape: GemShape.diamond,
    facetCount: 16, shimmerSpeed: 3.0,
  );

  // === YELLOW variants ===
  static const topazYellow = GemVisualDef(
    id: 12, name: 'Topaz Yellow',
    primaryColor: Color(0xFFFDD835), secondaryColor: Color(0xFFFFEE58),
    glintColor: Color(0xFFFFF9C4),
    rarity: GemRarity.common, cut: GemCut.oval, shape: GemShape.circle,
  );
  static const citrineGold = GemVisualDef(
    id: 13, name: 'Citrine Gold',
    primaryColor: Color(0xFFFFB300), secondaryColor: Color(0xFFFFD54F),
    glintColor: Color(0xFFFFF8E1),
    rarity: GemRarity.uncommon, cut: GemCut.cushion, shape: GemShape.diamond,
    facetCount: 8,
  );
  static const fireOpal = GemVisualDef(
    id: 14, name: 'Fire Opal',
    primaryColor: Color(0xFFFF6F00), secondaryColor: Color(0xFFFFCA28),
    glintColor: Color(0xFFFFECB3),
    rarity: GemRarity.rare, cut: GemCut.radiant, shape: GemShape.diamond,
    facetCount: 10, shimmerSpeed: 1.5,
  );
  static const sunstone = GemVisualDef(
    id: 15, name: 'Sunstone',
    primaryColor: Color(0xFFFF8F00), secondaryColor: Color(0xFFFFE082),
    glintColor: Color(0xFFFFFFFF),
    rarity: GemRarity.epic, cut: GemCut.round, shape: GemShape.star,
    facetCount: 12, shimmerSpeed: 2.5,
  );

  // === PURPLE variants ===
  static const amethystPurple = GemVisualDef(
    id: 16, name: 'Amethyst Purple',
    primaryColor: Color(0xFF8E24AA), secondaryColor: Color(0xFFAB47BC),
    glintColor: Color(0xFFE1BEE7),
    rarity: GemRarity.common, cut: GemCut.cushion, shape: GemShape.diamond,
  );
  static const tanzanite = GemVisualDef(
    id: 17, name: 'Tanzanite',
    primaryColor: Color(0xFF5C6BC0), secondaryColor: Color(0xFF7986CB),
    glintColor: Color(0xFFC5CAE9),
    rarity: GemRarity.uncommon, cut: GemCut.princess, shape: GemShape.diamond,
    facetCount: 8,
  );
  static const morganite = GemVisualDef(
    id: 18, name: 'Morganite',
    primaryColor: Color(0xFFF48FB1), secondaryColor: Color(0xFFF8BBD0),
    glintColor: Color(0xFFFCE4EC),
    rarity: GemRarity.rare, cut: GemCut.heart, shape: GemShape.diamond,
    facetCount: 10, shimmerSpeed: 1.5,
  );
  static const prismaticDiamond = GemVisualDef(
    id: 19, name: 'Prismatic Diamond',
    primaryColor: Color(0xFFE040FB), secondaryColor: Color(0xFFEA80FC),
    glintColor: Color(0xFFFFFFFF),
    rarity: GemRarity.legendary, cut: GemCut.round, shape: GemShape.star,
    facetCount: 16, shimmerSpeed: 3.0,
  );

  // === ORANGE variants ===
  static const citrineOrange = GemVisualDef(
    id: 20, name: 'Citrine Orange',
    primaryColor: Color(0xFFF4511E), secondaryColor: Color(0xFFFF7043),
    glintColor: Color(0xFFFFCCBC),
    rarity: GemRarity.common, cut: GemCut.round, shape: GemShape.circle,
  );
  static const padparadscha = GemVisualDef(
    id: 21, name: 'Padparadscha',
    primaryColor: Color(0xFFFF8A65), secondaryColor: Color(0xFFF48FB1),
    glintColor: Color(0xFFFCE4EC),
    rarity: GemRarity.uncommon, cut: GemCut.heart, shape: GemShape.diamond,
    facetCount: 8,
  );
  static const blackOpal = GemVisualDef(
    id: 22, name: 'Black Opal',
    primaryColor: Color(0xFF263238), secondaryColor: Color(0xFF00BFA5),
    glintColor: Color(0xFF64FFDA),
    rarity: GemRarity.epic, cut: GemCut.radiant, shape: GemShape.diamond,
    facetCount: 12, shimmerSpeed: 2.0,
  );
  static const moonstone = GemVisualDef(
    id: 23, name: 'Moonstone',
    primaryColor: Color(0xFFB0BEC5), secondaryColor: Color(0xFFE0E0E0),
    glintColor: Color(0xFFFFFFFF),
    rarity: GemRarity.rare, cut: GemCut.oval, shape: GemShape.circle,
    facetCount: 10, shimmerSpeed: 2.0,
  );

  /// All 24 visual definitions.
  static const List<GemVisualDef> all = [
    rubyRed, garnet, bloodDiamond, cosmicRuby,
    sapphireBlue, aquamarine, starSapphire, voidGem,
    emeraldGreen, peridot, alexandrite, jadeDragon,
    topazYellow, citrineGold, fireOpal, sunstone,
    amethystPurple, tanzanite, morganite, prismaticDiamond,
    citrineOrange, padparadscha, moonstone, blackOpal,
  ];

  /// Mapping from basic GemType to its visual variants (4 per type).
  static const Map<GemType, List<GemVisualDef>> _variants = {
    GemType.red:    [rubyRed, garnet, bloodDiamond, cosmicRuby],
    GemType.blue:   [sapphireBlue, aquamarine, starSapphire, voidGem],
    GemType.green:  [emeraldGreen, peridot, alexandrite, jadeDragon],
    GemType.yellow: [topazYellow, citrineGold, fireOpal, sunstone],
    GemType.purple: [amethystPurple, tanzanite, morganite, prismaticDiamond],
    GemType.orange: [citrineOrange, padparadscha, moonstone, blackOpal],
  };

  /// Get all visual variants for a given basic GemType.
  static List<GemVisualDef> variantsFor(GemType type) =>
      _variants[type] ?? const [];

  /// Get the default (common) visual definition for a GemType.
  static GemVisualDef forType(GemType type) => variantsFor(type).first;

  /// Get a visual variant by rarity for a given GemType.
  static GemVisualDef? variantByRarity(GemType type, GemRarity rarity) {
    final variants = variantsFor(type);
    for (final v in variants) {
      if (v.rarity == rarity) return v;
    }
    return null;
  }

  /// Get visual definition by its numeric id.
  static GemVisualDef byId(int id) => all.firstWhere((v) => v.id == id);

  /// Filter all visuals by rarity.
  static List<GemVisualDef> byRarity(GemRarity rarity) =>
      all.where((v) => v.rarity == rarity).toList();

  /// Total number of defined visual variants.
  static int get count => all.length;
}

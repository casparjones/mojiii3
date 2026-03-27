import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/gem_type.dart';

void main() {
  group('GemType', () {
    test('has 6 basic types', () {
      expect(GemType.values.length, 6);
      expect(GemType.count, 6);
    });
  });

  group('SpecialType', () {
    test('has correct values', () {
      expect(SpecialType.values, contains(SpecialType.none));
      expect(SpecialType.values, contains(SpecialType.bomb));
      expect(SpecialType.values, contains(SpecialType.rainbow));
      expect(SpecialType.values, contains(SpecialType.stripedHorizontal));
      expect(SpecialType.values, contains(SpecialType.stripedVertical));
    });
  });

  group('Gem', () {
    test('creates with default special type none', () {
      const gem = Gem(type: GemType.red);
      expect(gem.type, GemType.red);
      expect(gem.special, SpecialType.none);
    });

    test('creates with special type', () {
      const gem = Gem(type: GemType.blue, special: SpecialType.bomb);
      expect(gem.type, GemType.blue);
      expect(gem.special, SpecialType.bomb);
    });

    test('equality works correctly', () {
      const a = Gem(type: GemType.red);
      const b = Gem(type: GemType.red);
      const c = Gem(type: GemType.blue);
      const d = Gem(type: GemType.red, special: SpecialType.bomb);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('copyWith works correctly', () {
      const gem = Gem(type: GemType.red);
      final copy = gem.copyWith(special: SpecialType.bomb);
      expect(copy.type, GemType.red);
      expect(copy.special, SpecialType.bomb);

      final copy2 = gem.copyWith(type: GemType.green);
      expect(copy2.type, GemType.green);
      expect(copy2.special, SpecialType.none);
    });

    test('toString works', () {
      const gem = Gem(type: GemType.red);
      expect(gem.toString(), 'Gem(GemType.red)');

      const special = Gem(type: GemType.red, special: SpecialType.bomb);
      expect(special.toString(), 'Gem(GemType.red, SpecialType.bomb)');
    });

    test('visual returns correct GemVisualDef', () {
      const gem = Gem(type: GemType.red);
      expect(gem.visual, equals(GemVisuals.rubyRed));
      expect(gem.visual.name, 'Ruby Red');
    });
  });

  group('GemRarity', () {
    test('has correct score multipliers', () {
      expect(GemRarity.common.scoreMultiplier, 1.0);
      expect(GemRarity.uncommon.scoreMultiplier, 1.5);
      expect(GemRarity.rare.scoreMultiplier, 2.0);
      expect(GemRarity.epic.scoreMultiplier, 3.0);
      expect(GemRarity.legendary.scoreMultiplier, 5.0);
    });

    test('has 5 rarity levels', () {
      expect(GemRarity.values.length, 5);
    });
  });

  group('GemCut', () {
    test('has 10 cut styles', () {
      expect(GemCut.values.length, 10);
    });
  });

  group('GemShape', () {
    test('has 7 shapes', () {
      expect(GemShape.values.length, 7);
    });
  });

  group('GemVisualDef', () {
    test('equality based on id', () {
      expect(GemVisuals.rubyRed, equals(GemVisuals.rubyRed));
      expect(GemVisuals.rubyRed, isNot(equals(GemVisuals.garnet)));
    });

    test('toString contains name', () {
      expect(GemVisuals.rubyRed.toString(), contains('Ruby Red'));
    });

    test('has correct default facetCount', () {
      expect(GemVisuals.rubyRed.facetCount, 6);
    });

    test('has correct default shimmerSpeed', () {
      expect(GemVisuals.rubyRed.shimmerSpeed, 1.0);
    });

    test('custom facetCount and shimmerSpeed', () {
      expect(GemVisuals.garnet.facetCount, 8);
      expect(GemVisuals.cosmicRuby.shimmerSpeed, 3.0);
    });
  });

  group('GemVisuals', () {
    test('has 24 total visual definitions', () {
      expect(GemVisuals.count, 24);
      expect(GemVisuals.all.length, 24);
    });

    test('all ids are unique', () {
      final ids = GemVisuals.all.map((v) => v.id).toSet();
      expect(ids.length, GemVisuals.count);
    });

    test('all names are unique', () {
      final names = GemVisuals.all.map((v) => v.name).toSet();
      expect(names.length, GemVisuals.count);
    });

    test('each GemType has 4 variants', () {
      for (final type in GemType.values) {
        expect(GemVisuals.variantsFor(type).length, 4,
            reason: '${type.name} should have 4 variants');
      }
    });

    test('forType returns common variant', () {
      for (final type in GemType.values) {
        final visual = GemVisuals.forType(type);
        expect(visual.rarity, GemRarity.common,
            reason: '${type.name} default should be common');
      }
    });

    test('variantByRarity returns correct variant', () {
      final rare = GemVisuals.variantByRarity(GemType.red, GemRarity.rare);
      expect(rare, isNotNull);
      expect(rare!.name, 'Blood Diamond');
    });

    test('variantByRarity returns null for missing rarity', () {
      // Red has no epic variant
      final epic = GemVisuals.variantByRarity(GemType.red, GemRarity.epic);
      expect(epic, isNull);
    });

    test('byId returns correct visual', () {
      final v = GemVisuals.byId(0);
      expect(v, equals(GemVisuals.rubyRed));
    });

    test('byRarity returns correct count', () {
      // 6 common (one per GemType)
      expect(GemVisuals.byRarity(GemRarity.common).length, 6);
      // 6 uncommon (one per GemType)
      expect(GemVisuals.byRarity(GemRarity.uncommon).length, 6);
      // 5 rare (red, blue, yellow, purple, orange)
      expect(GemVisuals.byRarity(GemRarity.rare).length, 5);
      // 3 epic (green, yellow, orange)
      expect(GemVisuals.byRarity(GemRarity.epic).length, 3);
      // 4 legendary (red, blue, green, purple)
      expect(GemVisuals.byRarity(GemRarity.legendary).length, 4);
    });

    test('byRarity covers all visuals', () {
      int total = 0;
      for (final rarity in GemRarity.values) {
        total += GemVisuals.byRarity(rarity).length;
      }
      expect(total, 24);
    });

    test('each variant has valid colors', () {
      for (final v in GemVisuals.all) {
        expect(v.primaryColor, isNotNull);
        expect(v.secondaryColor, isNotNull);
        expect(v.glintColor, isNotNull);
      }
    });

    test('facetCount increases with rarity', () {
      // Common defaults to 6, uncommon 8, rare 10, etc.
      for (final type in GemType.values) {
        final variants = GemVisuals.variantsFor(type);
        for (int i = 1; i < variants.length; i++) {
          expect(variants[i].facetCount, greaterThanOrEqualTo(variants[i - 1].facetCount),
              reason: '${type.name} variant ${variants[i].name} facetCount should >= previous');
        }
      }
    });

    test('red variants have correct names', () {
      final names = GemVisuals.variantsFor(GemType.red).map((v) => v.name).toList();
      expect(names, ['Ruby Red', 'Garnet', 'Blood Diamond', 'Cosmic Ruby']);
    });

    test('blue variants have correct names', () {
      final names = GemVisuals.variantsFor(GemType.blue).map((v) => v.name).toList();
      expect(names, ['Sapphire Blue', 'Aquamarine', 'Star Sapphire', 'Void Gem']);
    });
  });
}

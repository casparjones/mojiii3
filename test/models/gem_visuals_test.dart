import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/gem_type.dart';

void main() {
  group('GemType emoji mapping', () {
    test('all gem types have emoji representation', () {
      for (final type in GemType.values) {
        expect(type.emoji.isNotEmpty, isTrue,
            reason: '$type should have an emoji');
      }
    });

    test('all emojis are unique', () {
      final emojis = GemType.values.map((t) => t.emoji).toSet();
      expect(emojis.length, GemType.values.length);
    });

    test('specific emoji mappings are correct', () {
      expect(GemType.red.emoji, '\u{1F34E}'); // apple
      expect(GemType.blue.emoji, '\u{1FAD0}'); // blueberries
      expect(GemType.green.emoji, '\u{1F34B}'); // lemon
      expect(GemType.yellow.emoji, '\u{1F34A}'); // orange
      expect(GemType.purple.emoji, '\u{1F347}'); // grapes
      expect(GemType.orange.emoji, '\u{1F353}'); // strawberry
    });
  });

  group('GemVisuals', () {
    test('has 24 visual definitions', () {
      expect(GemVisuals.count, 24);
      expect(GemVisuals.all.length, 24);
    });

    test('all IDs are unique', () {
      final ids = GemVisuals.all.map((v) => v.id).toSet();
      expect(ids.length, 24);
    });

    test('all names are unique', () {
      final names = GemVisuals.all.map((v) => v.name).toSet();
      expect(names.length, 24);
    });

    test('forType returns common variant for each GemType', () {
      for (final type in GemType.values) {
        final visual = GemVisuals.forType(type);
        expect(visual.rarity, GemRarity.common,
            reason: 'Default visual for $type should be common');
      }
    });

    test('variantsFor returns 4 variants per GemType', () {
      for (final type in GemType.values) {
        final variants = GemVisuals.variantsFor(type);
        expect(variants.length, 4,
            reason: '$type should have 4 visual variants');
      }
    });

    test('byId returns correct visual', () {
      final visual = GemVisuals.byId(0);
      expect(visual.name, 'Ruby Red');
      expect(visual.rarity, GemRarity.common);

      final visual7 = GemVisuals.byId(7);
      expect(visual7.name, 'Void Gem');
      expect(visual7.rarity, GemRarity.legendary);
    });

    test('byId throws for invalid id', () {
      expect(() => GemVisuals.byId(99), throwsStateError);
    });

    test('byRarity filters correctly', () {
      final commons = GemVisuals.byRarity(GemRarity.common);
      expect(commons.length, 6); // one per GemType
      for (final v in commons) {
        expect(v.rarity, GemRarity.common);
      }

      final legendaries = GemVisuals.byRarity(GemRarity.legendary);
      expect(legendaries.length, greaterThanOrEqualTo(1));
      for (final v in legendaries) {
        expect(v.rarity, GemRarity.legendary);
      }
    });

    test('variantByRarity returns correct variant', () {
      final ruby = GemVisuals.variantByRarity(GemType.red, GemRarity.common);
      expect(ruby, isNotNull);
      expect(ruby!.name, 'Ruby Red');

      final cosmic =
          GemVisuals.variantByRarity(GemType.red, GemRarity.legendary);
      expect(cosmic, isNotNull);
      expect(cosmic!.name, 'Cosmic Ruby');
    });

    test('variantByRarity returns null for missing rarity', () {
      // Red has no epic rarity variant
      final result = GemVisuals.variantByRarity(GemType.red, GemRarity.epic);
      expect(result, isNull);
    });

    test('GemRarity score multipliers are increasing', () {
      expect(GemRarity.common.scoreMultiplier, 1.0);
      expect(GemRarity.uncommon.scoreMultiplier, 1.5);
      expect(GemRarity.rare.scoreMultiplier, 2.0);
      expect(GemRarity.epic.scoreMultiplier, 3.0);
      expect(GemRarity.legendary.scoreMultiplier, 5.0);
    });

    test('Gem.visual returns correct visual def', () {
      const gem = Gem(type: GemType.red);
      expect(gem.visual.name, 'Ruby Red');
      expect(gem.visual.rarity, GemRarity.common);

      const blueGem = Gem(type: GemType.blue);
      expect(blueGem.visual.name, 'Sapphire Blue');
    });

    test('GemVisualDef equality is based on id', () {
      expect(GemVisuals.rubyRed, equals(GemVisuals.rubyRed));
      expect(GemVisuals.rubyRed, isNot(equals(GemVisuals.garnet)));
    });

    test('GemVisualDef toString works', () {
      expect(GemVisuals.rubyRed.toString(), 'GemVisualDef(0: Ruby Red)');
    });
  });
}

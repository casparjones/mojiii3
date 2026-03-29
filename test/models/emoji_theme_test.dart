import 'package:flutter_test/flutter_test.dart';

import 'package:match3/models/emoji_theme.dart';
import 'package:match3/models/gem_type.dart';
import 'package:match3/game/save_system.dart';

void main() {
  // Reset active theme before each test.
  setUp(() {
    EmojiTheme.active = EmojiTheme.fruit;
  });

  group('EmojiTheme', () {
    test('fruit theme has correct emojis', () {
      expect(EmojiTheme.fruit.emojiFor(GemType.red), '🍎');
      expect(EmojiTheme.fruit.emojiFor(GemType.blue), '🫐');
      expect(EmojiTheme.fruit.emojiFor(GemType.green), '🍋');
      expect(EmojiTheme.fruit.emojiFor(GemType.yellow), '🍊');
      expect(EmojiTheme.fruit.emojiFor(GemType.purple), '🍇');
      expect(EmojiTheme.fruit.emojiFor(GemType.orange), '🍓');
    });

    test('animals theme has correct emojis', () {
      expect(EmojiTheme.animals.emojiFor(GemType.red), '🐱');
      expect(EmojiTheme.animals.emojiFor(GemType.blue), '🐶');
      expect(EmojiTheme.animals.emojiFor(GemType.green), '🐰');
      expect(EmojiTheme.animals.emojiFor(GemType.yellow), '🦊');
      expect(EmojiTheme.animals.emojiFor(GemType.purple), '🐼');
      expect(EmojiTheme.animals.emojiFor(GemType.orange), '🐨');
    });

    test('space theme has correct emojis', () {
      expect(EmojiTheme.space.emojiFor(GemType.red), '🚀');
      expect(EmojiTheme.space.emojiFor(GemType.blue), '🌙');
      expect(EmojiTheme.space.emojiFor(GemType.green), '⭐');
      expect(EmojiTheme.space.emojiFor(GemType.yellow), '💫');
      expect(EmojiTheme.space.emojiFor(GemType.purple), '🪐');
      expect(EmojiTheme.space.emojiFor(GemType.orange), '☄️');
    });

    test('byId returns correct theme', () {
      expect(EmojiTheme.byId('theme_fruit'), EmojiTheme.fruit);
      expect(EmojiTheme.byId('theme_animals'), EmojiTheme.animals);
      expect(EmojiTheme.byId('theme_space'), EmojiTheme.space);
    });

    test('byId returns fruit for unknown id', () {
      expect(EmojiTheme.byId('unknown'), EmojiTheme.fruit);
    });

    test('allThemes contains all themes', () {
      expect(EmojiTheme.allThemes.length, 16);
      expect(EmojiTheme.allThemes, contains(EmojiTheme.fruit));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.animals));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.space));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.tools));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.hands));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.people));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.cats));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.hearts));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.professions));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.flowers));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.weather));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.moon));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.food));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.party));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.landmarks));
      expect(EmojiTheme.allThemes, contains(EmojiTheme.flags));
    });

    test('active defaults to fruit', () {
      expect(EmojiTheme.active, EmojiTheme.fruit);
    });

    test('setting active changes the global theme', () {
      EmojiTheme.active = EmojiTheme.animals;
      expect(EmojiTheme.active, EmojiTheme.animals);
    });

    test('setActiveById changes the global theme', () {
      EmojiTheme.setActiveById('theme_space');
      expect(EmojiTheme.active, EmojiTheme.space);
    });

    test('emojiList returns all 6 emojis in order', () {
      final list = EmojiTheme.fruit.emojiList;
      expect(list.length, 6);
      expect(list[0], '🍎');
      expect(list[5], '🍓');
    });

    test('equality works by id', () {
      const a = EmojiTheme(
          id: 'test', name: 'Test', emojis: {GemType.red: 'X'});
      const b = EmojiTheme(
          id: 'test', name: 'Different', emojis: {GemType.blue: 'Y'});
      expect(a, equals(b));
    });

    test('toString returns readable form', () {
      expect(EmojiTheme.fruit.toString(), 'EmojiTheme(theme_fruit)');
    });
  });

  group('GemType.emoji with themes', () {
    test('returns fruit emojis by default', () {
      expect(GemType.red.emoji, '🍎');
      expect(GemType.blue.emoji, '🫐');
    });

    test('returns animal emojis when animal theme is active', () {
      EmojiTheme.active = EmojiTheme.animals;
      expect(GemType.red.emoji, '🐱');
      expect(GemType.blue.emoji, '🐶');
      expect(GemType.green.emoji, '🐰');
      expect(GemType.yellow.emoji, '🦊');
      expect(GemType.purple.emoji, '🐼');
      expect(GemType.orange.emoji, '🐨');
    });

    test('returns space emojis when space theme is active', () {
      EmojiTheme.active = EmojiTheme.space;
      expect(GemType.red.emoji, '🚀');
      expect(GemType.blue.emoji, '🌙');
      expect(GemType.green.emoji, '⭐');
    });

    test('defaultEmoji always returns fruit emoji', () {
      EmojiTheme.active = EmojiTheme.animals;
      expect(GemType.red.defaultEmoji, '🍎');
      expect(GemType.blue.defaultEmoji, '🫐');
    });

    test('switching theme updates emoji dynamically', () {
      expect(GemType.red.emoji, '🍎');

      EmojiTheme.active = EmojiTheme.space;
      expect(GemType.red.emoji, '🚀');

      EmojiTheme.active = EmojiTheme.fruit;
      expect(GemType.red.emoji, '🍎');
    });
  });

  group('SaveState selectedThemeId', () {
    test('defaults to theme_fruit', () {
      final save = SaveState();
      expect(save.selectedThemeId, 'theme_fruit');
    });

    test('serializes and deserializes selectedThemeId', () {
      final save = SaveState(selectedThemeId: 'theme_animals');
      final json = save.toJson();
      final restored = SaveState.fromJson(json);
      expect(restored.selectedThemeId, 'theme_animals');
    });
  });
}

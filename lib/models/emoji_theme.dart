import 'gem_type.dart';

/// Defines an emoji theme mapping each [GemType] to an emoji string.
class EmojiTheme {
  /// Unique identifier for this theme (matches shop item IDs).
  final String id;

  /// Display name for the theme.
  final String name;

  /// The emoji mapping for each gem type.
  final Map<GemType, String> emojis;

  const EmojiTheme({
    required this.id,
    required this.name,
    required this.emojis,
  });

  /// Returns the emoji for the given [GemType] in this theme.
  String emojiFor(GemType type) => emojis[type] ?? type.defaultEmoji;

  /// All emojis in this theme as a list (in GemType.values order).
  List<String> get emojiList =>
      GemType.values.map((t) => emojiFor(t)).toList();

  // ---------------------------------------------------------------------------
  // Built-in themes
  // ---------------------------------------------------------------------------

  /// Fruit theme (default).
  static const fruit = EmojiTheme(
    id: 'theme_fruit',
    name: 'Fruit Theme',
    emojis: {
      GemType.red: '🍎',
      GemType.blue: '🫐',
      GemType.green: '🍋',
      GemType.yellow: '🍊',
      GemType.purple: '🍇',
      GemType.orange: '🍓',
    },
  );

  /// Animal theme.
  static const animals = EmojiTheme(
    id: 'theme_animals',
    name: 'Animal Theme',
    emojis: {
      GemType.red: '🐱',
      GemType.blue: '🐶',
      GemType.green: '🐰',
      GemType.yellow: '🦊',
      GemType.purple: '🐼',
      GemType.orange: '🐨',
    },
  );

  /// Space theme.
  static const space = EmojiTheme(
    id: 'theme_space',
    name: 'Space Theme',
    emojis: {
      GemType.red: '🚀',
      GemType.blue: '🌙',
      GemType.green: '⭐',
      GemType.yellow: '💫',
      GemType.purple: '🪐',
      GemType.orange: '☄️',
    },
  );

  /// Handwerker (Tools) theme.
  static const tools = EmojiTheme(
    id: 'theme_tools',
    name: 'Handwerker',
    emojis: {
      GemType.red: '🔨',
      GemType.blue: '🪚',
      GemType.green: '🪛',
      GemType.yellow: '🔧',
      GemType.purple: '🔩',
      GemType.orange: '⚙️',
    },
  );

  /// Hands theme.
  static const hands = EmojiTheme(
    id: 'theme_hands',
    name: 'Haende',
    emojis: {
      GemType.red: '👊',
      GemType.blue: '✌️',
      GemType.green: '🤙',
      GemType.yellow: '👋',
      GemType.purple: '🖖',
      GemType.orange: '👍',
    },
  );

  /// People theme.
  static const people = EmojiTheme(
    id: 'theme_people',
    name: 'Menschen',
    emojis: {
      GemType.red: '👮',
      GemType.blue: '🧙',
      GemType.green: '🧛',
      GemType.yellow: '🤴',
      GemType.purple: '🧜‍♀️',
      GemType.orange: '🦸',
    },
  );

  /// Cats theme.
  static const cats = EmojiTheme(
    id: 'theme_cats',
    name: 'Katzen',
    emojis: {
      GemType.red: '🐱',
      GemType.blue: '🐯',
      GemType.green: '🦁',
      GemType.yellow: '🐆',
      GemType.purple: '🐈‍⬛',
      GemType.orange: '🐾',
    },
  );

  /// Hearts theme.
  static const hearts = EmojiTheme(
    id: 'theme_hearts',
    name: 'Herzen',
    emojis: {
      GemType.red: '❤️',
      GemType.blue: '💙',
      GemType.green: '💚',
      GemType.yellow: '💛',
      GemType.purple: '💜',
      GemType.orange: '🧡',
    },
  );

  /// Professions theme.
  static const professions = EmojiTheme(
    id: 'theme_professions',
    name: 'Berufe',
    emojis: {
      GemType.red: '👨‍⚕️',
      GemType.blue: '👨‍🍳',
      GemType.green: '👨‍🚒',
      GemType.yellow: '👨‍🔬',
      GemType.purple: '👷',
      GemType.orange: '👨‍🏫',
    },
  );

  /// Flowers theme.
  static const flowers = EmojiTheme(
    id: 'theme_flowers',
    name: 'Blumen',
    emojis: {
      GemType.red: '🌹',
      GemType.blue: '🌻',
      GemType.green: '🌵',
      GemType.yellow: '🌷',
      GemType.purple: '💐',
      GemType.orange: '🍀',
    },
  );

  /// Weather theme.
  static const weather = EmojiTheme(
    id: 'theme_weather',
    name: 'Wetter',
    emojis: {
      GemType.red: '☀️',
      GemType.blue: '🌧️',
      GemType.green: '🌪️',
      GemType.yellow: '⛈️',
      GemType.purple: '🌈',
      GemType.orange: '🌤️',
    },
  );

  /// Moon & Space theme.
  static const moon = EmojiTheme(
    id: 'theme_moon',
    name: 'Mond & Nacht',
    emojis: {
      GemType.red: '🌙',
      GemType.blue: '🌕',
      GemType.green: '🦉',
      GemType.yellow: '⭐',
      GemType.purple: '🦇',
      GemType.orange: '🔭',
    },
  );

  /// Food theme.
  static const food = EmojiTheme(
    id: 'theme_food',
    name: 'Essen',
    emojis: {
      GemType.red: '🍕',
      GemType.blue: '🍔',
      GemType.green: '🍣',
      GemType.yellow: '🌮',
      GemType.purple: '🍩',
      GemType.orange: '🍟',
    },
  );

  /// Party theme.
  static const party = EmojiTheme(
    id: 'theme_party',
    name: 'Party',
    emojis: {
      GemType.red: '🎉',
      GemType.blue: '🎈',
      GemType.green: '🎂',
      GemType.yellow: '🥂',
      GemType.purple: '🎊',
      GemType.orange: '🎁',
    },
  );

  /// Landmarks theme.
  static const landmarks = EmojiTheme(
    id: 'theme_landmarks',
    name: 'Sehenswuerdigkeiten',
    emojis: {
      GemType.red: '🗼',
      GemType.blue: '🗽',
      GemType.green: '🏰',
      GemType.yellow: '🕌',
      GemType.purple: '⛩️',
      GemType.orange: '🗿',
    },
  );

  /// Flags theme.
  static const flags = EmojiTheme(
    id: 'theme_flags',
    name: 'Flaggen',
    emojis: {
      GemType.red: '🇩🇪',
      GemType.blue: '🇫🇷',
      GemType.green: '🇮🇹',
      GemType.yellow: '🇪🇸',
      GemType.purple: '🇬🇧',
      GemType.orange: '🇯🇵',
    },
  );

  /// All available themes.
  static const List<EmojiTheme> allThemes = [
    fruit,
    animals,
    space,
    tools,
    hands,
    people,
    cats,
    hearts,
    professions,
    flowers,
    weather,
    moon,
    food,
    party,
    landmarks,
    flags,
  ];

  /// Look up a theme by its [id]. Returns [fruit] if not found.
  static EmojiTheme byId(String id) {
    for (final theme in allThemes) {
      if (theme.id == id) return theme;
    }
    return fruit;
  }

  // ---------------------------------------------------------------------------
  // Active theme (global state for GemType.emoji access)
  // ---------------------------------------------------------------------------

  /// The currently active theme. Defaults to [fruit].
  static EmojiTheme _active = fruit;

  /// Get the currently active theme.
  static EmojiTheme get active => _active;

  /// Set the active theme.
  static set active(EmojiTheme theme) {
    _active = theme;
  }

  /// Set the active theme by its ID string.
  static void setActiveById(String id) {
    _active = byId(id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EmojiTheme && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmojiTheme($id)';
}

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

  /// All available themes.
  static const List<EmojiTheme> allThemes = [fruit, animals, space];

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

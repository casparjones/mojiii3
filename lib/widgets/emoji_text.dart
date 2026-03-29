import 'package:flutter/material.dart';

/// A Text widget that renders emoji using the bundled Noto Color Emoji font
/// (Apache 2.0 licensed by Google) for consistent, license-safe rendering
/// across all platforms.
///
/// This replaces platform-specific emoji fonts (Apple Color Emoji, etc.)
/// to avoid potential licensing issues with proprietary emoji designs.
class EmojiText extends StatelessWidget {
  /// The emoji string to display.
  final String emoji;

  /// Font size for the emoji.
  final double fontSize;

  /// Optional additional text style properties (color, shadows, etc.).
  /// The [fontFamily] and [fontSize] will be overridden.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  const EmojiText(
    this.emoji, {
    super.key,
    this.fontSize = 24.0,
    this.style,
    this.textAlign,
  });

  /// The font family name for the bundled Noto Color Emoji font.
  static const String emojiFontFamily = 'NotoColorEmoji';

  /// Creates a [TextStyle] that uses the open-source emoji font.
  static TextStyle emojiStyle({double fontSize = 24.0, TextStyle? base}) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: emojiFontFamily,
      fontSize: fontSize,
      // Ensure emoji font is tried first, then fall back to platform default.
      fontFamilyFallback: const ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      textAlign: textAlign,
      style: emojiStyle(fontSize: fontSize, base: style),
    );
  }
}

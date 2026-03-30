# Mojiii 3

A free and open source match-3 puzzle game built with Flutter, inspired by classic gem-swapping puzzlers.

Swap adjacent emoji gems to create matches of 3 or more, trigger cascading combos, unlock special gems, and progress through procedurally generated levels.

## Features

- 6 gem types with swappable emoji themes
- Special gems: striped (row/col), bomb (3x3), rainbow (color clear)
- Cascade combos with score multipliers
- Procedurally generated levels with move and time constraints
- Obstacles: ice, stone, chains, slime
- Boss levels
- Free/endless mode
- Power-ups and in-game coin shop (no real money)
- Hint system and deadlock detection
- Background music and sound effects
- Fully offline - no tracking, no ads, no permissions

## Build

```bash
flutter pub get
flutter run -d linux        # Linux desktop
flutter run -d chrome       # Web
flutter build apk           # Android APK
```

## Test

```bash
flutter test
flutter analyze
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

Non-functional assets may use separate licenses:
- Noto Color Emoji font: Apache 2.0 (see `assets/fonts/LICENSE-NotoColorEmoji.txt`)

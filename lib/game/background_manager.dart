/// Helper class that maps level numbers to background image asset paths.
class BackgroundManager {
  /// Returns the asset path for the background based on level number and orientation.
  static String getBackgroundPath(int levelNumber, {bool landscape = false}) {
    final suffix = landscape ? 'landscape' : 'portrait';
    if (levelNumber <= 10) return 'assets/backgrounds/level_01_10_$suffix.png';
    if (levelNumber <= 20) return 'assets/backgrounds/level_11_20_$suffix.png';
    if (levelNumber <= 30) return 'assets/backgrounds/level_21_30_$suffix.png';
    if (levelNumber <= 40) return 'assets/backgrounds/level_31_40_$suffix.png';
    if (levelNumber <= 50) return 'assets/backgrounds/level_41_50_$suffix.png';
    if (levelNumber <= 60) return 'assets/backgrounds/level_51_60_$suffix.png';
    if (levelNumber <= 70) return 'assets/backgrounds/level_61_70_$suffix.png';
    if (levelNumber <= 80) return 'assets/backgrounds/level_71_80_$suffix.png';
    if (levelNumber <= 90) return 'assets/backgrounds/level_81_90_$suffix.png';
    return 'assets/backgrounds/level_91_100_$suffix.png';
  }
}

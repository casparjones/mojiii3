import 'package:package_info_plus/package_info_plus.dart';

/// Manages store detection and provides the correct sharing link
/// based on the installation source (Play Store, F-Droid, or fallback).
class StoreConfig {
  // TODO: Replace these placeholder URLs with real ones once published.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.match3';
  static const String fDroidUrl =
      'https://f-droid.org/packages/com.example.match3';
  static const String fallbackUrl =
      'https://example.com/match3';

  /// Known installer package names mapped to their store URLs.
  static const Map<String, String> _installerToUrl = {
    'com.android.vending': playStoreUrl,
    'com.google.android.packageinstaller': playStoreUrl,
    'org.fdroid.fdroid': fDroidUrl,
    'org.fdroid.fdroid.privileged': fDroidUrl,
  };

  /// Cached result so we only detect once.
  static String? _cachedStoreUrl;

  /// Detects the installation source and returns the appropriate store URL.
  ///
  /// Uses [PackageInfo.fromPlatform] to read the `installerStore` value
  /// and maps it to a known store URL.  Falls back to [fallbackUrl] when
  /// the source is unknown (e.g. sideloading, debug builds).
  static Future<String> getStoreUrl() async {
    if (_cachedStoreUrl != null) return _cachedStoreUrl!;

    try {
      final info = await PackageInfo.fromPlatform();
      final installer = info.installerStore ?? '';

      _cachedStoreUrl = _installerToUrl[installer] ?? fallbackUrl;
    } catch (_) {
      // On platforms where PackageInfo is unavailable, use fallback.
      _cachedStoreUrl = fallbackUrl;
    }

    return _cachedStoreUrl!;
  }

  /// Returns a user-friendly store name for display purposes.
  static Future<String> getStoreName() async {
    final url = await getStoreUrl();
    if (url == playStoreUrl) return 'Google Play';
    if (url == fDroidUrl) return 'F-Droid';
    return 'Website';
  }

  /// Builds a share text including the correct store link.
  static Future<String> buildShareText({
    String message = 'Check out this fun Match-3 game!',
  }) async {
    final url = await getStoreUrl();
    return '$message\n$url';
  }
}

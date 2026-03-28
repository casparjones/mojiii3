#!/usr/bin/env bash
set -euo pipefail

mkdir -p bin

echo "Building APK..."
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk bin/match3.apk
echo "Done: bin/match3.apk"

#!/usr/bin/env fish

mkdir -p bin

echo "Building APK..."
flutter build apk --release
and cp build/app/outputs/flutter-apk/app-release.apk bin/match3.apk
and echo "Done: bin/match3.apk"

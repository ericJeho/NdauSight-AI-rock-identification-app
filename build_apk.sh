#!/usr/bin/env bash
# One-command local APK build for NdauSight AI.
#
# Requires: Flutter SDK (3.27+) on your PATH, plus a Java 17 JDK and the
# Android SDK (both come with Android Studio). Run from the project root:
#
#     ./build_apk.sh
#
# The installable APK is written to:
#     build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail

echo "==> Checking Flutter..."
flutter --version

echo "==> Generating Android platform files (if missing)..."
flutter create . --platforms=android --org com.ndausight --project-name ndausight

echo "==> Restoring custom AndroidManifest (camera/GPS permissions)..."
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git checkout -- android/app/src/main/AndroidManifest.xml || true
else
  echo "    (not a git repo — make sure android/app/src/main/AndroidManifest.xml"
  echo "     still contains the CAMERA / LOCATION permissions.)"
fi

echo "==> Installing packages..."
flutter pub get

echo "==> Generating launcher icon & splash screen..."
dart run flutter_native_splash:create
dart run flutter_launcher_icons

echo "==> Running tests..."
flutter test || echo "    (tests reported issues — continuing to build)"

echo "==> Building release APK..."
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "==> Done. APK ready at: $APK"
ls -lh "$APK" 2>/dev/null || true
echo "Copy it to your Android phone and open it to install (enable"
echo "'Install unknown apps' for your file manager first)."

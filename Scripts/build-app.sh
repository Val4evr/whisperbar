#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/Build"
APP_DIR="$BUILD_DIR/WhisperBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c release --product WhisperBar

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$CONTENTS_DIR/Resources"
cp ".build/release/WhisperBar" "$MACOS_DIR/WhisperBar"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>WhisperBar</string>
  <key>CFBundleIdentifier</key>
  <string>ai.valprok.WhisperBar</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>WhisperBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>WhisperBar sends paste commands to the app you are dictating into.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>WhisperBar records your voice to transcribe dictation.</string>
</dict>
</plist>
PLIST

xattr -cr "$APP_DIR"
find "$APP_DIR" -exec xattr -c {} + 2>/dev/null || true

echo "$APP_DIR"

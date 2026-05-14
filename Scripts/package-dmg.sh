#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/Build"
APP_DIR="$BUILD_DIR/WhisperBar.app"
DIST_DIR="$ROOT_DIR/Dist"
ENTITLEMENTS="$ROOT_DIR/Resources/WhisperBar.entitlements"
CLEAN_ROOT="$(mktemp -d)"
CLEAN_APP="$CLEAN_ROOT/WhisperBar.app"
ARCHIVE="$CLEAN_ROOT/WhisperBar.tar"
DMG_ROOT="$CLEAN_ROOT/dmg"

cleanup() {
  rm -rf "$CLEAN_ROOT"
}
trap cleanup EXIT

cd "$ROOT_DIR"
"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
DMG="$DIST_DIR/WhisperBar-$VERSION-unsigned.dmg"

mkdir -p "$DIST_DIR" "$DMG_ROOT"
rm -f "$DMG"

COPYFILE_DISABLE=1 tar -C "$BUILD_DIR" -cf "$ARCHIVE" "WhisperBar.app"
mkdir -p "$CLEAN_ROOT/unpacked"
tar -C "$CLEAN_ROOT/unpacked" -xf "$ARCHIVE"
mv "$CLEAN_ROOT/unpacked/WhisperBar.app" "$CLEAN_APP"
xattr -cr "$CLEAN_APP"

IDENTITY="${WHISPERBAR_DMG_CODESIGN_IDENTITY:--}"
codesign \
  --force \
  --deep \
  --timestamp=none \
  --entitlements "$ENTITLEMENTS" \
  --sign "$IDENTITY" \
  "$CLEAN_APP"

codesign --verify --deep --strict --verbose=2 "$CLEAN_APP"
ditto "$CLEAN_APP" "$DMG_ROOT/WhisperBar.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "WhisperBar $VERSION" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

echo "$DMG"

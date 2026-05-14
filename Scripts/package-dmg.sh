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

stage_finder_layout() {
  if [[ "${WHISPERBAR_SKIP_DMG_LAYOUT:-0}" == "1" ]]; then
    return
  fi

  if ! /usr/bin/osascript >/dev/null <<APPLESCRIPT
set dmgFolder to POSIX file "$DMG_ROOT" as alias

tell application "Finder"
  open dmgFolder
  delay 0.5

  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {120, 120, 660, 420}

  set viewOptions to icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 104
  set text size of viewOptions to 13

  set position of item "WhisperBar.app" of dmgFolder to {170, 145}
  set position of item "Applications" of dmgFolder to {390, 145}

  update dmgFolder without registering applications
  close dmgWindow
end tell
APPLESCRIPT
  then
    echo "warning: unable to set Finder layout; continuing with a plain DMG" >&2
    return
  fi
}

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
stage_finder_layout

hdiutil create \
  -volname "WhisperBar $VERSION" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

echo "$DMG"

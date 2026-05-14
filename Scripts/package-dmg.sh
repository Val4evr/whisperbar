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
RW_DMG="$CLEAN_ROOT/WhisperBar-rw.dmg"
MOUNT_POINT="$CLEAN_ROOT/mount"
MOUNTED=0

cleanup() {
  if [[ "$MOUNTED" == "1" ]]; then
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  rm -rf "$CLEAN_ROOT"
}
trap cleanup EXIT

stage_finder_layout() {
  local volume_root="$1"

  if [[ "${WHISPERBAR_SKIP_DMG_LAYOUT:-0}" == "1" ]]; then
    return
  fi

  if ! /usr/bin/osascript >/dev/null <<APPLESCRIPT
set dmgFolder to POSIX file "$volume_root" as alias

tell application "Finder"
  open dmgFolder
  delay 0.75

  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {120, 120, 620, 380}

  set viewOptions to icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 112
  set text size of viewOptions to 13

  set position of item "WhisperBar.app" of dmgFolder to {150, 145}
  set position of item "Applications" of dmgFolder to {350, 145}
  set extension hidden of item "WhisperBar.app" of dmgFolder to true

  update dmgFolder without registering applications
  delay 0.5
  close dmgWindow
end tell
APPLESCRIPT
  then
    echo "warning: unable to set Finder layout; continuing with default icon view" >&2
  fi
}

cd "$ROOT_DIR"
"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
DMG="$DIST_DIR/WhisperBar-$VERSION-unsigned.dmg"

mkdir -p "$DIST_DIR" "$MOUNT_POINT"
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

hdiutil create \
  -volname "WhisperBar $VERSION" \
  -size "${WHISPERBAR_DMG_SIZE:-80m}" \
  -fs HFS+ \
  -ov \
  "$RW_DMG" >/dev/null
hdiutil attach "$RW_DMG" \
  -mountpoint "$MOUNT_POINT" \
  -nobrowse \
  -noverify \
  -noautoopen \
  -owners on >/dev/null
MOUNTED=1

ditto "$CLEAN_APP" "$MOUNT_POINT/WhisperBar.app"
ln -s /Applications "$MOUNT_POINT/Applications"
stage_finder_layout "$MOUNT_POINT"
sync
hdiutil detach "$MOUNT_POINT" >/dev/null
MOUNTED=0

hdiutil convert "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG" >/dev/null

echo "$DMG"

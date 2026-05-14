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

cleanup() {
  rm -rf "$CLEAN_ROOT"
}
trap cleanup EXIT

cd "$ROOT_DIR"
"$ROOT_DIR/Scripts/build-app.sh" >/dev/null

IDENTITY="${WHISPERBAR_RELEASE_CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning | awk -F\" '/Developer ID Application:/ { print $2; exit }')"
fi

if [[ -z "$IDENTITY" ]]; then
  cat >&2 <<'EOF'
No Developer ID Application signing identity found.

Create one from an Apple Developer Program account, or pass it explicitly:
  WHISPERBAR_RELEASE_CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" Scripts/package-release.sh
EOF
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
ZIP="$DIST_DIR/WhisperBar-$VERSION.zip"
mkdir -p "$DIST_DIR"
rm -f "$ZIP"

COPYFILE_DISABLE=1 tar -C "$BUILD_DIR" -cf "$ARCHIVE" "WhisperBar.app"
mkdir -p "$CLEAN_ROOT/unpacked"
tar -C "$CLEAN_ROOT/unpacked" -xf "$ARCHIVE"
mv "$CLEAN_ROOT/unpacked/WhisperBar.app" "$CLEAN_APP"
xattr -cr "$CLEAN_APP"

codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$IDENTITY" \
  "$CLEAN_APP"

codesign --verify --deep --strict --verbose=2 "$CLEAN_APP"
ditto -c -k --keepParent "$CLEAN_APP" "$ZIP"

PROFILE="${WHISPERBAR_NOTARY_PROFILE:-}"
if [[ -n "$PROFILE" ]]; then
  xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
  xcrun stapler staple "$CLEAN_APP"
  xcrun stapler validate "$CLEAN_APP"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$CLEAN_APP" "$ZIP"
  spctl --assess --type execute --verbose=4 "$CLEAN_APP"
elif [[ "${WHISPERBAR_SKIP_NOTARIZATION:-}" != "1" ]]; then
  cat >&2 <<EOF
Signed $ZIP, but did not notarize it.

Create a notarytool keychain profile, then rerun:
  xcrun notarytool store-credentials whisperbar-notary --apple-id <apple-id> --team-id <team-id> --password <app-specific-password>
  WHISPERBAR_NOTARY_PROFILE=whisperbar-notary Scripts/package-release.sh

For a local unsigned-notarization dry run only:
  WHISPERBAR_SKIP_NOTARIZATION=1 Scripts/package-release.sh
EOF
  exit 1
fi

echo "$ZIP"

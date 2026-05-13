#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/Build/WhisperBar.app"
INSTALL_DIR="/Applications/WhisperBar.app"
CLEAN_ROOT="$(mktemp -d)"
CLEAN_APP="$CLEAN_ROOT/WhisperBar.app"
ARCHIVE="$CLEAN_ROOT/WhisperBar.tar"

cleanup() {
  rm -rf "$CLEAN_ROOT"
}
trap cleanup EXIT

cd "$ROOT_DIR"
"$ROOT_DIR/Scripts/build-app.sh"

IDENTITY="${WHISPERBAR_CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning | awk -F\" '/Apple Development:/ { print $2; exit }')"
fi

if [[ -z "$IDENTITY" ]]; then
  echo "No Apple Development signing identity found. Install Xcode signing credentials first." >&2
  exit 1
fi

COPYFILE_DISABLE=1 tar -C "$ROOT_DIR/Build" -cf "$ARCHIVE" "WhisperBar.app"
mkdir -p "$CLEAN_ROOT/unpacked"
tar -C "$CLEAN_ROOT/unpacked" -xf "$ARCHIVE"
mv "$CLEAN_ROOT/unpacked/WhisperBar.app" "$CLEAN_APP"

codesign --force --deep --timestamp=none --sign "$IDENTITY" "$CLEAN_APP"
codesign --verify --deep --strict --verbose=2 "$CLEAN_APP"
rm -rf "$INSTALL_DIR"
ditto "$CLEAN_APP" "$INSTALL_DIR"
xattr -cr "$INSTALL_DIR"
codesign --verify --deep --strict --verbose=2 "$INSTALL_DIR"

echo "$INSTALL_DIR"

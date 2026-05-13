#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/Build/WhisperBar.app"
INSTALL_DIR="/Applications/WhisperBar.app"

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

codesign --force --deep --timestamp=none --sign "$IDENTITY" "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

rm -rf "$INSTALL_DIR"
ditto "$APP_DIR" "$INSTALL_DIR"
xattr -cr "$INSTALL_DIR"

echo "$INSTALL_DIR"

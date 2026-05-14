# Changelog

## 0.1.3 - 2026-05-14

DMG target icon fix.

- Use a Finder alias for the Applications drop target instead of a Unix symlink.

## 0.1.4 - 2026-05-14

Packaging polish.

- Package the DMG with a small drag-to-Applications Finder window.
- Replace the cropped contact-sheet app icon with a centered generated icon asset.

## 0.1.1 - 2026-05-14

Release polish.

- Add the WhisperBar app icon to the macOS app bundle.
- Stamp a simple Finder icon layout into unsigned DMG builds.

## 0.1.0 - 2026-05-14

First usable release.

- Menu bar only macOS dictation app.
- Realtime transcription through `gpt-realtime-whisper`.
- Floating live transcript pill.
- Paste into the focused app with clipboard restore for clipboard history.
- Local API key file storage with redacted UI state.
- Configurable global hotkey, unset by default.
- Local day/week/month usage and cost estimate.
- Launch at login toggle.
- Unsigned DMG install flow through GitHub Releases.
- Source install flow through `INSTALL_FROM_SOURCE.md`.

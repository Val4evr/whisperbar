# WhisperBar

WhisperBar is a tiny native macOS menu bar dictation app. It streams microphone audio to OpenAI's Realtime transcription API with `gpt-realtime-whisper`, shows a compact live dictation pill, pastes the final transcript into the currently focused app, and restores your previous clipboard afterward.

## Build

```sh
swift test
Scripts/build-app.sh
open Build/WhisperBar.app
```

The app stores your OpenAI API key in macOS Keychain. The app bundle includes microphone and Apple Events usage descriptions and runs as an accessory app, so it does not show in the Dock.

## Default Hotkey

The default toggle is `Command + Right Shift + /`. The right-shift distinction is handled with a global event tap, which requires Accessibility permission.

## Notes

- The model and endpoint are intentionally fixed to `gpt-realtime-whisper`.
- There is no backend. API traffic goes directly from your Mac to OpenAI.
- Clipboard restoration is delayed slightly so clipboard-history tools can observe the dictated text before the prior clipboard content is restored.

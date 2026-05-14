# WhisperBar

WhisperBar is a small native macOS menu bar dictation app. Press a global hotkey, speak, watch a floating transcript pill, then let the app paste the final transcript into the currently focused field.

It talks directly to the OpenAI API from your Mac. There is no backend, account sync, model picker, endpoint picker, or developer settings surface.

![WhisperBar menu bar panel](Assets/menu-panel.png)

![WhisperBar live dictation pill](Assets/dictation-pill.png)

## Install

Official install path for now: point a coding agent at [INSTALL.md](INSTALL.md) and ask it to install WhisperBar from source.

Short version:

```sh
git clone https://github.com/Val4evr/whisperbar.git
cd whisperbar
swift test
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

Then add your own OpenAI API key, choose a hotkey, and grant Microphone/Accessibility permissions to `/Applications/WhisperBar.app`.

> [!NOTE]
> WhisperBar is menu-bar-only and will not appear in the Dock.

## Features

- Streams microphone audio to OpenAI Realtime transcription with `gpt-realtime-whisper`.
- Shows a floating, draggable, non-activating dictation pill while recording/finalizing.
- Displays live transcript deltas while speaking.
- Uses final completed transcript events for pasted text when available.
- Pastes into the currently focused app with a synthetic `Cmd+V`.
- Preserves clipboard history by restoring the previous clipboard after paste.
- Stores the OpenAI API key locally in a user-only app support file.
- Tracks local usage by dictation duration and estimates cost for day/week/month.
- Supports launch at login.

## Notes

Fresh installs start with no hotkey configured. Use `Change` to record one, or press the reset button to fill in the suggested `Control + Option + Space` shortcut.

WhisperBar needs Microphone permission for dictation and Accessibility permission for automatic paste. Always grant permissions to the stable installed app at `/Applications/WhisperBar.app`, not the temporary `Build/WhisperBar.app` bundle.

OpenAI bills `gpt-realtime-whisper` by audio duration. WhisperBar estimates local cost at `$0.017/minute`, about `$1.02/hour`; this is not a billing API integration.

## License

WhisperBar is released under the [MIT License](LICENSE).

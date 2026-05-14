# WhisperBar

WhisperBar is a small native macOS menu bar dictation app. It is intentionally narrow: press the global hotkey, speak, watch a floating transcript pill, then let the app paste the final transcript into the currently focused field.

The app talks directly to the OpenAI API from the Mac. There is no backend, account sync, model picker, endpoint picker, or developer settings surface.

## Install

Official install path for now: point a coding agent at [INSTALL.md](INSTALL.md) and ask it to install WhisperBar from source.

Short version:

```sh
git clone https://github.com/Val4evr/menubar-dictation.git
cd menubar-dictation
swift test
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

Then add your own OpenAI API key, choose a hotkey, and grant Microphone/Accessibility permissions to `/Applications/WhisperBar.app`.

## Functionality

- Lives only in the macOS menu bar. It does not show a Dock icon.
- Streams microphone audio to OpenAI Realtime transcription with `gpt-realtime-whisper`.
- Shows a floating, draggable, non-activating dictation pill while recording/finalizing.
- Displays live transcript deltas while speaking.
- Uses final completed transcript events for the pasted text when available.
- Pastes into the currently focused app with a synthetic `Cmd+V`.
- Preserves clipboard history:
  - snapshots the current pasteboard,
  - writes the dictated text,
  - sends paste,
  - restores the previous pasteboard after a short delay.
- Stores the OpenAI API key locally in a user-only app support file.
- Tracks local usage by dictation duration and estimates cost for day/week/month.
- Supports launch at login.

## Menu Bar Panel

The menu bar panel is the only configuration UI:

- **Cost**: local usage estimate for day, week, or month, with a small bar chart. Hover bars to inspect bucket-level hour/day, estimated audio tokens, minutes, and cost.
- **OpenAI API Key**: saved keys are shown as a redacted read-only field. Click `Remove` to clear the saved key and enter a replacement.
- **Permissions**: microphone and Accessibility status.
- **Hotkey**: current global shortcut, a `Change` button to capture a shortcut, and a reset button that fills in `Control + Option + Space`.
- **Launch at Login**: macOS login item toggle. It is off by default.

Section icons use status color:

- Green means configured/available/enabled.
- Red means missing, empty, or disabled.

## Hotkey

Fresh installs start with no hotkey configured. Use `Change` to record one, or press the reset button to fill in the suggested shortcut:

```text
Control + Option + Space
```

WhisperBar uses Carbon global hotkey registration for normal shortcuts. Accessibility permission is still required for the paste step and for the legacy right-shift-aware event tap path.

## Permissions

Grant permissions to the stable installed app:

```text
/Applications/WhisperBar.app
```

Avoid granting permissions to `Build/WhisperBar.app` during normal testing. That bundle is temporary, and macOS may treat it as a different app identity across rebuilds.

Required permissions:

- **Microphone**: records dictation audio.
- **Accessibility**: sends the paste keystroke to the focused app.

## Local Files

WhisperBar keeps its state local:

```text
~/Library/Application Support/WhisperBar/openai.key
~/Library/Application Support/WhisperBar/api-key.json
~/Library/Application Support/WhisperBar/usage.json
~/Library/Logs/WhisperBar/WhisperBar.log
```

The API key file is written with user-only permissions (`0600`).

## Cost Accounting

OpenAI bills `gpt-realtime-whisper` by audio duration. WhisperBar records local dictation durations and estimates:

- audio tokens at `10 tokens/second`,
- minutes from local recording duration,
- cost at `$0.017/minute`.

This is a local estimate, not a billing API integration.

## Development

Requirements:

- macOS 14+
- Swift 6 toolchain
- Xcode command line tools
- Apple Development signing identity for stable installs

Run tests:

```sh
swift test
```

Build a local app bundle:

```sh
Scripts/build-app.sh
```

This creates:

```text
Build/WhisperBar.app
```

Use this only for quick bundle inspection. For actual app testing, install the signed `/Applications` copy.

## Stable Local Install

For day-to-day testing:

```sh
Scripts/build-install.sh
open /Applications/WhisperBar.app
```

`Scripts/build-install.sh`:

1. Builds the release executable.
2. Creates `Build/WhisperBar.app`.
3. Copies it through a metadata-stripping archive step.
4. Signs the clean copy with an Apple Development identity.
5. Verifies the signature.
6. Replaces `/Applications/WhisperBar.app`.
7. Verifies the installed app.

By default, the script uses the first `Apple Development:` codesigning identity returned by:

```sh
security find-identity -v -p codesigning
```

Override it with:

```sh
WHISPERBAR_CODESIGN_IDENTITY="Apple Development: Name (TEAMID)" Scripts/build-install.sh
```

The first run may prompt for access to the private signing key. Choose **Always Allow** for `codesign`; after that, permissions should survive app updates because the bundle identifier and signing identity remain stable.

## Release Flow

Current personal release flow:

```sh
swift test
Scripts/build-install.sh
open /Applications/WhisperBar.app
```

Then manually verify:

- menu bar panel opens below the menu bar and is not clipped,
- API key field is read-only when saved,
- microphone and Accessibility permissions are green,
- hotkey toggles dictation,
- pill appears and is draggable,
- transcript streams,
- stopping dictation pastes into the focused field,
- prior clipboard is restored,
- usage minutes/cost update in the menu.

Before pushing:

```sh
git status --short
git diff
git add <changed-files>
git commit -m "<message>"
git push
```

## Optional Packaged Distribution

The recommended install path is currently source install via [INSTALL.md](INSTALL.md). For non-technical users, the proper direct-distribution path is **Developer ID signing plus Apple notarization**. Do not send `Build/WhisperBar.app`, and do not rely on an Apple Development signature for release builds. Development signatures are for your own machines; friends will hit Gatekeeper friction and may lose permission continuity across builds.

One-time setup:

1. Join the Apple Developer Program.
2. Create/install a `Developer ID Application` certificate.
3. Create a notarytool keychain profile:

```sh
xcrun notarytool store-credentials whisperbar-notary \
  --apple-id <apple-id> \
  --team-id <team-id> \
  --password <app-specific-password>
```

Release:

```sh
swift test
WHISPERBAR_NOTARY_PROFILE=whisperbar-notary Scripts/package-release.sh
```

The release script:

1. Builds `Build/WhisperBar.app`.
2. Finds a `Developer ID Application:` signing identity, unless `WHISPERBAR_RELEASE_CODESIGN_IDENTITY` is set.
3. Signs with hardened runtime and `Resources/WhisperBar.entitlements`.
4. Creates `Dist/WhisperBar-<version>.zip`.
5. Submits the ZIP to Apple notarization with `notarytool`.
6. Staples the notarization ticket to the app.
7. Repackages the stapled app.
8. Runs `spctl` assessment.

The distributable artifact is:

```text
Dist/WhisperBar-<version>.zip
```

Friends can unzip it, drag `WhisperBar.app` to `/Applications`, open it, add their own OpenAI API key, and grant Microphone/Accessibility permissions to that stable `/Applications` copy.

For a release packaging dry run without notarization:

```sh
WHISPERBAR_SKIP_NOTARIZATION=1 Scripts/package-release.sh
```

Dry-run ZIPs are useful for inspecting the bundle, but they are not the recommended way to distribute the app.

## Troubleshooting

If macOS asks for permissions again, confirm that the running app is:

```text
/Applications/WhisperBar.app
```

not:

```text
Build/WhisperBar.app
```

Check the running process:

```sh
pgrep -fl WhisperBar
```

Check the installed signature:

```sh
codesign --verify --deep --strict --verbose=2 /Applications/WhisperBar.app
codesign -dv --verbose=4 /Applications/WhisperBar.app
```

Read logs:

```sh
tail -100 ~/Library/Logs/WhisperBar/WhisperBar.log
```

If signing fails with resource fork/Finder metadata errors, rerun:

```sh
Scripts/build-install.sh
```

The build scripts strip extended attributes from the temporary and installed bundles.

## Non-Goals

- No model picker.
- No endpoint picker.
- No provider abstraction.
- No generic developer/debug settings in the app UI.
- No backend or ephemeral-token service for v1.
- No file transcription workflow yet.

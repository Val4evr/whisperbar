# WhisperBar Source Installation Guide

These are the source installation instructions for technical users and coding agents.

Most users should install the unsigned DMG from [Releases](https://github.com/Val4evr/whisperbar/releases). Use this guide only when you want to build WhisperBar locally instead of installing a release artifact.

## Agent Instructions

If you are an AI coding agent installing WhisperBar for a user, do this end to end:

1. Confirm the user is on macOS 14 or newer.
2. Confirm Xcode command line tools are available.
3. Clone or update the repository.
4. Run the test suite.
5. Quit any currently running WhisperBar process.
6. Install the app to `/Applications/WhisperBar.app` with `Scripts/build-install.sh`.
7. Launch `/Applications/WhisperBar.app`.
8. Tell the user to add their own OpenAI API key in the menu bar panel.
9. Tell the user to choose a hotkey. Fresh installs intentionally start with no hotkey configured.
10. Tell the user to grant Microphone and Accessibility permissions to `/Applications/WhisperBar.app`.
11. Tell the user that Launch at Login is off by default unless they enable it.
12. Do not launch or permission `Build/WhisperBar.app`; that bundle is temporary.

Commands:

```sh
git clone https://github.com/Val4evr/whisperbar.git
cd whisperbar
swift test
pkill -x WhisperBar || true
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

If the user already has the repository:

```sh
cd /path/to/whisperbar
git pull
swift test
pkill -x WhisperBar || true
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

## Requirements

- macOS 14 or newer.
- Xcode command line tools.
- Swift toolchain.
- An OpenAI API key.
- Preferably an Apple Development signing identity on the local Mac.

Install Xcode command line tools:

```sh
xcode-select --install
```

Check Swift:

```sh
swift --version
```

Check signing identities:

```sh
security find-identity -v -p codesigning
```

The preferred identity looks like:

```text
Apple Development: Name (TEAMID)
```

If there is no Apple Development identity, sign into Xcode with an Apple ID and let Xcode create one:

```text
Xcode -> Settings -> Accounts
```

Then rerun:

```sh
Scripts/build-install.sh
```

For a local-only install, an ad-hoc signature can also work:

```sh
WHISPERBAR_CODESIGN_IDENTITY="-" Scripts/build-install.sh
```

Apple Development signing is preferred because it gives macOS a steadier app identity across updates.

## Permissions

Only grant permissions to:

```text
/Applications/WhisperBar.app
```

Do not grant permissions to:

```text
Build/WhisperBar.app
```

WhisperBar needs:

- **Microphone**: records dictation audio.
- **Accessibility**: sends `Cmd+V` to paste into the focused app.

Open permissions manually:

```sh
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

If the app appears more than once in the permissions list, remove the stale entries and keep the one for `/Applications/WhisperBar.app`.

## API Key

WhisperBar does not use Codex or ChatGPT auth. Each user needs their own OpenAI API key.

Add the key in the menu bar panel. After saving, the key is stored locally at:

```text
~/Library/Application Support/WhisperBar/openai.key
```

The file is written with user-only permissions.

## Hotkey

Fresh installs start with no hotkey configured. Open the menu bar panel and click `Change` to record one. The reset button fills in the suggested shortcut:

```text
Control + Option + Space
```

The hotkey is stored in the app's preferences after the user configures it.

## Updating

Update from source and reinstall the stable app path:

```sh
cd /path/to/whisperbar
git pull
swift test
pkill -x WhisperBar || true
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

As long as the app stays at `/Applications/WhisperBar.app` and is signed consistently, macOS permissions should usually survive updates.

## Creating an Unsigned DMG

Release maintainers can build a drag-to-Applications DMG with:

```sh
swift test
Scripts/package-dmg.sh
```

The output is written to:

```text
Dist/WhisperBar-<version>-unsigned.dmg
```

Upload that DMG to the matching GitHub Release. The generated app bundle is ad-hoc signed by default so macOS can run it as an app bundle, but it is not Developer ID signed or notarized. Users will still see the normal unsigned-app Gatekeeper warning on first launch.

## Troubleshooting

Check the running app:

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

If permissions keep reappearing, rebuild and relaunch only the stable app:

```sh
pkill -x WhisperBar || true
Scripts/build-install.sh
open -a /Applications/WhisperBar.app
```

If macOS still shows duplicate permission entries, remove all WhisperBar entries from Microphone and Accessibility settings, launch `/Applications/WhisperBar.app`, then grant permissions again.

## Why Source Install?

An unsigned `.app` downloaded from the internet will run into Gatekeeper warnings. An `.app` signed with someone else's Apple Development certificate is still not a proper public release artifact. The polished direct-distribution path is Developer ID signing plus Apple notarization, which requires a paid Apple Developer Program account.

For technical users, source install is useful when they want to build locally, sign locally, grant permissions locally, and keep control of their own API key.

# Codex Glass for macOS

[简体中文](README.md) | **English**

A native Swift / AppKit port of the Windows overlay, targeting macOS 13 and later without third-party runtime dependencies. The app interface is currently in Simplified Chinese. The build scripts use the current Mac's architecture; GitHub Actions builds Apple Silicon (arm64) and Intel (x64) separately. Interactive checks were performed on Apple Silicon running macOS 26; runtime behavior on older macOS versions has not been verified.

## Install

Install the official Codex CLI and sign in with ChatGPT, or use the official CLI bundled with the Codex desktop app. Do not copy account tokens into Codex Glass. Keep the Codex desktop app running for the overlay to appear.

### Build from source (recommended)

Use Xcode 26 or Apple Command Line Tools with the macOS 26 SDK. Tests require Swift 6 and Python 3. From the repository root:

```sh
./macos/test.sh
./macos/build.sh
./macos/install.sh
```

The app installs at `/Applications/Codex Glass.app`. To install without write access to that directory, use `./macos/install.sh "$HOME/Applications"`. The installer does not request administrator privileges.

### Prebuilt test packages

Open a successful run of the repository's [Build workflow](https://github.com/lunarfairy/codex-glass/actions/workflows/build.yml). Download the `CodexGlass-macos-arm64` artifact for Apple Silicon or `CodexGlass-macos-x64` for Intel. Extract the GitHub artifact ZIP, then the installation ZIP inside it if present.

Double-click `Install.command` in the fully extracted folder, or run `./install.sh` there. Use `Uninstall.command` to remove the app. Each artifact includes a SHA256 checksum; for example:

```sh
shasum -a 256 -c CodexGlass-macos-arm64.zip.sha256
```

These builds use an ad-hoc signature and are not Apple-notarized. macOS may block a downloaded build. Building locally from source is the recommended installation method; do not disable Gatekeeper. Public distribution should use Developer ID signing and notarization.

## Use

- The overlay appears while the official Codex desktop app is running and hides when it exits. Running only the CLI or a browser does not trigger it.
- The ten green segments show the remaining five-hour quota; the blue rail shows the weekly quota. The **显示五小时额度** switch also shows both percentages side by side. Turn it off to keep the larger weekly percentage. The setting is saved.
- After a valid quota response, an absent five-hour window is displayed as 100%. This is a display fallback, not confirmation of an unlimited plan. Missing weekly data remains `—`, and a failed connection does not appear as a full quota.
- Hover to see the weekly reset countdown. Drag to move the overlay; its position is saved. The hover size stays fixed during a drag. Double-click the overlay or use the menu bar icon to open settings; right-click for the menu.
- **背景不透明度** adjusts the background from 0–100% while keeping text and meters clear. Below 5%, a plain translucent surface replaces glass and window shadows to avoid visible noise. A minimum 1% input surface keeps blank areas responsive even at 0%.
- macOS 26 uses clear Liquid Glass. Earlier systems use a translucent visual-effect background.
- **登录 Mac 时自动启动** enables launch at login; it is off on first installation. Closing settings leaves the overlay running without a Dock icon.
- Quotas refresh about once a minute. Failed reads retry after 30 seconds; an orange dot marks stale data. Settings show the connection status and last update time.

## Update and remove

Build or extract a newer package and run its installer. Existing overlay position and preferences are retained.

```sh
./macos/uninstall.sh
# For a per-user installation:
./macos/uninstall.sh "$HOME/Applications"
```

Uninstalling removes Codex Glass, its login item, and its preferences. It does not remove Codex CLI, the desktop app, account configuration, or conversations.

## Diagnostics and privacy

```sh
"/Applications/Codex Glass.app/Contents/MacOS/CodexGlass" --check
codesign --verify --deep --strict "/Applications/Codex Glass.app"
```

`--check` prints quota percentages and reset times only. Codex Glass sends `initialize`, `initialized`, and `account/rateLimits/read` through the official CLI's [App Server protocol](https://learn.chatgpt.com/docs/app-server). It does not open a listening port, call a model, read `auth.json`, or access chat or project contents. The official CLI handles authentication and networking. Each query uses a short-lived subprocess with a 30-second timeout; hiding the overlay or sleeping cancels the query.

The parser selects the `codex` quota bucket, supports legacy responses, and identifies the five-hour and weekly windows by duration. Finder launches also search common Homebrew, npm, and official desktop-app locations for the native CLI executable.

## Build packages and run checks

```sh
./macos/package.sh
# Requires a logged-in graphical macOS session:
./macos/test-interaction.sh
```

Packaging writes an architecture-specific installation ZIP and `.zip.sha256` file to `macos/dist/`. The package contains the app, installation/removal scripts, bilingual documentation, and MIT license. It does not contain Codex CLI, personal preferences, or account data.

Core tests cover quota parsing, missing data, countdowns, display conditions, screen placement, protocol framing, errors, timeouts, and cancellation. The interaction check renders the real overlay using isolated preferences and asks WindowServer which window receives mouse input at low opacity and around the 5% boundary.

GitHub Actions runs core tests and creates arm64/x64 packages using macOS 26 runners. The graphical interaction check is run locally, separately from CI. The Windows implementation remains independent of the `macos/` sources.

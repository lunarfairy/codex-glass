# Codex Glass Design

## Purpose

Codex Glass is a small Windows utility that keeps Codex quota visible without routing Codex traffic through a third-party proxy. It remains hidden until the Codex desktop process is running, then shows an always-on-top floating glass bar.

## User experience

- The default surface is a 280×54 px horizontal dark-glass pill with rounded corners, a restrained border, and subtle shadow.
- The collapsed view shows two compact values: `5H 100%` and `WEEK 88%`. Percentages always mean remaining capacity.
- Hovering expands the bar vertically and reveals the reset countdown below each value.
- The window is draggable from any non-control area and persists its last valid screen position.
- A right-click menu provides `Refresh now`, `Pause display`, `Start with Windows`, and `Exit`.
- The utility starts with Windows but stays visually hidden. It shows when any Codex desktop process is present and hides after the last matching process exits.
- The first launch places the window near the upper-right work area of the primary display. Restored positions are clamped to an available monitor.

## Architecture

The application is a .NET 8 WPF executable with focused components:

- `CodexProcessWatcher` polls every two seconds and publishes whether Codex desktop is running.
- `AppServerClient` owns one `codex app-server` child process, sends newline-delimited JSON-RPC, performs `initialize`/`initialized`, and calls `account/rateLimits/read`.
- `QuotaParser` selects the account-wide Codex bucket and maps its primary and secondary windows by duration rather than array order.
- `QuotaPresenter` converts used percentage to remaining percentage, clamps values to 0–100, and formats reset countdowns.
- `QuotaRefreshService` refreshes every 60 seconds while Codex is open, serializes refreshes, keeps the last successful snapshot on transient failure, and restarts the App Server after repeated transport failures.
- `LocalSettingsStore` persists only display preferences and window geometry under `%LOCALAPPDATA%\CodexGlass\settings.json`.
- `GlassWindow` renders the floating surface and delegates logic to an application view model.

## Data flow

1. The process watcher detects Codex desktop.
2. The application shows the window and requests a refresh.
3. The App Server client starts the installed `codex` executable with `app-server` and completes the documented initialization handshake.
4. The client sends `account/rateLimits/read` with a unique request ID.
5. The parser extracts the five-hour and seven-day windows from `rateLimitsByLimitId.codex` when available, falling back to `rateLimits`.
6. The presenter publishes remaining percentages and reset countdowns to the WPF view model.
7. The window hides when Codex exits; the helper process is stopped after a short idle period.

## Privacy and security

- The utility never changes Codex's provider, base URL, proxy, model, or authentication configuration.
- It does not read or persist access tokens, prompts, source code, conversation history, or response content.
- It communicates only with the locally spawned official Codex App Server over standard input/output.
- No telemetry, updater, remote dashboard, or listening network port is included.

## Error handling

- If `codex` is missing, the bar displays `Codex CLI not found` in its expanded state and retries when Codex is next detected.
- If the account is logged out, it displays `Sign in to Codex` without opening authentication UI.
- A transient refresh failure preserves the last successful values and adds a muted stale indicator.
- Three consecutive transport failures restart the App Server once with bounded exponential backoff.
- Malformed or partial quota responses never overwrite a valid snapshot.
- Application shutdown terminates the owned App Server process and saves window geometry.

## Testing

- Unit tests cover JSON-RPC framing, initialization, response correlation, quota-window selection, percentage clamping, countdown formatting, stale-state behavior, process transitions, and position clamping.
- Integration tests use a fake line-oriented App Server process so tests never depend on a live account.
- A live smoke test calls the installed Codex App Server and verifies that a quota snapshot is rendered without exposing credentials.
- Packaging verification launches the published executable, checks a single running instance, confirms Codex-triggered visibility, and confirms clean shutdown.

## Distribution

- Publish as a self-contained Windows x64 single-file executable so no separate .NET installation is required.
- Deliver a zip containing `CodexGlass.exe`, a short README, and an uninstall script that removes only the app's startup entry and `%LOCALAPPDATA%\CodexGlass` data.
- Installation is per-user and does not require administrator privileges.

## Non-goals

- Multiple-account pooling or account switching.
- Proxying Codex requests.
- Usage history, cost accounting, charts, notifications, or remote access.
- Editing Codex configuration or credentials.

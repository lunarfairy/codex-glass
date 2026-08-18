# Codex Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, package, and install a polished Windows floating bar that appears with Codex and shows remaining five-hour and weekly quota from the official local Codex App Server.

**Architecture:** A .NET 8 WPF app separates quota parsing/presentation, Codex process detection, JSON-RPC transport, settings/startup management, and the glass window. The app starts with Windows but stays hidden until the installed Codex desktop process is detected; it never proxies Codex requests or persists credentials.

**Tech Stack:** C# 12, .NET 8 WPF, `System.Text.Json`, Windows DWM interop, xUnit, PowerShell packaging.

---

## File map

- `src/CodexGlass/CodexGlass.csproj` — WPF executable and publish settings.
- `src/CodexGlass/App.xaml(.cs)` — single-instance startup and service composition.
- `src/CodexGlass/MainWindow.xaml(.cs)` — dark glass surface, hover expansion, dragging, context menu.
- `src/CodexGlass/Models/QuotaModels.cs` — immutable quota and display records.
- `src/CodexGlass/Services/QuotaParser.cs` — official JSON response parsing and window selection.
- `src/CodexGlass/Services/QuotaPresenter.cs` — remaining percentages and countdown text.
- `src/CodexGlass/Services/AppServerClient.cs` — line-oriented JSON-RPC process client.
- `src/CodexGlass/Services/CodexLocator.cs` — installed native Codex executable discovery.
- `src/CodexGlass/Services/CodexProcessWatcher.cs` — Codex desktop presence transitions.
- `src/CodexGlass/Services/QuotaRefreshService.cs` — refresh cadence, stale state, restart policy.
- `src/CodexGlass/Services/LocalSettingsStore.cs` — per-user geometry and preferences.
- `src/CodexGlass/Services/StartupManager.cs` — per-user Run registry entry.
- `src/CodexGlass/Interop/AcrylicHelper.cs` — Windows backdrop and rounded-corner calls.
- `src/CodexGlass/ViewModels/MainViewModel.cs` — bindable UI state and commands.
- `tests/CodexGlass.Tests/*Tests.cs` — domain, transport, process, settings, and view-model tests.
- `packaging/install.ps1` — copy the published app per-user and register startup.
- `packaging/uninstall.ps1` — stop and remove only Codex Glass files/settings/startup.
- `README.md` — usage, privacy, install, and uninstall instructions.

### Task 1: Toolchain and solution scaffold

**Files:**
- Create: `CodexGlass.sln`
- Create: `src/CodexGlass/CodexGlass.csproj`
- Create: `tests/CodexGlass.Tests/CodexGlass.Tests.csproj`

- [ ] **Step 1: Install the missing .NET 8 SDK**

Run: `winget install Microsoft.DotNet.SDK.8 --exact --accept-package-agreements --accept-source-agreements --disable-interactivity`

Expected: `dotnet --list-sdks` reports an `8.0.x` SDK.

- [ ] **Step 2: Create the solution and projects**

Run:

```powershell
dotnet new sln -n CodexGlass
dotnet new wpf -n CodexGlass -o src/CodexGlass -f net8.0
dotnet new xunit -n CodexGlass.Tests -o tests/CodexGlass.Tests -f net8.0
dotnet sln add src/CodexGlass/CodexGlass.csproj tests/CodexGlass.Tests/CodexGlass.Tests.csproj
dotnet add tests/CodexGlass.Tests/CodexGlass.Tests.csproj reference src/CodexGlass/CodexGlass.csproj
```

Expected: `dotnet build CodexGlass.sln` succeeds.

- [ ] **Step 3: Set deterministic Windows publish properties**

Set `src/CodexGlass/CodexGlass.csproj` to:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <AssemblyName>CodexGlass</AssemblyName>
    <RootNamespace>CodexGlass</RootNamespace>
    <ApplicationManifest>app.manifest</ApplicationManifest>
  </PropertyGroup>
</Project>
```

- [ ] **Step 4: Commit the scaffold**

Run: `git add CodexGlass.sln src tests && git -c user.name=Codex -c user.email=codex@local commit -m "build: scaffold Codex Glass"`

### Task 2: Quota domain and presentation

**Files:**
- Create: `src/CodexGlass/Models/QuotaModels.cs`
- Create: `src/CodexGlass/Services/QuotaParser.cs`
- Create: `src/CodexGlass/Services/QuotaPresenter.cs`
- Create: `tests/CodexGlass.Tests/QuotaParserTests.cs`
- Create: `tests/CodexGlass.Tests/QuotaPresenterTests.cs`

- [ ] **Step 1: Write failing parser tests**

Tests must use a response containing `rateLimitsByLimitId.codex`, assert that 300-minute and 10080-minute windows are selected by duration, and assert fallback to `rateLimits` when the map is absent:

```csharp
[Fact]
public void Parse_SelectsFiveHourAndWeeklyWindowsByDuration()
{
    const string json = """{"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":12,"windowDurationMins":300,"resetsAt":1787050000},"secondary":{"usedPercent":34,"windowDurationMins":10080,"resetsAt":1787650000}}}}}""";
    var snapshot = QuotaParser.Parse(json);
    Assert.Equal(300, snapshot.FiveHour!.WindowMinutes);
    Assert.Equal(10080, snapshot.Weekly!.WindowMinutes);
}
```

Run: `dotnet test --filter QuotaParserTests`

Expected: compile failure because `QuotaParser` is absent.

- [ ] **Step 2: Implement immutable models and parser**

Use these public contracts:

```csharp
public sealed record QuotaWindow(double UsedPercent, int WindowMinutes, DateTimeOffset? ResetsAt);
public sealed record QuotaSnapshot(QuotaWindow? FiveHour, QuotaWindow? Weekly, DateTimeOffset UpdatedAt);
public static class QuotaParser { public static QuotaSnapshot Parse(string json); }
```

The parser accepts either a whole JSON-RPC response or the `result` object, prefers `rateLimitsByLimitId.codex`, tolerates numeric values encoded as JSON numbers, and throws `InvalidDataException` when neither five-hour nor weekly data exists.

- [ ] **Step 3: Write failing presenter tests**

```csharp
[Theory]
[InlineData(-1, 100)]
[InlineData(12, 88)]
[InlineData(150, 0)]
public void RemainingPercent_IsClamped(double used, int expected) =>
    Assert.Equal(expected, QuotaPresenter.RemainingPercent(used));
```

Also assert `4h 05m`, `2d 03h`, `Now`, and `—` countdown output using a supplied clock value.

- [ ] **Step 4: Implement the presenter and pass domain tests**

Public contracts:

```csharp
public sealed record QuotaDisplay(string FiveHourPercent, string WeeklyPercent, string FiveHourReset, string WeeklyReset);
public static class QuotaPresenter
{
    public static int RemainingPercent(double usedPercent);
    public static string FormatCountdown(DateTimeOffset? resetAt, DateTimeOffset now);
    public static QuotaDisplay Present(QuotaSnapshot snapshot, DateTimeOffset now);
}
```

Run: `dotnet test --filter "QuotaParserTests|QuotaPresenterTests"`

Expected: all domain tests pass.

- [ ] **Step 5: Commit the domain layer**

Run: `git add src/CodexGlass/Models src/CodexGlass/Services/QuotaParser.cs src/CodexGlass/Services/QuotaPresenter.cs tests && git -c user.name=Codex -c user.email=codex@local commit -m "feat: parse and present Codex quota"`

### Task 3: Process detection, settings, and startup

**Files:**
- Create: `src/CodexGlass/Services/CodexProcessWatcher.cs`
- Create: `src/CodexGlass/Services/LocalSettingsStore.cs`
- Create: `src/CodexGlass/Services/StartupManager.cs`
- Create: `tests/CodexGlass.Tests/CodexProcessWatcherTests.cs`
- Create: `tests/CodexGlass.Tests/LocalSettingsStoreTests.cs`

- [ ] **Step 1: Write failing process-classification tests**

```csharp
[Theory]
[InlineData("ChatGPT", @"C:\Program Files\WindowsApps\OpenAI.Codex_26.1_x64__id\app\ChatGPT.exe", "", true)]
[InlineData("ChatGPT", @"C:\Apps\ChatGPT.exe", "ChatGPT", false)]
[InlineData("codex", @"C:\tools\codex.exe", "", false)]
public void IsCodexDesktop_MatchesOnlyDesktopPackage(string name, string path, string title, bool expected) =>
    Assert.Equal(expected, CodexProcessWatcher.IsCodexDesktop(name, path, title));
```

This prevents the utility's own `codex app-server` child from keeping the bar visible.

- [ ] **Step 2: Implement watcher transitions**

Expose `event EventHandler<bool>? PresenceChanged`, `bool IsPresent`, `StartAsync`, and `DisposeAsync`. Poll every two seconds, catch per-process path access errors, and emit only on state changes.

- [ ] **Step 3: Write failing settings tests**

Use a temporary path and assert default values, JSON round trip, corrupt-file fallback, and screen-bound clamping. The persisted record is:

```csharp
public sealed record LocalSettings(double? Left = null, double? Top = null, bool StartWithWindows = true, bool Paused = false);
```

- [ ] **Step 4: Implement settings and startup registry management**

`StartupManager` reads/writes only `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\CodexGlass`. Quote the executable path and append `--background`. `LocalSettingsStore` writes atomically through a sibling temporary file.

Run: `dotnet test --filter "CodexProcessWatcherTests|LocalSettingsStoreTests"`

Expected: all tests pass.

- [ ] **Step 5: Commit local lifecycle support**

Run: `git add src/CodexGlass/Services tests && git -c user.name=Codex -c user.email=codex@local commit -m "feat: detect Codex and persist local settings"`

### Task 4: Official App Server client and refresh policy

**Files:**
- Create: `src/CodexGlass/Services/CodexLocator.cs`
- Create: `src/CodexGlass/Services/AppServerClient.cs`
- Create: `src/CodexGlass/Services/QuotaRefreshService.cs`
- Create: `tests/CodexGlass.Tests/AppServerClientTests.cs`
- Create: `tests/CodexGlass.Tests/QuotaRefreshServiceTests.cs`
- Create: `tests/CodexGlass.FakeServer/CodexGlass.FakeServer.csproj`
- Create: `tests/CodexGlass.FakeServer/Program.cs`

- [ ] **Step 1: Create a deterministic fake App Server**

The fake process reads JSON lines, returns an initialize response for request `0`, ignores `initialized`, and returns a fixed `account/rateLimits/read` result for later IDs. It writes protocol data only to stdout.

- [ ] **Step 2: Write failing JSON-RPC integration tests**

Assert that the client sends initialize first, correlates an out-of-order notification safely, parses the quota response, times out a missing response, and terminates the owned fake process on disposal.

- [ ] **Step 3: Implement native Codex discovery and App Server transport**

`CodexLocator` first checks a test override, then finds a running `ChatGPT.exe` whose path contains `OpenAI.Codex_` and resolves `resources\codex.exe`, then checks executable entries returned by `where.exe codex.exe`. `AppServerClient` starts the resolved executable with argument `app-server`, redirects standard streams, sends:

```json
{"method":"initialize","id":0,"params":{"clientInfo":{"name":"codex-glass","title":"Codex Glass","version":"1.0.0"}}}
{"method":"initialized","params":{}}
{"method":"account/rateLimits/read","id":1}
```

It uses a single reader loop and a request-ID dictionary so stdout can never be read concurrently.

- [ ] **Step 4: Write failing refresh-policy tests**

Assert immediate refresh on activation, 60-second scheduled refresh through a fake clock, preservation of the last snapshot on one failure, stale status after failure, and a transport restart after three consecutive failures.

- [ ] **Step 5: Implement refresh policy and pass transport tests**

Expose states `Hidden`, `Loading`, `Ready`, `Stale`, `SignedOut`, and `Unavailable`. Serialize refresh calls with `SemaphoreSlim`; never replace a valid snapshot with malformed data.

Run: `dotnet test --filter "AppServerClientTests|QuotaRefreshServiceTests"`

Expected: all transport and policy tests pass without a live account.

- [ ] **Step 6: Commit App Server integration**

Run: `git add src/CodexGlass/Services tests && git -c user.name=Codex -c user.email=codex@local commit -m "feat: read quotas from Codex App Server"`

### Task 5: Glass window and application composition

**Files:**
- Create: `src/CodexGlass/Interop/AcrylicHelper.cs`
- Create: `src/CodexGlass/ViewModels/MainViewModel.cs`
- Modify: `src/CodexGlass/App.xaml`
- Modify: `src/CodexGlass/App.xaml.cs`
- Modify: `src/CodexGlass/MainWindow.xaml`
- Modify: `src/CodexGlass/MainWindow.xaml.cs`
- Create: `src/CodexGlass/app.manifest`
- Create: `tests/CodexGlass.Tests/MainViewModelTests.cs`

- [ ] **Step 1: Write failing view-model tests**

Assert collapsed labels, loading placeholders, ready values, stale indicator, hover detail visibility, pause behavior, and refresh command invocation.

- [ ] **Step 2: Implement the bindable view model**

Use `INotifyPropertyChanged`; expose `FiveHourPercent`, `WeeklyPercent`, `FiveHourReset`, `WeeklyReset`, `StatusText`, `IsExpanded`, `IsStale`, and commands. UI mutations are marshalled to the WPF dispatcher.

- [ ] **Step 3: Implement the visual surface**

Create a borderless, non-taskbar, topmost 280×54 window. The XAML uses a `#D914161A` background, 18 px corners, a one-pixel `#26FFFFFF` border, Segoe UI Variable, restrained cyan/violet accents, and two equal quota columns. Mouse enter animates height to 92 and reset opacity to 1 over 160 ms; mouse leave reverses it. Double-clicking neither opens a dashboard nor changes Codex.

- [ ] **Step 4: Add Windows backdrop, dragging, menu, and composition**

`AcrylicHelper` applies the supported DWM rounded-corner preference and acrylic accent when available, falling back to the opaque dark surface. `MainWindow` calls `DragMove()` on left-button down and persists position on move completion. The context menu binds refresh, pause, startup toggle, and exit.

- [ ] **Step 5: Compose the app and enforce one instance**

`App` owns a named mutex, settings, watcher, client, refresh service, and window. It registers startup on first launch, shows only when Codex is present and display is not paused, stops the child process on shutdown, and brings the existing instance forward through a named event when a second instance starts.

Run: `dotnet test`

Expected: all tests pass.

- [ ] **Step 6: Commit the complete application**

Run: `git add src tests && git -c user.name=Codex -c user.email=codex@local commit -m "feat: add Codex Glass floating UI"`

### Task 6: Packaging, installation, and verification

**Files:**
- Create: `packaging/install.ps1`
- Create: `packaging/uninstall.ps1`
- Create: `README.md`
- Create: `outputs/CodexGlass.zip`

- [ ] **Step 1: Write packaging scripts**

`install.ps1` copies `CodexGlass.exe` to `%LOCALAPPDATA%\Programs\CodexGlass`, starts it, and writes the per-user startup entry. `uninstall.ps1` validates those exact paths, stops only `CodexGlass`, removes the startup value, app folder, and `%LOCALAPPDATA%\CodexGlass` settings. Both support `-WhatIf`.

- [ ] **Step 2: Publish the self-contained executable**

Run:

```powershell
dotnet publish src/CodexGlass/CodexGlass.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:DebugType=None -p:DebugSymbols=false -o outputs/CodexGlass
Compress-Archive -Path outputs/CodexGlass/CodexGlass.exe,README.md,packaging/install.ps1,packaging/uninstall.ps1 -DestinationPath outputs/CodexGlass.zip -Force
```

Expected: the zip contains exactly the executable, README, install script, and uninstall script.

- [ ] **Step 3: Run automated verification**

Run: `dotnet test -c Release` and `dotnet publish ...` again from a clean output directory.

Expected: zero test failures and a successful publish.

- [ ] **Step 4: Run a live App Server smoke test**

Launch the published executable while Codex desktop is running. Verify the process owns one `codex app-server` child, the window shows two non-placeholder remaining percentages, and hover reveals two reset labels. Verify no listening TCP port belongs to `CodexGlass`.

- [ ] **Step 5: Install and verify lifecycle behavior**

Run `packaging/install.ps1`, confirm the startup entry points to the installed executable, confirm one process instance, close Codex and verify the bar hides, reopen Codex and verify the bar returns, then confirm the saved position survives a restart.

- [ ] **Step 6: Commit deliverables**

Run: `git add README.md packaging && git -c user.name=Codex -c user.email=codex@local commit -m "build: package Codex Glass for Windows"`

## Completion evidence

- `dotnet test -c Release` passes every domain, transport, lifecycle, settings, and view-model test.
- A live `account/rateLimits/read` smoke test produces both five-hour and weekly values.
- The installed app is a single instance, has no listening port, and owns only its local App Server child.
- Runtime observation proves Codex-triggered show/hide, hover expansion, topmost behavior, drag persistence, and startup registration.
- `outputs/CodexGlass.zip` is the user-facing portable/installable deliverable.

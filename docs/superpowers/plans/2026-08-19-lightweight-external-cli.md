# Lightweight External CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish Codex Glass v1.0.2 without bundling or downloading Codex CLI, while preventing installation when the user has not installed a working CLI.

**Architecture:** The app-server launcher returns to the existing `cmd.exe /c codex app-server` pattern so Windows can resolve the user-installed CLI through PATH. The installer validates that command before touching the existing installation, then removes the old v1.0.1 `tools` directory during upgrade. The release builder publishes only Glass and the installer materials.

**Tech Stack:** .NET 8/WPF, xUnit, Windows PowerShell 5, GitHub Releases.

---

### Task 1: Restore PATH-based app-server startup

**Files:**
- Modify: `tests/CodexGlass.Tests/AppServerProcessTests.cs`
- Modify: `src/CodexGlass/AppServer/AppServerProcess.cs`
- Delete: `src/CodexGlass/AppServer/CodexCliLocator.cs`

- [ ] **Step 1: Write the failing test**

Replace the bundled-executable test with this behavior:

```csharp
[Fact]
public void CreateStartInfo_UsesHiddenRedirectedCodexAppServerFromPath()
{
    var startInfo = AppServerProcess.CreateStartInfo();

    Assert.Equal(Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe", startInfo.FileName);
    Assert.Equal(["/d", "/s", "/c", "codex app-server"], startInfo.ArgumentList);
    Assert.True(startInfo.CreateNoWindow);
    Assert.True(startInfo.RedirectStandardInput);
    Assert.True(startInfo.RedirectStandardOutput);
    Assert.True(startInfo.RedirectStandardError);
    Assert.False(startInfo.UseShellExecute);
}
```

- [ ] **Step 2: Run the focused test and confirm it fails**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore --filter FullyQualifiedName~AppServerProcessTests`

Expected: failure because the current launcher calls the bundled executable directly.

- [ ] **Step 3: Restore the minimal launcher**

Set `ProcessStartInfo.FileName` to `Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe"` and append the four argument-list entries `/d`, `/s`, `/c`, and `codex app-server`. Delete `CodexCliLocator.cs` because v1.0.2 must not look for a bundled executable.

- [ ] **Step 4: Run the focused test and confirm it passes**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore --filter FullyQualifiedName~AppServerProcessTests`

Expected: one passing launcher test.

- [ ] **Step 5: Commit the runtime change**

```powershell
git add tests/CodexGlass.Tests/AppServerProcessTests.cs src/CodexGlass/AppServer/AppServerProcess.cs src/CodexGlass/AppServer/CodexCliLocator.cs
git commit -m "feat: use user-installed Codex CLI"
```

### Task 2: Gate installation on a working external CLI

**Files:**
- Modify: `packaging/Install.ps1`

- [ ] **Step 1: Define the failing manual case**

Run the installer from a temporary copy of the package with `PATH` that contains no `codex` command. Confirm that the current installer would still copy files.

- [ ] **Step 2: Add the pre-install requirement check**

Immediately after `$ErrorActionPreference`, add this ASCII-only PowerShell logic before any process stop, file copy, registry edit, or shortcut operation:

```powershell
$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue
if ($null -eq $codexCommand) {
    throw 'Codex CLI is required. Install the official CLI from https://github.com/openai/codex, then run this installer again.'
}

$codexVersion = (& $codexCommand.Source --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $codexVersion -notmatch '(?i)codex') {
    throw 'The codex command could not be verified. Reinstall the official Codex CLI, then run this installer again.'
}
```

Set `$installedToolsDirectory = Join-Path $installDirectory 'tools'`. After stopping the installed Glass process and before `Copy-Item`, remove this exact directory when it exists, so an upgrade from v1.0.1 does not retain its old bundled CLI.

- [ ] **Step 3: Verify the missing-CLI case**

Run the package installer with `PATH` set to a directory containing no `codex`. Expected: exit code 1, the message mentions the official CLI URL, and no target app directory is created or changed.

- [ ] **Step 4: Verify a real CLI and upgrade cleanup**

Run the installer with the real `codex` command visible. Expected: exit code 0, `CodexGlass.exe` starts, and `%LOCALAPPDATA%\Programs\CodexGlass\tools` no longer exists.

- [ ] **Step 5: Commit the installer change**

```powershell
git add packaging/Install.ps1
git commit -m "feat: require external Codex CLI during install"
```

### Task 3: Build a lightweight package and update documentation

**Files:**
- Modify: `packaging/Build-Release.ps1`
- Modify: `packaging/使用说明.txt`
- Modify: `README.md`
- Modify: `src/CodexGlass/CodexGlass.csproj`
- Modify: `src/CodexGlass/AppServer/AppServerConnection.cs`
- Delete: `packaging/APACHE-2.0.txt`
- Delete: `packaging/THIRD_PARTY_NOTICES.txt`

- [ ] **Step 1: Make the release builder require no CLI parameter**

Remove `$CodexCliPath`, the CLI version execution, `app/tools` creation, and CLI copy. Keep the version parameter and publish only the .NET application. Copy only `Install.ps1`, `Uninstall.ps1`, and the two `.cmd` files plus `使用说明.txt`; do not include the former CLI license/notice files. Print the created archive path without a bundled CLI message.

- [ ] **Step 2: Update the user-facing prerequisites**

In both README and `使用说明.txt`, place the official `https://github.com/openai/codex` link before the Glass installation steps. State that the user must install the official CLI, confirm `codex --version` works, sign in to Codex Desktop, then install Glass. Remove claims that the archive includes CLI or requires no PATH configuration.

- [ ] **Step 3: Update versions and client metadata**

Set the project `Version`, `AssemblyVersion`, and `FileVersion` to `1.0.2`/`1.0.2.0`. Change app-server `clientInfo.version` to `1.0.2`.

- [ ] **Step 4: Build and inspect the archive**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File packaging\Build-Release.ps1 -Version 1.0.2`

Expected: a `CodexGlass-v1.0.2-windows-x64.zip` archive exists; its entries include `app/CodexGlass.exe` but do not include `tools/codex.exe`, `APACHE-2.0.txt`, or `THIRD_PARTY_NOTICES.txt`.

- [ ] **Step 5: Commit the release change**

```powershell
git add README.md packaging src/CodexGlass/CodexGlass.csproj src/CodexGlass/AppServer/AppServerConnection.cs
git commit -m "release: prepare lightweight external CLI package"
```

### Task 4: Full verification and release

**Files:**
- Verify: `CodexGlass.sln`
- Verify: `outputs/CodexGlass-v1.0.2-windows-x64.zip`

- [ ] **Step 1: Run the full test suite**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore`

Expected: all tests pass.

- [ ] **Step 2: Verify the actual ZIP from a Unicode path**

Extract the ZIP under a temporary directory with Chinese characters. Parse both PowerShell scripts using Windows PowerShell 5.1, run `Install.ps1` with the real CLI, then verify the installed Glass process displays a percentage and has no `tools/codex.exe`.

- [ ] **Step 3: Publish and verify GitHub Release**

Push `main`, create tag `v1.0.2`, upload the ZIP, download it back from GitHub, and compare SHA-256 values. Confirm the GitHub Actions test workflow succeeds for the tagged commit.

- [ ] **Step 4: Commit any verification-only documentation correction**

If verification reveals no correction is needed, make no additional commit. Otherwise, commit only the correction with a precise message.

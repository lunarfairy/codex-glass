# Weekly Capsule Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the installed two-value Codex Glass bar with a refined single-weekly-quota capsule and preserve all existing runtime behavior.

**Architecture:** Keep quota parsing, App Server transport, process watching, settings, and packaging intact. Narrow the view model to weekly presentation data, expose a normalized weekly progress value, and rebuild the WPF surface around the approved 176×52/82 layout.

**Tech Stack:** .NET 8, WPF/XAML, xUnit, PowerShell packaging

---

### Task 1: Lock the weekly presentation contract with tests

**Files:**
- Modify: `tests/CodexGlass.Tests/GlassLayoutTests.cs`
- Modify: `tests/CodexGlass.Tests/MainViewModelTests.cs`
- Modify: `src/CodexGlass/Presentation/GlassLayout.cs`
- Modify: `src/CodexGlass/ViewModels/MainViewModel.cs`

- [ ] **Step 1: Change the layout test to the approved dimensions**

```csharp
[Fact]
public void UsesCompactWeeklyCapsuleDimensions()
{
    Assert.Equal(176, GlassLayout.Width);
    Assert.Equal(52, GlassLayout.CollapsedHeight);
    Assert.Equal(82, GlassLayout.ExpandedHeight);
}
```

- [ ] **Step 2: Change the view-model tests to the weekly-only contract**

```csharp
[Fact]
public void Apply_FormatsWeeklyValueResetCopyAndProgress()
{
    var now = new DateTimeOffset(2026, 8, 18, 10, 0, 0, TimeSpan.Zero);
    var viewModel = new MainViewModel();
    var snapshot = new QuotaSnapshot(
        new QuotaWindow(72, now.AddHours(2)),
        new QuotaWindow(38, now.AddDays(2).AddHours(3).AddMinutes(4)));

    viewModel.Apply(snapshot, now);

    Assert.Equal("38%", viewModel.WeeklyPercent);
    Assert.Equal("2天 3小时 4分后重置", viewModel.WeeklyReset);
    Assert.Equal(0.38, viewModel.WeeklyProgress);
    Assert.False(viewModel.IsStale);
}
```

Update the stale-state test to assert only `WeeklyPercent`, `WeeklyProgress`, and `IsStale` remain unchanged after `MarkStale()`.

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```powershell
dotnet test tests\CodexGlass.Tests\CodexGlass.Tests.csproj --filter "FullyQualifiedName~GlassLayoutTests|FullyQualifiedName~MainViewModelTests"
```

Expected: failures showing the old `280/54/92` dimensions and missing `WeeklyProgress` property.

- [ ] **Step 4: Implement the weekly presentation contract**

Set `GlassLayout` constants to `176`, `52`, and `82`. In `MainViewModel`, remove five-hour presentation properties, add:

```csharp
private double _weeklyProgress;
public double WeeklyProgress { get => _weeklyProgress; private set => Set(ref _weeklyProgress, value); }
```

Update `Apply`:

```csharp
WeeklyPercent = $"{snapshot.Weekly.RemainingPercent}%";
WeeklyProgress = snapshot.Weekly.RemainingPercent / 100d;
var countdown = CountdownFormatter.Format(snapshot.Weekly.ResetsAt, now);
WeeklyReset = countdown switch
{
    "—" => "—",
    "即将重置" => countdown,
    _ => $"{countdown}后重置"
};
IsStale = false;
```

- [ ] **Step 5: Run the focused tests and verify GREEN**

Run the command from Step 3. Expected: all focused tests pass.

- [ ] **Step 6: Commit the contract change**

```powershell
git add src/CodexGlass/Presentation/GlassLayout.cs src/CodexGlass/ViewModels/MainViewModel.cs tests/CodexGlass.Tests/GlassLayoutTests.cs tests/CodexGlass.Tests/MainViewModelTests.cs
git commit -m "feat: present weekly quota only"
```

### Task 2: Rebuild the WPF capsule surface

**Files:**
- Modify: `src/CodexGlass/MainWindow.xaml`
- Modify: `packaging/使用说明.txt`

- [ ] **Step 1: Replace the two-column XAML with the single-value capsule**

Set the window dimensions to the `176×52` collapsed and `176×82` expanded contract. Use one clipped dark acrylic border with a 20 px corner radius, a diagonal `LinearGradientBrush`, a restrained translucent border, and a one-sided inner highlight.

The collapsed row must contain:

```xml
<TextBlock Text="W E E K" FontSize="8.5" FontWeight="SemiBold" Foreground="#72FFFFFF" />
<TextBlock Text="{Binding WeeklyPercent}" FontSize="26" FontWeight="SemiBold" Foreground="#FFF7F8FA" />
```

Add a 2 px progress track aligned to the lower interior edge. Bind a left-origin `ScaleTransform.ScaleX` to `WeeklyProgress`:

```xml
<Border Height="2" Background="#18FFFFFF" CornerRadius="1">
    <Border Background="#9FC9D8FF" CornerRadius="1" RenderTransformOrigin="0,0.5">
        <Border.RenderTransform>
            <ScaleTransform ScaleX="{Binding WeeklyProgress}" />
        </Border.RenderTransform>
    </Border>
</Border>
```

The expanded row contains only a centered `{Binding WeeklyReset}` text block in muted white. No five-hour controls or bindings remain.

Update the readme display description from “5 小时与 7 天剩余百分比” to “周剩余额度百分比”.

- [ ] **Step 2: Build and run the full test suite**

Run:

```powershell
dotnet test CodexGlass.sln -c Release
```

Expected: build succeeds and every test passes with zero failures.

- [ ] **Step 3: Launch the development build for a live UI smoke test**

Start `src\CodexGlass\bin\Release\net8.0-windows\CodexGlass.exe`. Verify with Windows UI Automation that the visible text contains `W E E K`, one percentage, and one reset value. Verify the window is topmost and changes from 52 to 82 logical pixels on hover.

- [ ] **Step 4: Commit the visual change**

```powershell
git add src/CodexGlass/MainWindow.xaml packaging/使用说明.txt
git commit -m "feat: refine weekly quota capsule"
```

### Task 3: Publish, install, and verify the redesigned build

**Files:**
- Replace generated binary: `outputs/CodexGlass/app/CodexGlass.exe`
- Replace generated archive: `outputs/CodexGlass.zip`

- [ ] **Step 1: Publish the self-contained executable**

Run:

```powershell
dotnet publish src\CodexGlass\CodexGlass.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=None -o work\publish
```

Expected: `work\publish\CodexGlass.exe` exists.

- [ ] **Step 2: Rebuild the user-facing package**

Copy the published executable to `outputs\CodexGlass\app\CodexGlass.exe`, keep the existing installation scripts and readme, and recreate `outputs\CodexGlass.zip` with optimal compression.

- [ ] **Step 3: Run the tested uninstall and install scripts**

Run `outputs\CodexGlass\Uninstall.ps1`, verify the installed directory, startup value, and process are removed, then run `outputs\CodexGlass\Install.ps1` and verify all three are restored.

- [ ] **Step 4: Perform the final runtime audit**

Verify:

- one installed `CodexGlass.exe` instance;
- visible capsule is topmost;
- 176×52 logical pixels collapsed and 176×82 expanded, accounting for monitor DPI;
- only one weekly percentage is visibly rendered;
- hover reveals only the weekly reset countdown;
- startup registry value points to the installed executable;
- the owned process tree has zero TCP listening ports;
- the release test suite remains fully passing;
- the package zip hash is recorded.

- [ ] **Step 5: Inspect the final diff and repository state**

Run:

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors and no uncommitted source changes.

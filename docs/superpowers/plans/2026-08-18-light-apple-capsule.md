# Light Apple Capsule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current dark weekly overlay with a light, transparent Apple-style glass capsule while preserving its behavior.

**Architecture:** Keep all data, process, settings, and installation layers unchanged. Restrict the change to layout constants, the WPF surface, and the native acrylic tint; verify the visual contract through the existing xUnit layout test and a live installed-window audit.

**Tech Stack:** .NET 8, WPF/XAML, xUnit, Windows acrylic composition, PowerShell packaging

---

### Task 1: Lock the light capsule size contract

**Files:**
- Modify: `tests/CodexGlass.Tests/GlassLayoutTests.cs`
- Modify: `src/CodexGlass/Presentation/GlassLayout.cs`

- [ ] **Step 1: Write the failing size test**

Replace the current assertions with:

```csharp
[Fact]
public void UsesLightAppleCapsuleDimensions()
{
    Assert.Equal(184, GlassLayout.Width);
    Assert.Equal(56, GlassLayout.CollapsedHeight);
    Assert.Equal(88, GlassLayout.ExpandedHeight);
}
```

- [ ] **Step 2: Verify RED**

Run:

```powershell
dotnet test tests\CodexGlass.Tests\CodexGlass.Tests.csproj --filter FullyQualifiedName~GlassLayoutTests
```

Expected: test fails because the current dimensions are 176, 52, and 82.

- [ ] **Step 3: Implement the new dimensions**

Set `GlassLayout` to:

```csharp
public const double Width = 184;
public const double CollapsedHeight = 56;
public const double ExpandedHeight = 88;
```

- [ ] **Step 4: Verify GREEN and commit**

Run the Step 2 command. Expected: one passing test.

```powershell
git add src/CodexGlass/Presentation/GlassLayout.cs tests/CodexGlass.Tests/GlassLayoutTests.cs
git commit -m "feat: size light Apple capsule"
```

### Task 2: Apply the light acrylic visual system

**Files:**
- Modify: `src/CodexGlass/MainWindow.xaml`
- Modify: `src/CodexGlass/Presentation/GlassBackdrop.cs`

- [ ] **Step 1: Change the native acrylic tint**

Replace the dark acrylic color with the pale neutral tint:

```csharp
GradientColor = unchecked((int)0xA6F8F8F8)
```

- [ ] **Step 2: Rebuild the XAML surface**

Set the window to `184×56` collapsed and `184×88` expanded. Use one 28 px rounded surface with this pale translucent gradient:

```xml
<LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
    <GradientStop Color="#BFFDFEFF" Offset="0" />
    <GradientStop Color="#9BEAF0F7" Offset="0.55" />
    <GradientStop Color="#A6DDE6F0" Offset="1" />
</LinearGradientBrush>
```

Use a `#78FFFFFF` one-pixel rim and `#8CFFFFFF` top inner highlight. Set the label to `#7C364152`, percentage to `#FF172033`, reset text to `#A63D4A5C`, progress track to `#24334152`, and progress fill to `#B45F8EFF`. Retain one weekly percentage and one reset text binding; retain the `ScaleTransform` binding to `WeeklyProgress`.

- [ ] **Step 3: Run the full release suite**

Run:

```powershell
dotnet test CodexGlass.sln -c Release
```

Expected: all tests pass with zero failures.

- [ ] **Step 4: Commit the material change**

```powershell
git add src/CodexGlass/MainWindow.xaml src/CodexGlass/Presentation/GlassBackdrop.cs
git commit -m "feat: add light acrylic capsule surface"
```

### Task 3: Publish and install the light capsule

**Files:**
- Replace generated binary: `outputs/CodexGlass/app/CodexGlass.exe`
- Replace generated archive: `outputs/CodexGlass.zip`

- [ ] **Step 1: Publish the self-contained executable**

```powershell
dotnet publish src\CodexGlass\CodexGlass.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=None -o work\publish
```

- [ ] **Step 2: Rebuild the user package**

Copy `work\publish\CodexGlass.exe` to `outputs\CodexGlass\app\CodexGlass.exe` and recreate `outputs\CodexGlass.zip` from the existing package folder.

- [ ] **Step 3: Reinstall and audit the live app**

Run the existing `outputs\CodexGlass\Uninstall.ps1` and `Install.ps1`. Verify one installed process, one visible weekly percentage, topmost state, 184×56 collapsed and 184×88 expanded logical dimensions after accounting for display scale, startup registration, no TCP listening ports, and a package hash.

- [ ] **Step 4: Final checks**

```powershell
dotnet test CodexGlass.sln -c Release --no-restore
git diff --check
git status --short
```

Expected: all tests pass, no whitespace errors, and no uncommitted source changes.

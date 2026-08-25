# Five-hour Segmented Meter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a green ten-segment five-hour quota meter above the existing blue weekly meter.

**Architecture:** `MainViewModel` turns the already-parsed five-hour percentage into ten immutable Boolean values. The WPF view renders those values as evenly spaced rounded bars, while the existing weekly track and hover countdown stay unchanged.

**Tech Stack:** .NET 8, WPF/XAML, xUnit.

---

### Task 1: Expose five-hour segment state

**Files:**
- Modify: `tests/CodexGlass.Tests/MainViewModelTests.cs`
- Modify: `src/CodexGlass/ViewModels/MainViewModel.cs`

- [x] **Step 1: Write failing mapping tests**

Add this theory to `MainViewModelTests`:

```csharp
[Theory]
[InlineData(0, 0)]
[InlineData(38, 4)]
[InlineData(100, 10)]
public void Apply_MapsFiveHourRemainingQuotaToTenSegments(int remainingPercent, int filledSegments)
{
    var viewModel = new MainViewModel();
    var snapshot = new QuotaSnapshot(
        new QuotaWindow(remainingPercent, null),
        new QuotaWindow(50, null));

    viewModel.Apply(snapshot, DateTimeOffset.UtcNow);

    Assert.Equal(10, viewModel.FiveHourSegments.Count);
    Assert.Equal(filledSegments, viewModel.FiveHourSegments.Count(segment => segment));
}
```

- [x] **Step 2: Run the focused test and confirm it fails**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore --filter FullyQualifiedName~MainViewModelTests`

Expected: compilation failure because `FiveHourSegments` does not exist.

- [x] **Step 3: Implement the minimal view-model state**

Add this property and backing field to `MainViewModel`:

```csharp
private IReadOnlyList<bool> _fiveHourSegments = Enumerable.Repeat(false, 10).ToArray();
public IReadOnlyList<bool> FiveHourSegments { get => _fiveHourSegments; private set => Set(ref _fiveHourSegments, value); }
```

At the beginning of `Apply`, calculate the filled count and replace the list:

```csharp
var fiveHourFilledSegments = Math.Clamp(
    (int)Math.Round(snapshot.FiveHour.RemainingPercent / 10d, MidpointRounding.AwayFromZero),
    0,
    10);
FiveHourSegments = Enumerable.Range(0, 10).Select(index => index < fiveHourFilledSegments).ToArray();
```

- [x] **Step 4: Run the focused test and confirm it passes**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore --filter FullyQualifiedName~MainViewModelTests`

Expected: all view-model tests pass.

- [x] **Step 5: Commit the data mapping**

```powershell
git add tests/CodexGlass.Tests/MainViewModelTests.cs src/CodexGlass/ViewModels/MainViewModel.cs
git commit -m "feat: map five-hour quota to segments"
```

### Task 2: Render the green segmented meter

**Files:**
- Modify: `src/CodexGlass/MainWindow.xaml`

- [x] **Step 1: Add the five-hour ItemsControl**

Inside the collapsed `Grid` that currently contains the weekly blue `Border`, add an `ItemsControl` above that border:

```xml
<ItemsControl ItemsSource="{Binding FiveHourSegments}"
              Height="3"
              Margin="0,0,0,14"
              VerticalAlignment="Bottom">
    <ItemsControl.ItemsPanel>
        <ItemsPanelTemplate>
            <UniformGrid Columns="10" />
        </ItemsPanelTemplate>
    </ItemsControl.ItemsPanel>
    <ItemsControl.ItemTemplate>
        <DataTemplate>
            <Border Margin="0,0,2,0" CornerRadius="1.5">
                <Border.Style>
                    <Style TargetType="Border">
                        <Setter Property="Background" Value="#24334152" />
                        <Style.Triggers>
                            <DataTrigger Binding="{Binding}" Value="True">
                                <Setter Property="Background" Value="#B34FBF7A" />
                            </DataTrigger>
                        </Style.Triggers>
                    </Style>
                </Border.Style>
            </Border>
        </DataTemplate>
    </ItemsControl.ItemTemplate>
</ItemsControl>
```

Keep the blue weekly `Border` below it and move its bottom margin to `6` so both bars fit in the existing 56-pixel collapsed region.

- [x] **Step 2: Build the WPF project**

Run: `dotnet build src\CodexGlass\CodexGlass.csproj --configuration Release --no-restore`

Expected: build succeeds without XAML errors.

- [x] **Step 3: Run all tests and inspect the running overlay**

Run: `dotnet test CodexGlass.sln --configuration Release --no-restore`

Then start Codex Glass locally and inspect that the weekly percentage and countdown still appear; visually confirm the green line has ten segments above the blue line.

- [ ] **Step 4: Commit the visual meter**

```powershell
git add src/CodexGlass/MainWindow.xaml
git commit -m "feat: display five-hour segmented quota meter"
```

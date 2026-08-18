using CodexGlass.Quota;
using CodexGlass.ViewModels;

namespace CodexGlass.Tests;

public sealed class MainViewModelTests
{
    [Fact]
    public void Apply_FormatsPercentagesAndResetCountdowns()
    {
        var now = new DateTimeOffset(2026, 8, 18, 10, 0, 0, TimeSpan.Zero);
        var viewModel = new MainViewModel();
        var snapshot = new QuotaSnapshot(
            new QuotaWindow(72, now.AddHours(2).AddMinutes(14)),
            new QuotaWindow(38, now.AddDays(2).AddHours(3).AddMinutes(4)));

        viewModel.Apply(snapshot, now);

        Assert.Equal("72%", viewModel.FiveHourPercent);
        Assert.Equal("38%", viewModel.WeeklyPercent);
        Assert.Equal("2小时 14分", viewModel.FiveHourReset);
        Assert.Equal("2天 3小时 4分", viewModel.WeeklyReset);
        Assert.False(viewModel.IsStale);
    }

    [Fact]
    public void MarkStale_PreservesLastKnownPercentages()
    {
        var viewModel = new MainViewModel();
        viewModel.Apply(
            new QuotaSnapshot(new QuotaWindow(80, null), new QuotaWindow(55, null)),
            DateTimeOffset.UtcNow);

        viewModel.MarkStale();

        Assert.Equal("80%", viewModel.FiveHourPercent);
        Assert.Equal("55%", viewModel.WeeklyPercent);
        Assert.True(viewModel.IsStale);
    }
}

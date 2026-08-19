using CodexGlass.Quota;
using CodexGlass.ViewModels;

namespace CodexGlass.Tests;

public sealed class MainViewModelTests
{
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

    [Fact]
    public void MarkStale_PreservesLastKnownWeeklyValue()
    {
        var viewModel = new MainViewModel();
        viewModel.Apply(
            new QuotaSnapshot(new QuotaWindow(80, null), new QuotaWindow(55, null)),
            DateTimeOffset.UtcNow);

        viewModel.MarkStale();

        Assert.Equal("55%", viewModel.WeeklyPercent);
        Assert.Equal(0.55, viewModel.WeeklyProgress);
        Assert.True(viewModel.IsStale);
    }

    [Fact]
    public void MarkUnavailable_ExplainsHowToRecoverWhenNoQuotaWasLoaded()
    {
        var viewModel = new MainViewModel();

        viewModel.MarkUnavailable();

        Assert.Equal("—", viewModel.WeeklyPercent);
        Assert.Equal("请先登录 Codex", viewModel.WeeklyReset);
        Assert.True(viewModel.IsStale);
    }
}

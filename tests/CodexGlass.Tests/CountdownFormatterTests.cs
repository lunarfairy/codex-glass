using CodexGlass.Quota;

namespace CodexGlass.Tests;

public sealed class CountdownFormatterTests
{
    [Fact]
    public void Format_UsesDaysHoursAndMinutesForWeeklyWindow()
    {
        var now = new DateTimeOffset(2026, 8, 18, 10, 0, 0, TimeSpan.Zero);

        var text = CountdownFormatter.Format(now.AddDays(2).AddHours(3).AddMinutes(4), now);

        Assert.Equal("2天 3小时 4分", text);
    }

    [Fact]
    public void Format_UsesHoursAndMinutesForShortWindow()
    {
        var now = new DateTimeOffset(2026, 8, 18, 10, 0, 0, TimeSpan.Zero);

        Assert.Equal("2小时 14分", CountdownFormatter.Format(now.AddHours(2).AddMinutes(14), now));
    }

    [Fact]
    public void Format_ReturnsPendingWhenResetHasPassed()
    {
        var now = new DateTimeOffset(2026, 8, 18, 10, 0, 0, TimeSpan.Zero);

        Assert.Equal("即将重置", CountdownFormatter.Format(now.AddSeconds(-1), now));
    }

    [Fact]
    public void Format_ReturnsDashWhenResetIsUnknown()
    {
        Assert.Equal("—", CountdownFormatter.Format(null, DateTimeOffset.UtcNow));
    }
}

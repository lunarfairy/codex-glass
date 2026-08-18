namespace CodexGlass.Quota;

public static class CountdownFormatter
{
    public static string Format(DateTimeOffset? resetsAt, DateTimeOffset now)
    {
        if (resetsAt is null)
        {
            return "—";
        }

        var remaining = resetsAt.Value - now;
        if (remaining <= TimeSpan.Zero)
        {
            return "即将重置";
        }

        var minutes = (int)Math.Ceiling(remaining.TotalMinutes);
        var days = minutes / 1440;
        var hours = minutes % 1440 / 60;
        var minutePart = minutes % 60;

        return days > 0
            ? $"{days}天 {hours}小时 {minutePart}分"
            : $"{hours}小时 {minutePart}分";
    }
}

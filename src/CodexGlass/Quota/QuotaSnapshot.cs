namespace CodexGlass.Quota;

public sealed record QuotaWindow(int RemainingPercent, DateTimeOffset? ResetsAt);

public sealed record QuotaSnapshot(QuotaWindow FiveHour, QuotaWindow Weekly);

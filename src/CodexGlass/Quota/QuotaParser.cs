using System.IO;
using System.Text.Json;

namespace CodexGlass.Quota;

public static class QuotaParser
{
    public static QuotaSnapshot Parse(string json)
    {
        using var document = JsonDocument.Parse(json);
        var result = document.RootElement.GetProperty("result");
        var limits = SelectLimits(result);

        QuotaWindow? fiveHour = null;
        QuotaWindow? weekly = null;

        foreach (var property in limits.EnumerateObject())
        {
            var value = property.Value;
            if (value.ValueKind != JsonValueKind.Object ||
                !value.TryGetProperty("windowDurationMins", out var durationElement))
            {
                continue;
            }

            var quota = ParseWindow(value);
            switch (durationElement.GetInt32())
            {
                case 300:
                    fiveHour = quota;
                    break;
                case 10080:
                    weekly = quota;
                    break;
            }
        }

        if (weekly is null)
        {
            throw new InvalidDataException("The response did not include the weekly Codex limit.");
        }

        return new QuotaSnapshot(fiveHour ?? new QuotaWindow(100, null), weekly);
    }

    private static JsonElement SelectLimits(JsonElement result)
    {
        if (result.TryGetProperty("rateLimitsByLimitId", out var byId) &&
            byId.TryGetProperty("codex", out var codex))
        {
            return codex;
        }

        return result.GetProperty("rateLimits");
    }

    private static QuotaWindow ParseWindow(JsonElement window)
    {
        var usedPercent = window.GetProperty("usedPercent").GetDouble();
        var remaining = (int)Math.Round(100 - usedPercent, MidpointRounding.AwayFromZero);
        remaining = Math.Clamp(remaining, 0, 100);

        DateTimeOffset? resetsAt = null;
        if (window.TryGetProperty("resetsAt", out var reset) && reset.ValueKind == JsonValueKind.Number)
        {
            resetsAt = DateTimeOffset.FromUnixTimeSeconds(reset.GetInt64());
        }

        return new QuotaWindow(remaining, resetsAt);
    }
}

using CodexGlass.Quota;

namespace CodexGlass.Tests;

public sealed class QuotaParserTests
{
    [Fact]
    public void Parse_SelectsFiveHourAndWeeklyWindowsByDuration()
    {
        const string json = """
        {
          "result": {
            "rateLimitsByLimitId": {
              "codex": {
                "primary": { "usedPercent": 28.4, "windowDurationMins": 300, "resetsAt": 1787040000 },
                "secondary": { "usedPercent": 61.6, "windowDurationMins": 10080, "resetsAt": 1787472000 }
              }
            }
          }
        }
        """;

        var snapshot = QuotaParser.Parse(json);

        Assert.Equal(72, snapshot.FiveHour.RemainingPercent);
        Assert.Equal(38, snapshot.Weekly.RemainingPercent);
        Assert.Equal(DateTimeOffset.FromUnixTimeSeconds(1787040000), snapshot.FiveHour.ResetsAt);
        Assert.Equal(DateTimeOffset.FromUnixTimeSeconds(1787472000), snapshot.Weekly.ResetsAt);
    }

    [Fact]
    public void Parse_FallsBackToTopLevelRateLimits()
    {
        const string json = """
        {
          "result": {
            "rateLimits": {
              "primary": { "usedPercent": 0, "windowDurationMins": 300, "resetsAt": null },
              "secondary": { "usedPercent": 100, "windowDurationMins": 10080, "resetsAt": 1787472000 }
            }
          }
        }
        """;

        var snapshot = QuotaParser.Parse(json);

        Assert.Equal(100, snapshot.FiveHour.RemainingPercent);
        Assert.Null(snapshot.FiveHour.ResetsAt);
        Assert.Equal(0, snapshot.Weekly.RemainingPercent);
    }

    [Theory]
    [InlineData(-12, 100)]
    [InlineData(110, 0)]
    public void Parse_ClampsRemainingPercent(double usedPercent, int expectedRemaining)
    {
        var json = $$"""
        {
          "result": {
            "rateLimits": {
              "primary": { "usedPercent": {{usedPercent}}, "windowDurationMins": 300 },
              "secondary": { "usedPercent": 0, "windowDurationMins": 10080 }
            }
          }
        }
        """;

        Assert.Equal(expectedRemaining, QuotaParser.Parse(json).FiveHour.RemainingPercent);
    }

    [Fact]
    public void Parse_TreatsMissingFiveHourWindowAsFullyAvailable()
    {
        const string json = """{"result":{"rateLimits":{"primary":{"usedPercent":26,"windowDurationMins":10080,"resetsAt":1787642831},"secondary":null}}}""";

        var snapshot = QuotaParser.Parse(json);

        Assert.Equal(100, snapshot.FiveHour.RemainingPercent);
        Assert.Null(snapshot.FiveHour.ResetsAt);
        Assert.Equal(74, snapshot.Weekly.RemainingPercent);
    }

    [Fact]
    public void Parse_RejectsResponseWithoutWeeklyWindow()
    {
        const string json = """{"result":{"rateLimits":{"primary":{"usedPercent":20,"windowDurationMins":300}}}}""";

        var error = Assert.Throws<InvalidDataException>(() => QuotaParser.Parse(json));

        Assert.Contains("weekly", error.Message);
    }
}

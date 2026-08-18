using System.Text.Json;
using CodexGlass.AppServer;

namespace CodexGlass.Tests;

public sealed class AppServerConnectionTests
{
    [Fact]
    public async Task InitializeAndRead_WritesProtocolMessagesAndSkipsNotifications()
    {
        const string responses = """
        {"id":0,"result":{"userAgent":"Codex Desktop/0.143.0"}}
        {"method":"account/rateLimits/updated","params":{}}
        {"id":1,"result":{"rateLimits":{"primary":{"usedPercent":26,"windowDurationMins":10080,"resetsAt":1787642831},"secondary":null}}}
        """;
        using var input = new StringReader(responses);
        using var output = new StringWriter();
        var connection = new AppServerConnection(input, output);

        await connection.InitializeAsync(CancellationToken.None);
        var json = await connection.ReadRateLimitsAsync(CancellationToken.None);

        Assert.Contains("\"usedPercent\":26", json);
        var messages = output.ToString().Split(Environment.NewLine, StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(3, messages.Length);
        Assert.Equal("initialize", JsonDocument.Parse(messages[0]).RootElement.GetProperty("method").GetString());
        Assert.Equal("initialized", JsonDocument.Parse(messages[1]).RootElement.GetProperty("method").GetString());
        Assert.Equal("account/rateLimits/read", JsonDocument.Parse(messages[2]).RootElement.GetProperty("method").GetString());
    }

    [Fact]
    public async Task ReadRateLimits_ThrowsWhenServerReturnsAnError()
    {
        const string responses = """
        {"id":0,"result":{}}
        {"id":1,"error":{"code":-32603,"message":"not signed in"}}
        """;
        using var input = new StringReader(responses);
        using var output = new StringWriter();
        var connection = new AppServerConnection(input, output);
        await connection.InitializeAsync(CancellationToken.None);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(
            () => connection.ReadRateLimitsAsync(CancellationToken.None));

        Assert.Contains("not signed in", error.Message);
    }
}

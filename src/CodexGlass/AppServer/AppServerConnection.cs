using System.IO;
using System.Text.Json;

namespace CodexGlass.AppServer;

public sealed class AppServerConnection(TextReader input, TextWriter output)
{
    public async Task InitializeAsync(CancellationToken cancellationToken)
    {
        await SendAsync(new
        {
            method = "initialize",
            id = 0,
            @params = new
            {
                clientInfo = new { name = "codex-glass", title = "Codex Glass", version = "1.0.0" }
            }
        }, cancellationToken);
        await ReadResponseAsync(0, cancellationToken);
        await SendAsync(new { method = "initialized", @params = new { } }, cancellationToken);
    }

    public async Task<string> ReadRateLimitsAsync(CancellationToken cancellationToken)
    {
        await SendAsync(new { method = "account/rateLimits/read", id = 1 }, cancellationToken);
        return await ReadResponseAsync(1, cancellationToken);
    }

    private async Task SendAsync<T>(T message, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        await output.WriteLineAsync(JsonSerializer.Serialize(message));
        await output.FlushAsync(cancellationToken);
    }

    private async Task<string> ReadResponseAsync(int expectedId, CancellationToken cancellationToken)
    {
        while (true)
        {
            var line = await input.ReadLineAsync(cancellationToken);
            if (line is null)
            {
                throw new EndOfStreamException("Codex app-server closed before returning a response.");
            }

            using var document = JsonDocument.Parse(line);
            var root = document.RootElement;
            if (!root.TryGetProperty("id", out var id) || id.GetInt32() != expectedId)
            {
                continue;
            }

            if (root.TryGetProperty("error", out var error))
            {
                var message = error.TryGetProperty("message", out var value) ? value.GetString() : error.GetRawText();
                throw new InvalidOperationException($"Codex app-server error: {message}");
            }

            return line;
        }
    }
}

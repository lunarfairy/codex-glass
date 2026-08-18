using System.Diagnostics;
using CodexGlass.Quota;

namespace CodexGlass.AppServer;

public sealed class AppServerProcess : IAsyncDisposable
{
    private readonly Process _process;
    private readonly AppServerConnection _connection;
    private readonly Task<string> _stderr;

    private AppServerProcess(Process process)
    {
        _process = process;
        _connection = new AppServerConnection(process.StandardOutput, process.StandardInput);
        _stderr = process.StandardError.ReadToEndAsync();
    }

    public static ProcessStartInfo CreateStartInfo()
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe",
            UseShellExecute = false,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        startInfo.ArgumentList.Add("/d");
        startInfo.ArgumentList.Add("/s");
        startInfo.ArgumentList.Add("/c");
        startInfo.ArgumentList.Add("codex app-server");
        return startInfo;
    }

    public static async Task<AppServerProcess> StartAsync(CancellationToken cancellationToken)
    {
        var process = Process.Start(CreateStartInfo())
            ?? throw new InvalidOperationException("Could not start Codex app-server.");
        var server = new AppServerProcess(process);

        try
        {
            await server._connection.InitializeAsync(cancellationToken);
            return server;
        }
        catch
        {
            await server.DisposeAsync();
            throw;
        }
    }

    public async Task<QuotaSnapshot> ReadQuotaAsync(CancellationToken cancellationToken)
    {
        var response = await _connection.ReadRateLimitsAsync(cancellationToken);
        return QuotaParser.Parse(response);
    }

    public async ValueTask DisposeAsync()
    {
        if (!_process.HasExited)
        {
            _process.Kill(entireProcessTree: true);
        }

        await _process.WaitForExitAsync();
        await _stderr;
        _process.Dispose();
    }
}

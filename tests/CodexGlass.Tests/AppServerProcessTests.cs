using CodexGlass.AppServer;

namespace CodexGlass.Tests;

public sealed class AppServerProcessTests
{
    [Fact]
    public void CreateStartInfo_UsesHiddenRedirectedCodexAppServerFromPath()
    {
        var startInfo = AppServerProcess.CreateStartInfo();

        Assert.Equal(Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe", startInfo.FileName);
        Assert.Equal(["/d", "/s", "/c", "codex app-server"], startInfo.ArgumentList);
        Assert.True(startInfo.CreateNoWindow);
        Assert.True(startInfo.RedirectStandardInput);
        Assert.True(startInfo.RedirectStandardOutput);
        Assert.True(startInfo.RedirectStandardError);
        Assert.False(startInfo.UseShellExecute);
    }
}

using CodexGlass.AppServer;

namespace CodexGlass.Tests;

public sealed class AppServerProcessTests
{
    [Fact]
    public void ResolveExecutablePath_PrefersBundledCodexCli()
    {
        var directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"));
        var bundledCli = Path.Combine(directory, "tools", "codex.exe");
        Directory.CreateDirectory(Path.GetDirectoryName(bundledCli)!);
        File.WriteAllText(bundledCli, string.Empty);

        try
        {
            Assert.Equal(bundledCli, CodexCliLocator.ResolveExecutablePath(directory));
        }
        finally
        {
            Directory.Delete(directory, recursive: true);
        }
    }

    [Fact]
    public void CreateStartInfo_UsesBundledCliDirectlyWithHiddenRedirectedAppServer()
    {
        var executablePath = @"C:\CodexGlass\tools\codex.exe";
        var startInfo = AppServerProcess.CreateStartInfo(executablePath);

        Assert.Equal(executablePath, startInfo.FileName);
        Assert.Equal(["app-server"], startInfo.ArgumentList);
        Assert.True(startInfo.CreateNoWindow);
        Assert.True(startInfo.RedirectStandardInput);
        Assert.True(startInfo.RedirectStandardOutput);
        Assert.True(startInfo.RedirectStandardError);
        Assert.False(startInfo.UseShellExecute);
    }
}

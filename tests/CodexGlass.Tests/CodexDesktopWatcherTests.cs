using CodexGlass.Desktop;

namespace CodexGlass.Tests;

public sealed class CodexDesktopWatcherTests
{
    [Fact]
    public void IsRunning_ReturnsTrueWhenPackagedCodexShellExists()
    {
        var processes = new[]
        {
            new DesktopProcess("ChatGPT", @"C:\Program Files\WindowsApps\OpenAI.ChatGPT_1.0\app\ChatGPT.exe", "ChatGPT"),
            new DesktopProcess("ChatGPT", @"C:\Program Files\WindowsApps\OpenAI.Codex_1.0\app\ChatGPT.exe", "Codex")
        };
        var watcher = new CodexDesktopWatcher(() => processes);

        Assert.True(watcher.IsRunning());
    }

    [Fact]
    public void IsRunning_ReturnsFalseWithoutCodexShell()
    {
        var watcher = new CodexDesktopWatcher(() =>
            [new DesktopProcess("ChatGPT", @"C:\Program Files\WindowsApps\OpenAI.ChatGPT_1.0\app\ChatGPT.exe", "ChatGPT")]);

        Assert.False(watcher.IsRunning());
    }
}

using CodexGlass.Desktop;

namespace CodexGlass.Tests;

public sealed class CodexProcessMatcherTests
{
    [Fact]
    public void MatchesPackagedCodexDesktopProcess()
    {
        const string path = @"C:\Program Files\WindowsApps\OpenAI.Codex_26.814.5167.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe";

        Assert.True(CodexProcessMatcher.IsCodexDesktop("ChatGPT", path, "Codex"));
    }

    [Theory]
    [InlineData("ChatGPT", @"C:\Program Files\WindowsApps\OpenAI.ChatGPT_1.0\app\ChatGPT.exe", "ChatGPT")]
    [InlineData("codex", @"C:\Program Files\WindowsApps\OpenAI.Codex_1.0\app\resources\codex.exe", "")]
    [InlineData("ChatGPT", null, "ChatGPT")]
    public void RejectsProcessesThatAreNotTheCodexDesktopShell(string name, string? path, string title)
    {
        Assert.False(CodexProcessMatcher.IsCodexDesktop(name, path, title));
    }

    [Fact]
    public void MatchesCodexTitleWhenPackagedPathCannotBeRead()
    {
        Assert.True(CodexProcessMatcher.IsCodexDesktop("ChatGPT", null, "Codex"));
    }
}

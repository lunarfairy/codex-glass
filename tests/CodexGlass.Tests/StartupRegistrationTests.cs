using CodexGlass.Configuration;

namespace CodexGlass.Tests;

public sealed class StartupRegistrationTests
{
    [Fact]
    public void BuildCommand_QuotesExecutablePath()
    {
        Assert.Equal(
            "\"C:\\Program Files\\Codex Glass\\CodexGlass.exe\" --background",
            StartupRegistration.BuildCommand(@"C:\Program Files\Codex Glass\CodexGlass.exe"));
    }
}

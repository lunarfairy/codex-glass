namespace CodexGlass.Desktop;

public static class CodexProcessMatcher
{
    public static bool IsCodexDesktop(string processName, string? executablePath, string windowTitle)
    {
        if (!processName.Equals("ChatGPT", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (!string.IsNullOrWhiteSpace(executablePath))
        {
            return executablePath.Contains("\\OpenAI.Codex_", StringComparison.OrdinalIgnoreCase);
        }

        return windowTitle.Equals("Codex", StringComparison.OrdinalIgnoreCase);
    }
}

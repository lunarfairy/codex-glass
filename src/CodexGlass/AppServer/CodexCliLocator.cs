using System.IO;

namespace CodexGlass.AppServer;

public static class CodexCliLocator
{
    private const string RelativeBundledCliPath = "tools\\codex.exe";

    public static string ResolveExecutablePath(string baseDirectory)
    {
        var bundledCli = Path.Combine(baseDirectory, RelativeBundledCliPath);
        return File.Exists(bundledCli) ? bundledCli : "codex";
    }
}

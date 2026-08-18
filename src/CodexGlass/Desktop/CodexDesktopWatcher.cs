using System.Diagnostics;

namespace CodexGlass.Desktop;

public sealed record DesktopProcess(string Name, string? ExecutablePath, string WindowTitle);

public sealed class CodexDesktopWatcher
{
    private readonly Func<IEnumerable<DesktopProcess>> _processes;

    public CodexDesktopWatcher() : this(ReadProcesses)
    {
    }

    public CodexDesktopWatcher(Func<IEnumerable<DesktopProcess>> processes)
    {
        _processes = processes;
    }

    public bool IsRunning() => _processes().Any(process =>
        CodexProcessMatcher.IsCodexDesktop(process.Name, process.ExecutablePath, process.WindowTitle));

    private static IEnumerable<DesktopProcess> ReadProcesses()
    {
        foreach (var process in Process.GetProcessesByName("ChatGPT").Concat(Process.GetProcessesByName("codex")))
        {
            using (process)
            {
                string? path = null;
                try
                {
                    path = process.MainModule?.FileName;
                }
                catch
                {
                    // Packaged apps can deny access; the window title is the verified fallback.
                }

                yield return new DesktopProcess(process.ProcessName, path, process.MainWindowTitle);
            }
        }
    }
}

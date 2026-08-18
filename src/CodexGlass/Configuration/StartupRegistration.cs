using Microsoft.Win32;

namespace CodexGlass.Configuration;

public static class StartupRegistration
{
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "CodexGlass";

    public static string BuildCommand(string executablePath) => $"\"{executablePath}\" --background";

    public static void Ensure(string executablePath)
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKey, writable: true)
            ?? Registry.CurrentUser.CreateSubKey(RunKey, writable: true);
        key.SetValue(ValueName, BuildCommand(executablePath));
    }
}

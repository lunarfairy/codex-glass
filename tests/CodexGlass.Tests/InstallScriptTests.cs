using System.Diagnostics;

namespace CodexGlass.Tests;

public sealed class InstallScriptTests
{
    [Fact]
    public async Task InstallScript_StopsBeforeInstalling_WhenCodexCliIsMissing()
    {
        var directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"));
        var sourceDirectory = Path.Combine(directory, "app");
        Directory.CreateDirectory(sourceDirectory);
        await File.WriteAllTextAsync(Path.Combine(sourceDirectory, "CodexGlass.exe"), string.Empty);
        File.Copy(
            Path.Combine(AppContext.BaseDirectory, "packaging", "Install.ps1"),
            Path.Combine(directory, "Install.ps1"));

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.SystemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe"),
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            startInfo.ArgumentList.Add("-NoProfile");
            startInfo.ArgumentList.Add("-ExecutionPolicy");
            startInfo.ArgumentList.Add("Bypass");
            startInfo.ArgumentList.Add("-File");
            startInfo.ArgumentList.Add(Path.Combine(directory, "Install.ps1"));
            startInfo.Environment["PATH"] = directory;

            using var process = Process.Start(startInfo)!;
            var output = await process.StandardOutput.ReadToEndAsync();
            var error = await process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();

            Assert.NotEqual(0, process.ExitCode);
            Assert.Contains("Codex CLI is required", output + error);
            Assert.False(Directory.Exists(Path.Combine(directory, "Programs", "CodexGlass")));
        }
        finally
        {
            Directory.Delete(directory, recursive: true);
        }
    }
}

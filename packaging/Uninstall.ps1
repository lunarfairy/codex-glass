$ErrorActionPreference = 'Stop'

$programsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
$installDirectory = [IO.Path]::GetFullPath((Join-Path $programsDirectory 'CodexGlass'))
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$settingsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'CodexGlass'))

function Remove-DirectoryWhenUnlocked([string] $path) {
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (Test-Path -LiteralPath $path) {
        try {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
        }
        catch [UnauthorizedAccessException] {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

if (-not $installDirectory.StartsWith($programsDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($installDirectory) -ne 'CodexGlass') {
    throw '卸载路径校验失败，未删除任何文件。'
}

Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'CodexGlass' -ErrorAction SilentlyContinue

$installedProcesses = @(Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
})
if ($installedProcesses.Count -gt 0) {
    $installedProcesses | Stop-Process -Force
    $installedProcesses | Wait-Process -Timeout 10
}

if (Test-Path -LiteralPath $installDirectory) {
    Remove-DirectoryWhenUnlocked $installDirectory
}

if ($settingsDirectory -eq [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'CodexGlass')) -and
    (Test-Path -LiteralPath $settingsDirectory)) {
    Remove-DirectoryWhenUnlocked $settingsDirectory
}

Write-Host 'Codex Glass 已完全卸载。' -ForegroundColor Green

$ErrorActionPreference = 'Stop'

$programsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
$installDirectory = [IO.Path]::GetFullPath((Join-Path $programsDirectory 'CodexGlass'))
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$settingsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'CodexGlass'))
$shortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Codex Glass.lnk'
$legacyShortcutName = 'Codex Glass ' + [char]0x63A7 + [char]0x5236 + [char]0x53F0 + '.lnk'
$legacyShortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) $legacyShortcutName

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
    throw 'Uninstall path validation failed. No files were removed.'
}

Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'CodexGlass' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $shortcutPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $legacyShortcutPath -Force -ErrorAction SilentlyContinue

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

Write-Host 'Codex Glass was completely removed.' -ForegroundColor Green

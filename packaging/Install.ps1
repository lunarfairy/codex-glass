$ErrorActionPreference = 'Stop'

$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $codexCommand) {
    throw 'Codex CLI is required. Install the official CLI from https://github.com/openai/codex, then run this installer again.'
}

$codexVersion = (& $codexCommand.Source --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $codexVersion -notmatch '(?i)codex') {
    throw 'The codex command could not be verified. Reinstall the official Codex CLI, then run this installer again.'
}

$sourceDirectory = Join-Path $PSScriptRoot 'app'
$sourceExecutable = Join-Path $sourceDirectory 'CodexGlass.exe'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\CodexGlass'
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$installedToolsDirectory = Join-Path $installDirectory 'tools'
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

if (-not (Test-Path -LiteralPath $sourceExecutable -PathType Leaf)) {
    throw 'The installation package is incomplete: CodexGlass.exe is missing.'
}

$installedProcesses = @(Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
})
if ($installedProcesses.Count -gt 0) {
    $installedProcesses | Stop-Process -Force
    $installedProcesses | Wait-Process -Timeout 10
}

if (Test-Path -LiteralPath $installedToolsDirectory) {
    Remove-DirectoryWhenUnlocked $installedToolsDirectory
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDirectory '*') -Destination $installDirectory -Recurse -Force

$registration = Start-Process -FilePath $installedExecutable -ArgumentList @('--register-startup') -Wait -PassThru
if ($registration.ExitCode -ne 0) {
    throw 'Could not register Windows startup.'
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $installedExecutable
$shortcut.Arguments = '--control'
$shortcut.WorkingDirectory = $installDirectory
$shortcut.Description = 'Open Codex Glass controls'
$shortcut.Save()
Remove-Item -LiteralPath $legacyShortcutPath -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $installedExecutable
Write-Host 'Codex Glass is installed and will start with Windows.' -ForegroundColor Green

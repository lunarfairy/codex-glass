$ErrorActionPreference = 'Stop'

$sourceDirectory = Join-Path $PSScriptRoot 'app'
$sourceExecutable = Join-Path $sourceDirectory 'CodexGlass.exe'
$sourceCli = Join-Path $sourceDirectory 'tools\codex.exe'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\CodexGlass'
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Codex Glass.lnk'

if (-not (Test-Path -LiteralPath $sourceExecutable -PathType Leaf)) {
    throw 'The installation package is incomplete: CodexGlass.exe is missing.'
}

if (-not (Test-Path -LiteralPath $sourceCli -PathType Leaf)) {
    throw 'The installation package is incomplete: bundled codex.exe is missing.'
}

Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
} | Stop-Process -Force

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

Start-Process -FilePath $installedExecutable
Write-Host 'Codex Glass is installed and will start with Windows.' -ForegroundColor Green

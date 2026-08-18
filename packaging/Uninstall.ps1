$ErrorActionPreference = 'Stop'

$programsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs'))
$installDirectory = [IO.Path]::GetFullPath((Join-Path $programsDirectory 'CodexGlass'))
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$settingsDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'CodexGlass'))

if (-not $installDirectory.StartsWith($programsDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($installDirectory) -ne 'CodexGlass') {
    throw '卸载路径校验失败，未删除任何文件。'
}

Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'CodexGlass' -ErrorAction SilentlyContinue

Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
} | Stop-Process -Force

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}

if ($settingsDirectory -eq [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'CodexGlass')) -and
    (Test-Path -LiteralPath $settingsDirectory)) {
    Remove-Item -LiteralPath $settingsDirectory -Recurse -Force
}

Write-Host 'Codex Glass 已完全卸载。' -ForegroundColor Green

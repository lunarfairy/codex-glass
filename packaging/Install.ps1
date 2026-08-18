$ErrorActionPreference = 'Stop'

$sourceDirectory = Join-Path $PSScriptRoot 'app'
$sourceExecutable = Join-Path $sourceDirectory 'CodexGlass.exe'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\CodexGlass'
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Codex Glass 控制台.lnk'

if (-not (Test-Path -LiteralPath $sourceExecutable -PathType Leaf)) {
    throw '安装包不完整：找不到 CodexGlass.exe。'
}

Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
} | Stop-Process -Force

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDirectory '*') -Destination $installDirectory -Recurse -Force

$registration = Start-Process -FilePath $installedExecutable -ArgumentList '--register-startup' -Wait -PassThru
if ($registration.ExitCode -ne 0) {
    throw '无法注册自动启动。'
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $installedExecutable
$shortcut.Arguments = '--control'
$shortcut.WorkingDirectory = $installDirectory
$shortcut.Description = '打开 Codex Glass 控制台'
$shortcut.Save()

Start-Process -FilePath $installedExecutable
Write-Host 'Codex Glass 已安装，并会随 Windows 在后台启动。' -ForegroundColor Green

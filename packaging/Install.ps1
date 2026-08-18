$ErrorActionPreference = 'Stop'

$sourceDirectory = Join-Path $PSScriptRoot 'app'
$sourceExecutable = Join-Path $sourceDirectory 'CodexGlass.exe'
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\CodexGlass'
$installedExecutable = Join-Path $installDirectory 'CodexGlass.exe'

if (-not (Test-Path -LiteralPath $sourceExecutable -PathType Leaf)) {
    throw '安装包不完整：找不到 CodexGlass.exe。'
}

Get-Process CodexGlass -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
} | Stop-Process -Force

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDirectory '*') -Destination $installDirectory -Recurse -Force

& $installedExecutable --register-startup
if ($LASTEXITCODE -ne 0) {
    throw '无法注册自动启动。'
}

Start-Process -FilePath $installedExecutable
Write-Host 'Codex Glass 已安装，并会随 Windows 在后台启动。' -ForegroundColor Green

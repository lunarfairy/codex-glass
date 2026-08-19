param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CodexCliPath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Version
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$releaseName = "CodexGlass-v$Version-windows-x64"
$outputRoot = Join-Path $repositoryRoot 'outputs'
$releaseDirectory = Join-Path $outputRoot $releaseName
$appDirectory = Join-Path $releaseDirectory 'app'
$bundleCli = Join-Path $appDirectory 'tools\codex.exe'
$archivePath = Join-Path $outputRoot "$releaseName.zip"
$projectPath = Join-Path $repositoryRoot 'src\CodexGlass\CodexGlass.csproj'

if (-not (Test-Path -LiteralPath $CodexCliPath -PathType Leaf)) {
    throw "Codex CLI was not found: $CodexCliPath"
}

$cliVersion = (& $CodexCliPath --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $cliVersion -notmatch '^codex-cli ') {
    throw "The selected file is not a working Codex CLI: $CodexCliPath"
}

if (Test-Path -LiteralPath $releaseDirectory) {
    throw "Release directory already exists: $releaseDirectory"
}

dotnet publish $projectPath --configuration Release --runtime win-x64 --self-contained true --output $appDirectory
New-Item -ItemType Directory -Path (Split-Path -Parent $bundleCli) -Force | Out-Null
Copy-Item -LiteralPath $CodexCliPath -Destination $bundleCli

foreach ($file in @('Install.ps1', 'Uninstall.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $releaseDirectory
}

foreach ($file in (Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*.cmd')) {
    Copy-Item -LiteralPath $file.FullName -Destination $releaseDirectory
}

foreach ($file in (Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*.txt')) {
    Copy-Item -LiteralPath $file.FullName -Destination $releaseDirectory
}

if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

Compress-Archive -LiteralPath $releaseDirectory -DestinationPath $archivePath
Write-Host "Created $archivePath" -ForegroundColor Green
Write-Host "Bundled $cliVersion" -ForegroundColor Green

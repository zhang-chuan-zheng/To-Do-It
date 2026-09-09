[CmdletBinding()]
param(
    [string]$Preset = 'local-dev',
    [string]$QtBinPath = 'D:\Qt\6.11.2\msvc2022_64\bin'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$executablePath = Join-Path $projectRoot "build\$Preset\bin\ToDoIt.exe"
$developmentEventFile = Join-Path $projectRoot 'data\event.csv'

if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
    throw "The application has not been built: $executablePath"
}
if (-not (Test-Path -LiteralPath $QtBinPath -PathType Container)) {
    throw "The Qt runtime directory was not found: $QtBinPath"
}

$env:PATH = "$QtBinPath;$env:PATH"
$env:QT_FORCE_STDERR_LOGGING = '1'
if (Test-Path -LiteralPath $developmentEventFile -PathType Leaf) {
    $env:TODOIT_EVENT_FILE = $developmentEventFile
}
& $executablePath
$applicationExitCode = $LASTEXITCODE

if ($applicationExitCode -ne 0) {
    $startupLogPath = Join-Path (Split-Path -Parent $executablePath) 'startup-error.log'
    if (Test-Path -LiteralPath $startupLogPath -PathType Leaf) {
        Write-Host "`nTo Do It startup diagnostics:"
        Get-Content -LiteralPath $startupLogPath
    }
}

exit $applicationExitCode

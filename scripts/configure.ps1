[CmdletBinding()]
param(
    [string]$Preset = 'local-dev',
    [string]$CMakePath = 'D:\Qt\Tools\CMake_64\bin\cmake.exe',
    [switch]$Fresh,
    [string]$VisualStudioInstallPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Initialize-MsvcEnvironment.ps1') `
    -VisualStudioInstallPath $VisualStudioInstallPath

if (-not (Test-Path -LiteralPath $CMakePath -PathType Leaf)) {
    throw "CMake was not found: $CMakePath"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $arguments = @('--preset', $Preset)
    if ($Fresh) {
        $arguments += '--fresh'
    }

    & $CMakePath @arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

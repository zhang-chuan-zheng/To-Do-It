[CmdletBinding()]
param(
    [string]$Preset = 'local-dev',
    [string]$CMakePath = 'D:\Qt\Tools\CMake_64\bin\cmake.exe',
    [int]$Parallel = 0,
    [string]$Target,
    [string]$VisualStudioInstallPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Initialize-MsvcEnvironment.ps1') `
    -VisualStudioInstallPath $VisualStudioInstallPath

if (-not (Test-Path -LiteralPath $CMakePath -PathType Leaf)) {
    throw "CMake was not found: $CMakePath"
}

$arguments = @('--build', '--preset', $Preset)
if ($Parallel -gt 0) {
    $arguments += @('--parallel', $Parallel)
}
if (-not [string]::IsNullOrWhiteSpace($Target)) {
    $arguments += @('--target', $Target)
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & $CMakePath @arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

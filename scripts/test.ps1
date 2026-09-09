[CmdletBinding()]
param(
    [string]$Preset = 'local-dev',
    [string]$CTestPath = 'D:\Qt\Tools\CMake_64\bin\ctest.exe',
    [int]$Parallel = 0
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $CTestPath -PathType Leaf)) {
    throw "CTest was not found: $CTestPath"
}

$arguments = @('--preset', $Preset)
if ($Parallel -gt 0) {
    $arguments += @('--parallel', $Parallel)
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    & $CTestPath @arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

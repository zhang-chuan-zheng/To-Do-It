[CmdletBinding()]
param(
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$manualPath = Join-Path $resolvedProjectRoot 'docs\structure.md'
$rootPrefix = $resolvedProjectRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

function Get-ProjectRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $resolvedFullPath = [System.IO.Path]::GetFullPath($FullPath)
    if (-not $resolvedFullPath.StartsWith(
        $rootPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Path is outside the project root: $resolvedFullPath"
    }

    return $resolvedFullPath.Substring($rootPrefix.Length).Replace('\', '/')
}

if (-not (Test-Path -LiteralPath $manualPath -PathType Leaf)) {
    Write-Error 'docs/structure.md does not exist.'
    exit 1
}

$manualText = Get-Content -Raw -LiteralPath $manualPath
$ignoredTopDirectories = @('.git', '.vs', '.toolchains', 'build', 'out', 'runtime')
$ignoredFilePatterns = @('*.tmp', '*.bak')

$projectFiles = Get-ChildItem -LiteralPath $resolvedProjectRoot -Recurse -File -Force |
    Where-Object {
        $relativePath = Get-ProjectRelativePath -FullPath $_.FullName
        $topDirectory = $relativePath.Split('/')[0]
        $isIgnoredDirectory = $ignoredTopDirectories -contains $topDirectory -or $topDirectory -like 'cmake-build-*'
        $isIgnoredFile = $false

        foreach ($pattern in $ignoredFilePatterns) {
            if ($_.Name -like $pattern) {
                $isIgnoredFile = $true
                break
            }
        }

        -not $isIgnoredDirectory -and -not $isIgnoredFile
    } |
    ForEach-Object {
        Get-ProjectRelativePath -FullPath $_.FullName
    } |
    Sort-Object -Unique

$missingEntries = @(
    foreach ($relativePath in $projectFiles) {
        if (-not $manualText.Contains("``$relativePath``")) {
            $relativePath
        }
    }
)

if ($missingEntries.Count -gt 0) {
    Write-Error ("The following project files are missing explicit annotations in docs/structure.md:`n - " + ($missingEntries -join "`n - "))
    exit 1
}

Write-Host "structure.md check passed: $($projectFiles.Count) project files have explicit annotations."

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Owner,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Repository
)

$ErrorActionPreference = 'Stop'

function Get-FullPath([string]$PathValue)
{
    return [System.IO.Path]::GetFullPath($PathValue)
}

function Assert-ChildPath([string]$PathValue, [string]$ParentValue)
{
    $path = Get-FullPath $PathValue
    $parent = (Get-FullPath $ParentValue).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($parent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a generated path outside '$parent': $path"
    }
    return $path
}

$projectRoot = Get-FullPath (Join-Path $PSScriptRoot '..')
$packageRoot = Join-Path $projectRoot 'out/packages'
$metadataPath = Join-Path $packageRoot 'publish-metadata.json'
if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw 'publish-metadata.json is missing. Run scripts/package.ps1 first.'
}
$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$version = [string]$metadata.appVersion
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid release version in publish-metadata.json: '$version'"
}
if ($Owner -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*$' -or
    $Repository -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw 'Owner or Repository contains characters that are invalid for this GitHub Pages layout.'
}
$expectedUrl = "https://${Owner}.github.io/${Repository}/updates/windows/x64"
if ([string]$metadata.repositoryUrl -ne $expectedUrl) {
    throw "The installer was packaged for '$($metadata.repositoryUrl)', not '$expectedUrl'. Re-run package.ps1 with -RepositoryUrl '$expectedUrl'."
}

$publishRoot = Assert-ChildPath (Join-Path $projectRoot "out/github-publish/v$version") $projectRoot
if (Test-Path -LiteralPath $publishRoot) {
    Remove-Item -LiteralPath $publishRoot -Recurse -Force
}
$releaseRoot = Join-Path $publishRoot 'release-assets'
$pagesRoot = Join-Path $publishRoot 'pages'
$repositoryRoot = Join-Path $pagesRoot 'updates/windows/x64'
[void](New-Item -ItemType Directory -Path $releaseRoot -Force)
[void](New-Item -ItemType Directory -Path $repositoryRoot -Force)

$assetNames = @(
    "ToDoIt-Setup-$version-x64.exe",
    "ToDoIt-OfflineUpdate-$version-x64.zip",
    "ToDoIt-OnlineRepository-$version-x64.zip",
    'SHA256SUMS.txt',
    'publish-metadata.json',
    'release-manifest.json'
)
$declaredHashes = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $packageRoot 'SHA256SUMS.txt')) {
    if ($line -notmatch '^([0-9A-Fa-f]{64})\s{2}(.+)$') {
        throw "Invalid SHA256SUMS.txt line: $line"
    }
    $declaredHashes[$Matches[2]] = $Matches[1].ToLowerInvariant()
}
foreach ($assetName in $assetNames) {
    $source = Join-Path $packageRoot $assetName
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Release asset is missing: $source"
    }
    if ($assetName -ne 'SHA256SUMS.txt') {
        $actualHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
        if (-not $declaredHashes.ContainsKey($assetName) -or
            $declaredHashes[$assetName] -ne $actualHash) {
            throw "Release asset hash does not match SHA256SUMS.txt: $assetName"
        }
    }
    Copy-Item -LiteralPath $source -Destination $releaseRoot
}

Expand-Archive `
    -LiteralPath (Join-Path $packageRoot "ToDoIt-OnlineRepository-$version-x64.zip") `
    -DestinationPath $repositoryRoot
[System.IO.File]::WriteAllText(
    (Join-Path $pagesRoot '.nojekyll'),
    '',
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "GitHub Release assets: $releaseRoot"
Write-Host "GitHub Pages content: $pagesRoot"
Write-Host "Updater URL: $expectedUrl"

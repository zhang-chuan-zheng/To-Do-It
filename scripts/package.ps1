[CmdletBinding()]
param(
    [string]$Preset = 'local-release',
    [string]$CMakePath = 'D:\Qt\Tools\CMake_64\bin\cmake.exe',
    [string]$IfwRoot,
    [string]$RepositoryUrl,
    [Parameter(Mandatory = $true)]
    [string]$QtLicenseFile
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

function Expand-Template(
    [string]$Source,
    [string]$Destination,
    [hashtable]$Values)
{
    $content = [System.IO.File]::ReadAllText($Source)
    foreach ($entry in $Values.GetEnumerator()) {
        $content = $content.Replace("@$($entry.Key)@", [string]$entry.Value)
    }
    [System.IO.File]::WriteAllText(
        $Destination,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$projectRoot = Get-FullPath (Join-Path $PSScriptRoot '..')
$cmakeFile = Join-Path $projectRoot 'CMakeLists.txt'
$cmakeText = [System.IO.File]::ReadAllText($cmakeFile)
$versionMatch = [regex]::Match(
    $cmakeText,
    'project\s*\(\s*ToDoIt\s+VERSION\s+([0-9]+\.[0-9]+\.[0-9]+)',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
if (-not $versionMatch.Success) {
    throw 'Unable to read the ToDoIt version from the root CMakeLists.txt.'
}
$version = $versionMatch.Groups[1].Value

$remoteRepositoriesXml = ''
$installerMode = '--offline-only'
if (-not [string]::IsNullOrWhiteSpace($RepositoryUrl)) {
    try {
        $repositoryUri = [System.Uri]$RepositoryUrl
    } catch {
        throw 'RepositoryUrl must be an absolute HTTPS URL.'
    }
    if (-not $repositoryUri.IsAbsoluteUri -or $repositoryUri.Scheme -ne 'https') {
        throw 'RepositoryUrl must be an absolute HTTPS URL.'
    }
    $RepositoryUrl = $RepositoryUrl.TrimEnd('/')
    $escapedRepositoryUrl = [System.Security.SecurityElement]::Escape($RepositoryUrl)
    $remoteRepositoriesXml = @"
    <RemoteRepositories>
        <Repository>
            <Url>$escapedRepositoryUrl</Url>
            <Enabled>1</Enabled>
            <DisplayName>To Do It GitHub Updates</DisplayName>
        </Repository>
    </RemoteRepositories>
"@
    $installerMode = '--hybrid'
}

$buildDirectory = Join-Path $projectRoot "build/$Preset"
$builtApplication = Join-Path $buildDirectory 'bin/ToDoIt.exe'
$builtMigrator = Join-Path $buildDirectory 'bin/ToDoItMigrator.exe'
if (-not (Test-Path -LiteralPath $builtApplication -PathType Leaf) -or
    -not (Test-Path -LiteralPath $builtMigrator -PathType Leaf)) {
    throw "Release binaries are missing. Build preset '$Preset' first; this packaging script never compiles the project."
}

$manifest = Join-Path $projectRoot "updater/manifests/$version.json"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw "Release manifest is missing: $manifest"
}
$manifestData = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($manifestData.appVersion -ne $version -or [int]$manifestData.eventSchema -lt 1) {
    throw 'Release manifest version/schema does not match the CMake project version.'
}
$targetSchemaDefinitions = @(
    $manifestData.eventSchemas |
        Where-Object { [int]$_.version -eq [int]$manifestData.eventSchema }
)
if ($targetSchemaDefinitions.Count -ne 1 -or
    @($targetSchemaDefinitions[0].columns).Count -lt 1 -or
    [string]$targetSchemaDefinitions[0].columns[0].name -ne 'schema_version') {
    throw 'Release manifest must contain exactly one valid target event schema definition.'
}

if (-not (Test-Path -LiteralPath $CMakePath -PathType Leaf)) {
    throw "CMake was not found: $CMakePath"
}
if (-not (Test-Path -LiteralPath $QtLicenseFile -PathType Leaf)) {
    throw "Provide the official LGPL-3.0-only.txt file with -QtLicenseFile. Missing: $QtLicenseFile"
}

if ([string]::IsNullOrWhiteSpace($IfwRoot)) {
    $binaryCreatorCandidate = Get-ChildItem -LiteralPath 'D:\Qt\Tools' `
        -Filter 'binarycreator.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($null -eq $binaryCreatorCandidate) {
        throw 'Qt Installer Framework is not installed. Add it with the Qt Maintenance Tool, then pass -IfwRoot.'
    }
    $binaryCreator = $binaryCreatorCandidate.FullName
    $IfwRoot = Split-Path (Split-Path $binaryCreator -Parent) -Parent
} else {
    $binaryCreator = Join-Path $IfwRoot 'bin/binarycreator.exe'
}
$installerBase = Join-Path $IfwRoot 'bin/installerbase.exe'
$repositoryGenerator = Join-Path $IfwRoot 'bin/repogen.exe'
if (-not (Test-Path -LiteralPath $binaryCreator -PathType Leaf) -or
    -not (Test-Path -LiteralPath $installerBase -PathType Leaf) -or
    -not (Test-Path -LiteralPath $repositoryGenerator -PathType Leaf)) {
    throw "Qt Installer Framework tools were not found below: $IfwRoot"
}

$generatedRoot = Assert-ChildPath (Join-Path $projectRoot 'out/package-work') $projectRoot
$outputRoot = Assert-ChildPath (Join-Path $projectRoot 'out/packages') $projectRoot
if (Test-Path -LiteralPath $generatedRoot) {
    Remove-Item -LiteralPath $generatedRoot -Recurse -Force
}
[void](New-Item -ItemType Directory -Path $generatedRoot)
[void](New-Item -ItemType Directory -Path $outputRoot -Force)

$stageRoot = Join-Path $generatedRoot 'stage'
$ifwRoot = Join-Path $generatedRoot 'ifw'
$configRoot = Join-Path $ifwRoot 'config'
$packageRoot = Join-Path $ifwRoot 'packages/com.todoit.app'
$packageData = Join-Path $packageRoot 'data'
$packageMeta = Join-Path $packageRoot 'meta'
[void](New-Item -ItemType Directory -Path $stageRoot)
[void](New-Item -ItemType Directory -Path $configRoot)
[void](New-Item -ItemType Directory -Path $packageData)
[void](New-Item -ItemType Directory -Path $packageMeta)

# This performs CMake install/deployment only. It does not invoke a build.
& $CMakePath --install $buildDirectory --prefix $stageRoot --config Release
if ($LASTEXITCODE -ne 0) {
    throw "CMake install/deployment failed with exit code $LASTEXITCODE."
}

foreach ($requiredRelativePath in @(
    'ToDoIt.exe',
    'ToDoItMigrator.exe',
    'release-manifest.json',
    'qt.conf',
    'Qt6Core.dll',
    'Qt6Gui.dll',
    'Qt6Qml.dll',
    'Qt6Quick.dll',
    'Qt6QuickControls2.dll',
    'Qt6QuickEffects.dll',
    'plugins/platforms/qwindows.dll',
    'qml/QtQuick/qmldir',
    'qml/QtQuick/Controls/qtquickcontrols2plugin.dll'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $stageRoot $requiredRelativePath) -PathType Leaf)) {
        throw "The staged release is incomplete: $requiredRelativePath is missing."
    }
}

# Windows resolves ordinary dependent DLLs beside the executable. A previous
# package put ToDoIt.exe in the installation root but Qt6*.dll in root/bin,
# producing an installer that succeeded yet could not launch on a clean PC.
$misplacedQtRuntime = Join-Path $stageRoot 'bin/Qt6Core.dll'
if (Test-Path -LiteralPath $misplacedQtRuntime -PathType Leaf) {
    throw 'Invalid Windows deployment layout: Qt runtime DLLs are under bin while ToDoIt.exe is in the install root.'
}

$releaseFiles = @(
    Get-ChildItem -LiteralPath $stageRoot -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {
            [ordered]@{
                path = $_.FullName.Substring($stageRoot.Length).TrimStart('\', '/').Replace('\', '/')
                size = $_.Length
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        }
)
$releaseIndex = [ordered]@{
    appVersion = $version
    eventSchema = [int]$manifestData.eventSchema
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    files = $releaseFiles
}
$releaseIndexJson = $releaseIndex | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText(
    (Join-Path $stageRoot 'release-files.json'),
    $releaseIndexJson,
    [System.Text.UTF8Encoding]::new($false)
)

Get-ChildItem -LiteralPath $stageRoot -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $packageData -Recurse -Force
}

$templateValues = @{
    TODOIT_VERSION = $version
    TODOIT_RELEASE_DATE = (Get-Date -Format 'yyyy-MM-dd')
    TODOIT_REMOTE_REPOSITORIES = $remoteRepositoriesXml
}
Expand-Template `
    (Join-Path $projectRoot 'installer/config/config.xml.in') `
    (Join-Path $configRoot 'config.xml') `
    $templateValues
Expand-Template `
    (Join-Path $projectRoot 'installer/packages/com.todoit.app/meta/package.xml.in') `
    (Join-Path $packageMeta 'package.xml') `
    $templateValues
Expand-Template `
    (Join-Path $projectRoot 'installer/controller/installer-controller.qs') `
    (Join-Path $configRoot 'installer-controller.qs') `
    $templateValues
Copy-Item -LiteralPath `
    (Join-Path $projectRoot 'installer/config/style.qss') `
    -Destination (Join-Path $configRoot 'style.qss')
Copy-Item -LiteralPath `
    (Join-Path $projectRoot 'installer/packages/com.todoit.app/meta/installscript.qs') `
    -Destination (Join-Path $packageMeta 'installscript.qs')
Expand-Template `
    (Join-Path $projectRoot 'installer/packages/com.todoit.app/meta/welcomewidget.ui') `
    (Join-Path $packageMeta 'welcomewidget.ui') `
    $templateValues
Copy-Item -LiteralPath `
    (Join-Path $projectRoot 'installer/packages/com.todoit.app/meta/uninstalloptionswidget.ui') `
    -Destination (Join-Path $packageMeta 'uninstalloptionswidget.ui')
Copy-Item -LiteralPath $QtLicenseFile `
    -Destination (Join-Path $packageMeta 'LGPL-3.0-only.txt')

$outputInstaller = Assert-ChildPath `
    (Join-Path $outputRoot "ToDoIt-Setup-$version-x64.exe") `
    $outputRoot
if (Test-Path -LiteralPath $outputInstaller) {
    Remove-Item -LiteralPath $outputInstaller -Force
}

& $binaryCreator `
    $installerMode `
    -t $installerBase `
    -c (Join-Path $configRoot 'config.xml') `
    -p (Join-Path $ifwRoot 'packages') `
    $outputInstaller
if ($LASTEXITCODE -ne 0) {
    throw "Qt Installer Framework packaging failed with exit code $LASTEXITCODE."
}

$repositoryRoot = Join-Path $generatedRoot 'repository'
& $repositoryGenerator `
    -p (Join-Path $ifwRoot 'packages') `
    $repositoryRoot
if ($LASTEXITCODE -ne 0) {
    throw "Qt Installer Framework repository generation failed with exit code $LASTEXITCODE."
}

$updateBundleRoot = Join-Path $generatedRoot 'offline-update'
[void](New-Item -ItemType Directory -Path $updateBundleRoot)
Copy-Item -LiteralPath $repositoryRoot `
    -Destination (Join-Path $updateBundleRoot 'repository') `
    -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'installer/update/apply-update.ps1') `
    -Destination $updateBundleRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'installer/update/README.txt') `
    -Destination $updateBundleRoot

$outputUpdate = Assert-ChildPath `
    (Join-Path $outputRoot "ToDoIt-OfflineUpdate-$version-x64.zip") `
    $outputRoot
if (Test-Path -LiteralPath $outputUpdate) {
    Remove-Item -LiteralPath $outputUpdate -Force
}
Compress-Archive -Path (Join-Path $updateBundleRoot '*') `
    -DestinationPath $outputUpdate `
    -CompressionLevel Optimal

$outputRepository = Assert-ChildPath `
    (Join-Path $outputRoot "ToDoIt-OnlineRepository-$version-x64.zip") `
    $outputRoot
if (Test-Path -LiteralPath $outputRepository) {
    Remove-Item -LiteralPath $outputRepository -Force
}
Compress-Archive -Path (Join-Path $repositoryRoot '*') `
    -DestinationPath $outputRepository `
    -CompressionLevel Optimal

$outputManifest = Join-Path $outputRoot 'release-manifest.json'
Copy-Item -LiteralPath $manifest -Destination $outputManifest -Force
$publishMetadataPath = Join-Path $outputRoot 'publish-metadata.json'
$publishMetadata = [ordered]@{
    appVersion = $version
    eventSchema = [int]$manifestData.eventSchema
    repositoryUrl = $RepositoryUrl
    installerMode = $installerMode.TrimStart('-')
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
}
[System.IO.File]::WriteAllText(
    $publishMetadataPath,
    ($publishMetadata | ConvertTo-Json -Depth 4),
    [System.Text.UTF8Encoding]::new($false)
)

$hashFile = Join-Path $outputRoot 'SHA256SUMS.txt'
$releaseAssets = @(
    $outputInstaller,
    $outputUpdate,
    $outputRepository,
    $outputManifest,
    $publishMetadataPath
)
$hashLines = $releaseAssets | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([System.IO.Path]::GetFileName($_))"
}
[System.IO.File]::WriteAllLines(
    $hashFile,
    $hashLines,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Installer created: $outputInstaller"
Write-Host "Offline update package created: $outputUpdate"
Write-Host "Online repository archive created: $outputRepository"
Write-Host "Release hashes created: $hashFile"

[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\ToDoIt')
)

$ErrorActionPreference = 'Stop'

$repository = Join-Path $PSScriptRoot 'repository'
$updatesFile = Join-Path $repository 'Updates.xml'
if (-not (Test-Path -LiteralPath $updatesFile -PathType Leaf)) {
    throw "This update package is incomplete: $updatesFile is missing."
}

$maintenanceTool = Join-Path $InstallDir 'ToDoItMaintenanceTool.exe'
if (-not (Test-Path -LiteralPath $maintenanceTool -PathType Leaf)) {
    throw "To Do It is not installed at '$InstallDir'. Pass the installation directory with -InstallDir."
}

$repositoryUri = ([System.Uri](Resolve-Path -LiteralPath $repository).Path).AbsoluteUri
& $maintenanceTool `
    --add-temp-repository $repositoryUri `
    update com.todoit.app
exit $LASTEXITCODE

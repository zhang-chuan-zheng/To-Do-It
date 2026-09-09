[CmdletBinding()]
param(
    [string]$VisualStudioInstallPath
)

$ErrorActionPreference = 'Stop'

# Ask Visual Studio tools for English diagnostics when that language pack is
# installed. The configure script also handles Chinese-only MSVC installations.
$env:VSLANG = '1033'

if (Get-Command cl.exe -ErrorAction SilentlyContinue) {
    return
}

if ([string]::IsNullOrWhiteSpace($VisualStudioInstallPath)) {
    $vsWherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vsWherePath -PathType Leaf) {
        $VisualStudioInstallPath = & $vsWherePath `
            -latest `
            -products '*' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath
    }
}

if ([string]::IsNullOrWhiteSpace($VisualStudioInstallPath)) {
    $knownInstall = 'D:\Microsoft Visual Studio\18\Community'
    if (Test-Path -LiteralPath $knownInstall -PathType Container) {
        $VisualStudioInstallPath = $knownInstall
    }
}

if ([string]::IsNullOrWhiteSpace($VisualStudioInstallPath)) {
    throw 'Unable to locate a Visual Studio installation with the x64 C++ toolchain.'
}

$vsDevCmdPath = Join-Path $VisualStudioInstallPath 'Common7\Tools\VsDevCmd.bat'
if (-not (Test-Path -LiteralPath $vsDevCmdPath -PathType Leaf)) {
    throw "VsDevCmd.bat was not found below: $VisualStudioInstallPath"
}

$commandLine = '"' + $vsDevCmdPath + '" -arch=x64 -host_arch=x64 -no_logo >nul && set'
$environmentLines = @(& $env:ComSpec /d /s /c $commandLine)
if ($LASTEXITCODE -ne 0) {
    throw "Visual Studio developer environment initialization failed with exit code $LASTEXITCODE."
}

$environmentValues = [System.Collections.Generic.Dictionary[string, string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($line in $environmentLines) {
    $separatorIndex = $line.IndexOf('=')
    if ($separatorIndex -le 0) {
        continue
    }

    $name = $line.Substring(0, $separatorIndex)
    $value = $line.Substring($separatorIndex + 1)

    if (-not $environmentValues.ContainsKey($name)) {
        $environmentValues.Add($name, $value)
        continue
    }

    # Some hosts expose both PATH and Path. Prefer the value produced by
    # VsDevCmd (the one that contains the selected MSVC toolchain).
    if ($name -ieq 'Path' -and $value -match '\\VC\\Tools\\MSVC\\[^;]+\\bin\\Host') {
        $environmentValues[$name] = $value
    }
}

foreach ($entry in $environmentValues.GetEnumerator()) {
    Set-Item -LiteralPath "Env:$($entry.Key)" -Value $entry.Value
}

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    throw 'The Visual Studio environment was loaded, but cl.exe is still unavailable.'
}

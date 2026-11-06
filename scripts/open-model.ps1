# Open a local .scad model in the Windows OpenSCAD GUI with this repository's
# pinned NopSCADlib available as a project-local library.
# Requires OpenSCAD installed and .\bootstrap.ps1 run once.
[CmdletBinding()]
param(
    [string]$Model = "examples/spacer/v0.1/scad/spacer.scad",
    [string]$OpenSCADExe
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$extPath = Join-Path $root "ext"
$library = Join-Path $extPath "NopSCADlib\core.scad"

if (-not (Test-Path -LiteralPath $library -PathType Leaf)) {
    throw "NopSCADlib ontbreekt. Voer vanuit de repository uit: .\bootstrap.ps1"
}

$modelPath = if ([System.IO.Path]::IsPathRooted($Model)) {
    $Model
} else {
    Join-Path $root $Model
}
if (-not (Test-Path -LiteralPath $modelPath -PathType Leaf)) {
    throw "Modelbestand niet gevonden: $modelPath"
}
$modelPath = (Resolve-Path -LiteralPath $modelPath).Path

# Prefer an explicitly supplied executable. Otherwise, use OpenSCAD Nightly
# by default. Fall back to the regular installation or PATH only if Nightly
# is absent; do not modify the machine-wide OpenSCAD configuration.
if ($OpenSCADExe) {
    if (-not (Test-Path -LiteralPath $OpenSCADExe -PathType Leaf)) {
        throw "OpenSCAD executable niet gevonden: $OpenSCADExe"
    }
    $exe = (Resolve-Path -LiteralPath $OpenSCADExe).Path
} else {
    $exe = $null
    $candidates = @(
        "C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
    )
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "OpenSCAD\openscad.exe")
    }
    $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
    if ($programFilesX86) {
        $candidates += (Join-Path $programFilesX86 "OpenSCAD\openscad.exe")
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $exe = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }
    if (-not $exe) {
        $cmd = Get-Command openscad.exe -CommandType Application -ErrorAction SilentlyContinue
        if ($cmd) { $exe = $cmd.Source }
    }
    if (-not $exe) {
        throw "OpenSCAD niet gevonden. Verwacht: C:\Program Files\OpenSCAD (Nightly)\openscad.exe. Gebruik anders -OpenSCADExe '<pad>\openscad.exe'."
    }
}

# Windows OpenSCAD uses ; between library paths. A child process started
# from here inherits this value. No system-wide library installation is needed.
# Keep the library path local to the launched GUI; do not change the
# caller's PowerShell session or globally installed libraries.
$previousOpenSCADPath = [Environment]::GetEnvironmentVariable("OPENSCADPATH", "Process")
try {
    $env:OPENSCADPATH = $extPath + $(if ($previousOpenSCADPath) { ";$previousOpenSCADPath" } else { "" })
    Write-Host "OpenSCAD: $exe"
    Write-Host "Model: $modelPath"
    Write-Host "Library path: $env:OPENSCADPATH"
    Start-Process -FilePath $exe -ArgumentList ('"' + $modelPath + '"') -WorkingDirectory (Split-Path $modelPath -Parent)
}
finally {
    [Environment]::SetEnvironmentVariable("OPENSCADPATH", $previousOpenSCADPath, "Process")
}

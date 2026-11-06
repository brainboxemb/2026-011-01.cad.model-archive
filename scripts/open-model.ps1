# Open a local .scad model in the Windows OpenSCAD GUI with this repository's
# pinned NopSCADlib available as a project-local library.
# Requires OpenSCAD installed and "vcs import" performed once.
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
    throw "NopSCADlib ontbreekt. Voer in de repo-root uit: New-Item -ItemType Directory ext -Force; vcs import --input dependencies.repos ext"
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

# Prefer an explicitly supplied GUI executable; otherwise try PATH and the
# standard installation locations (without modifying global Windows settings).
if ($OpenSCADExe) {
    if (-not (Test-Path -LiteralPath $OpenSCADExe -PathType Leaf)) {
        throw "OpenSCAD executable niet gevonden: $OpenSCADExe"
    }
    $exe = (Resolve-Path -LiteralPath $OpenSCADExe).Path
} else {
    $exe = $null
    $cmd = Get-Command openscad.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        $exe = $cmd.Source
    }
    if (-not $exe) {
        $candidates = @(
            (Join-Path $env:ProgramFiles "OpenSCAD\openscad.exe")
        )
        $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
        if ($programFilesX86) {
            $candidates += (Join-Path $programFilesX86 "OpenSCAD\openscad.exe")
        }
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $exe = $candidate
                break
            }
        }
    }
    if (-not $exe) {
        throw "OpenSCAD niet gevonden. Installeer OpenSCAD of gebruik -OpenSCADExe 'C:\pad\openscad.exe'."
    }
}

# Windows OpenSCAD uses ; between library paths. A child process started
# from here inherits this value. No system-wide library installation is needed.
$env:OPENSCADPATH = $extPath + $(if ($env:OPENSCADPATH) { ";$env:OPENSCADPATH" } else { "" })

Write-Host "OpenSCAD: $exe"
Write-Host "Model: $modelPath"
Write-Host "Library path: $env:OPENSCADPATH"
Start-Process -FilePath $exe -ArgumentList ('"' + $modelPath + '"') -WorkingDirectory (Split-Path $modelPath -Parent)

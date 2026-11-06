<#
.SYNOPSIS
    Fetch this model archive's pinned external libraries.

.DESCRIPTION
    Creates the local ext/ directory (if needed) and uses vcs2l to check
    out dependencies.repos, including NopSCADlib. Safe to rerun when the
    pinned dependencies are already present.

    Prefers a 'vcs' executable in the current environment. Otherwise
    runs 'vcs' from the shared brainboxemb-dev-tools Conda environment.
    Does not install Python packages globally or change shell settings.

.PARAMETER CondaExe
    Optional path to conda.exe when it is not on PATH or in a standard
    Windows installation directory.

.EXAMPLE
    .\bootstrap.ps1

.EXAMPLE
    .\bootstrap.ps1 -CondaExe 'C:\tools\miniconda3\Scripts\conda.exe'
#>
[CmdletBinding()]
param(
    [string]$CondaExe
)

$ErrorActionPreference = 'Stop'

# Resolve paths relative to this script, not the caller's working directory.
$repoRoot = $PSScriptRoot
$manifest = Join-Path $repoRoot 'dependencies.repos'
$ext = Join-Path $repoRoot 'ext'
$library = Join-Path $ext 'NopSCADlib\core.scad'

if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw "Missing dependencies manifest: $manifest"
}
if ($CondaExe -and -not (Test-Path -LiteralPath $CondaExe -PathType Leaf)) {
    throw "Specified conda.exe does not exist: $CondaExe"
}

# vcs2l expects the target directory to exist. Bootstrapping creates it.
New-Item -ItemType Directory -Path $ext -Force | Out-Null

# Use the active environment when possible. Otherwise use the shared Conda
# environment without requiring 'conda activate' in the current PowerShell.
$vcs = Get-Command vcs -CommandType Application -ErrorAction SilentlyContinue
Push-Location $repoRoot
try {
    if ($vcs) {
        Write-Host "Fetching libraries using: $($vcs.Source)"
        & $vcs.Source import --input dependencies.repos ext
    } else {
        $condaOnPath = Get-Command conda.exe -CommandType Application -ErrorAction SilentlyContinue
        $candidates = @(
            $CondaExe
            $env:CONDA_EXE
            $(if ($condaOnPath) { $condaOnPath.Source })
            'C:\tools\miniconda3\Scripts\conda.exe'
            'C:\tools\miniforge3\Scripts\conda.exe'
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'miniconda3\Scripts\conda.exe' })
            $(if ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'miniforge3\Scripts\conda.exe' })
        )
        $conda = $candidates |
            Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
            Select-Object -First 1

        if (-not $conda) {
            throw "vcs2l was not found. Install brainboxemb-dev-tools via tool.py-dev-env, or activate the environment and rerun bootstrap.ps1."
        }
        $conda = (Resolve-Path -LiteralPath $conda).Path
        Write-Host "Fetching libraries from Conda environment brainboxemb-dev-tools..."
        & $conda run --no-capture-output --name brainboxemb-dev-tools vcs import --input dependencies.repos ext
    }

    if ($LASTEXITCODE -ne 0) {
        throw "vcs2l dependency checkout failed (exit code $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

# Catch a successful command which produced no usable library checkout.
if (-not (Test-Path -LiteralPath $library -PathType Leaf)) {
    throw "NopSCADlib was not found after checkout: $library"
}

Write-Host "Ready: ext/NopSCADlib. Open a model using .\scripts\open-model.ps1"

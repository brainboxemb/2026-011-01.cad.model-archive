# Working with the model archive on Windows

**The primary workflow is local OpenSCAD GUI use.** Docker is reserved for
GitHub Actions. Documentation generation on Windows is optional and not
part of the current setup.

## Prerequisites

- [OpenSCAD for Windows](https://openscad.org/downloads.html), installed normally.
- Git, Python (`py`) and `vcs2l` for pulling the external NopSCADlib library.
- Windows PowerShell. There is **no requirement to install Docker Desktop**.

From the repository root:

```powershell
py -m pip install vcs2l
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
```

If `vcs` is not found after installation, ensure the Python *Scripts* folder
is available on your PATH (or reinstall vcs2l using the Python environment
whose Scripts directory is already on PATH).

The result is `ext/NopSCADlib`, pinned to the upstream commit in
`dependencies.repos`. The external checkout is ignored by Git.

## Open a model in desktop OpenSCAD

Run:

```powershell
.\scripts\open-model.ps1
```

The example spacer at `examples/spacer/v0.1/scad/spacer.scad` opens in the
**installed Windows GUI**. To open a specific archive model:

```powershell
.\scripts\open-model.ps1 -Model "models/<name>/v0.1/scad/main.scad"
```

If OpenSCAD is installed in a custom directory:

```powershell
.\scripts\open-model.ps1 -OpenSCADExe "D:\Apps\OpenSCAD\openscad.exe"
```

If your PowerShell execution policy blocks local scripts, you can run this
one invocation without changing machine-wide settings:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\open-model.ps1
```

### Why launch through PowerShell?

OpenSCAD finds a library imported as:

```openscad
include <NopSCADlib/core.scad>;
```

by searching library directories. For this repository the launcher sets
`OPENSCADPATH` to the **parent of** `NopSCADlib`, i.e. `ext/`, and preserves
any existing search path. It launches OpenSCAD with the selected model file.

Double-clicking the `.scad` file from Windows Explorer will **not** normally
inherit the project-specific environment variable. Opening through the
launcher avoids globally installing or configuring NopSCADlib.

Once opened, use the normal OpenSCAD GUI: change parameters, use F5 to
preview or F6 to render, and export STL from the GUI as needed. Neither Python
nor Docker is needed for normal edits after fetching NopSCADlib.

## Adding models and versions

```text
models/
  tube-clip/
    README.md               Description, application and version index
    v0.1/
      scad/
        main.scad
    v0.2/
      scad/
        main.scad
```

Each version is independent so an older design remains reproducible. A single
unversioned model can use `models/tube-clip/scad/main.scad`.

NopSCADlib's `_stl`, `_assembly` and `//! ` conventions are available, but
we do **not** require assembly documentation for every small part.

## CI and future documentation publication

[GitHub Actions](../.github/workflows/nopscadlib-smoke.yml) uses the
[repository-specific Docker image](../docker/README.md) to test a full upstream
NopSCADlib `make_all.py` build. That is a CI check, **not** the normal
Windows modeling workflow.

The intended public documentation destination is **GitHub Pages backed by a
separate orphan `gh-pages` branch**, rather than GitHub Wiki or generated
files mixed into `main`. See [Publishing plan](PUBLISHING.md).
Publication is not yet enabled.

## Licensing

NopSCADlib is [GPL-3.0-or-later](https://github.com/nophead/NopSCADlib/blob/master/COPYING).
Checking it out via vcs2l does not change its license. Do not redistribute
NopSCADlib's source without the upstream notices; review the licensing of
individual models that incorporate upstream geometry or code.

# Working with the model archive on Windows

**The primary workflow is local OpenSCAD GUI use.** Docker is reserved for
GitHub Actions. Documentation generation on Windows is optional and not
part of the current setup.

## Prerequisites

- [OpenSCAD for Windows](https://openscad.org/downloads.html), installed normally.
- Git and the shared `brainboxemb-dev-tools` Conda environment from
  [`tool.py-dev-env`](https://github.com/brainboxemb/tool.py-dev-env).
  This environment supplies `vcs2l`.
- Windows PowerShell. **Docker Desktop is not required.**

From the repository root:

```powershell
.\bootstrap.ps1
```

The bootstrap script creates `ext/` and uses `vcs import` to retrieve
`ext/NopSCADlib` at the commit pinned in `dependencies.repos`. It uses
the active `vcs` command, or runs `vcs` via `brainboxemb-dev-tools`
with `conda.exe` if the Conda environment is not activated. Re-running
it is supported, and it does not modify global Python or OpenSCAD settings.
The external checkout is ignored by Git.

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
unversioned model uses `models/tube-clip/source/scad/main.scad` instead.
The extra `source/` level avoids a Windows filename collision between a model's
human-maintained `README.md` and NopSCADlib's lowercase generated `readme.md`.

NopSCADlib's `_stl`, `_assembly` and `//! ` conventions are available, but
we do **not** require assembly documentation for every small part.

## CI and future documentation publication

[GitHub Actions](../.github/workflows/nopscadlib-smoke.yml) uses the
[repository-specific Docker image](../docker/README.md) to test a full upstream
NopSCADlib `make_all.py` build. That is a CI check, **not** the normal
Windows modeling workflow.

The repository has a separate **`gh-pages`** branch containing a
holding page. GitHub Pages deployment succeeded automatically after the
branch was created. Actual model documentation is not published or automated
yet. See [Publishing plan](PUBLISHING.md).

## Licensing

NopSCADlib is [GPL-3.0-or-later](https://github.com/nophead/NopSCADlib/blob/master/COPYING).
Checking it out via vcs2l does not change its license. Do not redistribute
NopSCADlib's source without the upstream notices; review the licensing of
individual models that incorporate upstream geometry or code.

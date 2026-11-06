# 2026-011-01.cad.model-archive

Public archive for small, independent OpenSCAD models. A model can have
multiple retained versions, each with its own `.scad` source.

External dependencies are managed with [vcs2l](https://github.com/ros-infrastructure/vcs2l) using `dependencies.repos`.

## Start on Windows (without Docker)

Install [OpenSCAD for Windows](https://openscad.org/downloads.html),
Git, and the shared `brainboxemb-dev-tools` Conda environment from
[`tool.py-dev-env`](https://github.com/brainboxemb/tool.py-dev-env).
From the repository root in PowerShell:

```powershell
.\bootstrap.ps1
.\scripts\open-model.ps1
```

`bootstrap.ps1` creates `ext/` and fetches the pinned NopSCADlib dependency
through `vcs2l`. It can use `vcs` from an activated environment or invoke it
through the shared Conda environment. No global `pip install` or manual
directory creation is necessary; rerunning the script is supported.

The last command opens the example spacer in the **installed OpenSCAD GUI**.
The launcher prefers OpenSCAD Nightly on Windows.
It temporarily sets `OPENSCADPATH` for that launch, so
`include <NopSCADlib/core.scad>;` works without installing a global library.

Open any other model by passing its path:

```powershell
.\scripts\open-model.ps1 -Model "models/<name>/v0.1/scad/main.scad"
```

If PowerShell blocks the script, use the one-off execution-policy option
documented in [the Windows workflow](docs/WORKFLOW.md); do not change your
machine's global policy.

## Structure

```text
dependencies.repos               Pin NopSCADlib commit
ext/NopSCADlib/                  Local fetched checkout; ignored by Git
bootstrap.ps1                    Fetch pinned external libraries into ext/
scripts/open-model.ps1           Launch the Windows OpenSCAD GUI
models/<model>/                  Model description and versions
models/<model>/vX.Y/scad/        Source for a versioned model
models/<model>/source/scad/      Source without numbered versions
examples/spacer/v0.1/scad/       Minimal NopSCADlib example
models/corner_bracket/v0.1/scad/  Corner bracket and interactive design walkthrough
docs/                            Usage and future publication decisions
```

Unversioned models use `source/scad/` to keep NopSCADlib's generated lowercase
`readme.md` separate from the human-written model `README.md` on Windows.

## Model catalog

Current model:
[**Corner bracket — v0.1**](models/corner_bracket/README.md), a configurable
plywood outside-corner bracket with captive M4 nuts and two removable plugs.
Its [design walkthrough](models/corner_bracket/v0.1/scad/design.scad) shows six
construction stages and is used to generate documentation images in CI.

For a minimal NopSCADlib demonstration, try the
[example spacer](examples/spacer/v0.1/scad/spacer.scad).

- [Windows modeling workflow](docs/WORKFLOW.md)
- [Shared CAD toolchain](https://github.com/brainboxemb/docker.scad-toolchain) (CI only)
- [GitHub Pages holding page](https://brainboxemb.github.io/2026-011-01.cad.model-archive/)
- [Generated documentation publication plan](docs/PUBLISHING.md)

Documentation generation is **not required on Windows**. GitHub Actions
uses the centrally built `scad-toolchain-drawing` image to generate a spacer
example plus the corner bracket's STL, BOM, HTML and six design images.
Generated results are retained as CI artifacts; GitHub Pages publishing is
a separate step. The local OpenSCAD launcher is tested independently on Windows.

## Licensing

NopSCADlib is an external GPL-3.0-or-later dependency. Fetching it via vcs2l
does not change its license. Whether an individual model incorporates
NopSCADlib code and is distributed must be assessed separately. No license
has yet been assigned to the archive's own models.

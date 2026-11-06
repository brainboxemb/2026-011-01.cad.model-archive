# 2026-011-01.cad.model-archive

Public archive for small, independent OpenSCAD models. A model can have
multiple retained versions, each with its own `.scad` source.

The archive is deliberately lightweight: **no `project.yml`, Moon or SCons**.
[NopSCADlib](https://github.com/nophead/NopSCADlib) is the modeling/documentation
dependency, pinned in `dependencies.repos` and fetched with
[vcs2l](https://github.com/ros-infrastructure/vcs2l).

## Start on Windows (without Docker)

Install [OpenSCAD for Windows](https://openscad.org/downloads.html), Git,
Python and vcs2l. From the repository root in PowerShell:

```powershell
py -m pip install vcs2l
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
.\scripts\open-model.ps1
```

The last command opens the example spacer in the **installed OpenSCAD GUI**.
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
scripts/open-model.ps1           Launch the Windows OpenSCAD GUI
models/<model>/                  Model description and versions
models/<model>/vX.Y/scad/        Source for a versioned model
models/<model>/source/scad/      Source without numbered versions
examples/spacer/v0.1/scad/       Minimal NopSCADlib example
(no local Dockerfile)           CI uses published shared drawing image
docs/                            Usage and future publication decisions
```

Unversioned models use `source/scad/` to keep NopSCADlib's generated lowercase
`readme.md` separate from the human-written model `README.md` on Windows.

## Model catalog

No finished models have been archived yet. Try the
[example spacer](examples/spacer/v0.1/scad/spacer.scad).

- [Windows modeling workflow](docs/WORKFLOW.md)
- [Shared Docker toolchain (drawing runtime)](https://github.com/brainboxemb/docker.scad-toolchain)
- [GitHub Pages holding page](https://brainboxemb.github.io/2026-011-01.cad.model-archive/)
- [Generated documentation publication plan](docs/PUBLISHING.md)

Documentation generation is **not required on Windows** at this stage.
CI uses the centrally built `scad-toolchain-drawing` image, runs upstream
NopSCADlib document generation, and publishes the example to `gh-pages`
on merges to `main`. Windows
OpenSCAD launcher behavior is checked independently in CI without Docker.

## Licensing

NopSCADlib is an external GPL-3.0-or-later dependency. Fetching it via vcs2l
does not change its license. Whether an individual model incorporates
NopSCADlib code and is distributed must be assessed separately. No license
has yet been assigned to the archive's own models.

# Archive workflow

## Principles

- Keep each small model independent and documented close to its source.
- Prefer NopSCADlib's existing `make_all.py` over creating our own pipeline.
- Use [vcs2l](https://github.com/ros-infrastructure/vcs2l) to fetch NopSCADlib at the exact revision in `dependencies.repos`; `ext/` is not committed.
- Use the existing [BrainboxEmb OpenSCAD Docker runtime](https://github.com/brainboxemb/docker.scad-toolchain) for repeatable OpenSCAD CLI renders, not `tool.scad-project`.
- A model's version is its own working directory. Run NopSCADlib from **inside that directory** (it expects a local `scad/` subdirectory).

## Setup (Windows PowerShell)

From the repository root, with Git and Python installed:

```powershell
py -m pip install vcs2l colorama markdown
vcs import --input dependencies.repos ext
```

The NopSCADlib checkout is now `ext/NopSCADlib`. To open a model in the **OpenSCAD desktop GUI**, start OpenSCAD from a PowerShell session with the local library search path:

```powershell
$root = (Get-Location).Path
$sep = [IO.Path]::PathSeparator
$env:OPENSCADPATH = "$root\ext" + $(if ($env:OPENSCADPATH) { "$sep$env:OPENSCADPATH" } else { "" })
# Launch your installed OpenSCAD GUI from this same session.
```

`OPENSCADPATH` must point to the **parent** of `NopSCADlib`, not to the library directory itself. This is not a global library installation.

## Fast PNG / STL using the existing Docker image

The existing `ghcr.io/brainboxemb/scad-toolchain-openscad` image already includes OpenSCAD, Xvfb and its other OpenSCAD tooling. It does **not** yet provide all dependencies of NopSCADlib's full document-generation pipeline. It is suitable for direct OpenSCAD exports.

Run from the repository root in PowerShell, after `vcs import`. `:edge` is a **mutable development** image; use a verified immutable released tag for a fixed workflow.

PNG preview:

```powershell
docker run --rm --init -v "${PWD}:/work" -w /work -e "OPENSCADPATH=/work/ext:/opt/openscad-libraries" ghcr.io/brainboxemb/scad-toolchain-openscad:edge xvfb-run -a openscad -o examples/spacer/v0.1/preview.png --imgsize=960,720 --autocenter --viewall examples/spacer/v0.1/scad/spacer.scad
```

STL:

```powershell
docker run --rm -v "${PWD}:/work" -w /work -e "OPENSCADPATH=/work/ext:/opt/openscad-libraries" ghcr.io/brainboxemb/scad-toolchain-openscad:edge openscad -o examples/spacer/v0.1/spacer.stl examples/spacer/v0.1/scad/spacer.scad
```

The container's default BOSL2 search path is preserved by appending `/opt/openscad-libraries` in `OPENSCADPATH`.

## NopSCADlib documentation (upstream workflow)

NopSCADlib expects OpenSCAD on `PATH`, **ImageMagick 7** (`magick` command), and Python packages such as `colorama` and `markdown`. The Docker image above does not yet include ImageMagick 7 or all Python requirements; do **not** assume the following works inside it unchanged.

On a Windows host with those tools installed, run from the repository root:

```powershell
$root = (Get-Location).Path
$sep = [IO.Path]::PathSeparator
$env:OPENSCADPATH = "$root\ext" + $(if ($env:OPENSCADPATH) { "$sep$env:OPENSCADPATH" } else { "" })
Push-Location examples/spacer/v0.1
py "$root\ext\NopSCADlib\scripts\make_all.py"
Pop-Location
```

Per the [upstream usage guide](https://github.com/nophead/NopSCADlib/blob/master/docs/usage.md), `make_all.py` works in the *current project directory* and generates, among other things, `readme.md`, assembly pictures, `stls/`, and `bom/`. The source file uses the upstream `//! ` documentation comments and `main_assembly()` / `*_stl()` conventions. The generated `readme.md` belongs to the **version directory**, so do not put handwritten notes in that file; use the model-level `README.md`.

**Not yet verified in this repository:** a complete `make_all.py` run using the pinned NopSCADlib revision, including prerequisites and the resulting generated README/illustrations. The sample should be used to validate that before automating anything.

## Adding a model

1. Create `models/<name>/README.md` as the model index, explaining use, dimensions, print material and versions.
2. Add a `scad/` directory either directly under the model or under `vX.Y/`. Keep source and editable parameters there.
3. Use NopSCADlib's `//! ` comments, `*_stl()` module and `main_assembly()` where NopSCADlib-generated docs are wanted.
4. Run and inspect the upstream generator. Keep the model source, version documentation and chosen deliverables together.
5. Document how the version differs; retain previous versions rather than overwriting them.

## Licensing

NopSCADlib is [GPL-3.0-or-later](https://github.com/nophead/NopSCADlib/blob/master/COPYING). Fetching it with vcs2l or excluding `ext/` from Git **does not alter those terms**. Running tools to generate independent outputs is different from incorporating library code into an OpenSCAD model; the latter can trigger copyleft obligations on distribution. Do not copy upstream library source into this archive without retaining the upstream license and attribution. A repository-wide license for the authored models has **not** been selected yet.

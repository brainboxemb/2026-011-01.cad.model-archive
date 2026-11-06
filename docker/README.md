# Dedicated NopSCADlib runtime

This is a **repository-local Dockerfile**, not another generic BrainboxEmb
toolchain. It extends `ghcr.io/brainboxemb/scad-toolchain-openscad:v0.6.1`.
The shared drawing profile remains unchanged: NopSCADlib needs ImageMagick 7
and a few Python packages, not Inkscape or a second CAD pipeline.

The multi-stage Dockerfile builds ImageMagick 7.1.2-1 from its tagged upstream
source. This avoids silently using Ubuntu's ImageMagick 6 binary with an
unverified `magick` compatibility wrapper.

## Prerequisites

- Docker Desktop on Windows.
- Git, Python and `vcs2l` on the host to fetch NopSCADlib (not included in the image).

## Build locally (PowerShell, from repository root)

```powershell
py -m pip install vcs2l
New-Item -ItemType Directory -Path ext -Force | Out-Null
vcs import --input dependencies.repos ext
docker build -f docker/Dockerfile -t model-archive-nopscadlib:local .
```

## Generate all documents and outputs for an example version

```powershell
docker run --rm --init `
    -v "${PWD}:/work" `
    -w /work/examples/spacer/v0.1 `
    model-archive-nopscadlib:local `
    xvfb-run -a python /work/ext/NopSCADlib/scripts/make_all.py
```

This invokes **upstream NopSCADlib** `make_all.py` directly. It should create:
`readme.md`, `readme.html`, `printme.html`, `bom/`, `stls/`,
and `assemblies/` under the selected version directory.

For other models, change only the working directory from
`/work/examples/spacer/v0.1` to `/work/models/<name>/vX.Y`.

The checkout is provided through `/work/ext/NopSCADlib`; Docker's
`OPENSCADPATH` also retains the existing BOSL2 library path.

## CI validation

[The NopSCADlib smoke workflow](../.github/workflows/nopscadlib-smoke.yml)
builds this image, fetches the pinned library via vcs2l, executes `make_all.py`
on the spacer example and checks for the expected outputs. It is the intended
end-to-end qualification of this Dockerfile.

**Implementation status:** Dockerfile and CI smoke are defined; a successful
CI build/run is required before calling the image validated. Do not publish or
claim an immutable new runtime release before that passes.

## License and maintenance

NopSCADlib remains an external, version-pinned GPL-3.0-or-later dependency;
it is not copied into the image. ImageMagick's own license applies to its
compiled binaries. The repository should retain a clear record of the
upstream tools and exact versions used for generated outputs.

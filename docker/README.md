# CI-only Docker runtime for NopSCADlib

This Docker image is used **only by GitHub Actions**, not for opening models
on Windows. The [Windows workflow](../docs/WORKFLOW.md) launches the locally
installed OpenSCAD GUI using a repository-local `OPENSCADPATH`.

The Dockerfile extends `ghcr.io/brainboxemb/scad-toolchain-openscad:v0.6.1`
with the requirements for upstream NopSCADlib's document generator:

- ImageMagick 7, built from upstream source because Ubuntu 24.04 supplies
  ImageMagick 6 in its default package;
- Python `colorama`, `Markdown` and `codespell`;
- `vcs2l` to download the pinned external NopSCADlib checkout.

The shared BrainboxEmb runtime remains unchanged. We do not need
`scad-toolchain-drawing` or Inkscape here.

The [NopSCADlib smoke workflow](../.github/workflows/nopscadlib-smoke.yml)
builds this image, fetches NopSCADlib using vcs2l **inside Docker**, calls
upstream `scripts/make_all.py` for the sample spacer and checks the resulting
STL, images, BOM and Markdown/HTML.

Current CI builds the generated files as a verification exercise; it does not
publish them to Pages. A separate `gh-pages` branch with a placeholder page exists already, but
published model documentation is not automated yet; see [publication plan](../docs/PUBLISHING.md).

NopSCADlib is checked out at runtime, not vendored in the image. The upstream
GPL-3.0-or-later license remains applicable to its source.

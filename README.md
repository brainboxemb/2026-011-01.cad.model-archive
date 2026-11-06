# 2026-011-01.cad.model-archive

A public collection of small, independent OpenSCAD models.

The archive is deliberately **lightweight**: no `project.yml`, Moon, SCons or custom documentation generator. It uses the upstream **NopSCADlib** conventions and tools, with **vcs2l** to fetch a pinned external dependency.

## Layout

```text
dependencies.repos                Pinned NopSCADlib revision
ext/NopSCADlib/                   Local checkout (ignored by Git)
models/<model>/                   Model overview and, optionally, versions
models/<model>/vX.Y/scad/         OpenSCAD sources for a version
examples/spacer/v0.1/scad/        Small proof-of-concept (not an archived model)
docs/WORKFLOW.md                  Setup, rendering and documentation
```

Each version can stand on its own. When a model needs no separate versions, it may use `models/<model>/scad/` directly.

## Model catalog

No finished models have been archived yet. The [spacer example](examples/spacer/v0.1/scad/spacer.scad) exercises NopSCADlib's `_stl` / `_assembly` conventions.

## Start here

See [Workflow](docs/WORKFLOW.md) for Windows setup, the existing BrainboxEmb Docker image, generating STL/PNG output, and NopSCADlib's own documentation pipeline.

NopSCADlib is fetched from upstream, not vendored. Its GPL-3.0-or-later terms still apply to the upstream code and must be considered when publishing models that incorporate its code. No archive-wide license is assumed at this stage.

**Status:** initial setup / proof of concept. The NopSCADlib end-to-end documentation generation and its container prerequisites still need a verified run.

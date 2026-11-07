# Generated documentation and GitHub Pages

GitHub Actions generates HTML, STL, BOM and illustrated design documentation
using NopSCADlib and publishes it to the `gh-pages` branch.

## Where things live

- [Workflow](../.github/workflows/nopscadlib-smoke.yml): **only** declares
  checkout, generation, artifact upload and publication.
- [Generator](../scripts/ci/generate-docs.sh): invokes the central Docker
  toolchain and NopSCADlib.
- [Illustration renderer](../scripts/ci/render-bracket-steps.sh): creates the
  PNG images for each design tutorial step.
- [Output checks](../scripts/ci/validate-docs.sh): verifies generated files.
- [Pages publisher](../scripts/ci/publish-pages.sh): assembles and commits
  the generated website.
- [Website templates](../site/): homepage, page wrapper and CSS.

**HTML, CSS and website assembly logic do not belong in the workflow YAML.**

## Generator output

The central [CAD drawing image](https://github.com/brainboxemb/docker.scad-toolchain)
provides the tools needed by NopSCADlib. The generator defaults to the **immutable**
`ghcr.io/brainboxemb/scad-toolchain-drawing:v0.6.3` release, rather than
moving `:edge`. `SCAD_DRAWING_IMAGE` can override this for isolated
experiments; production CI should use a verified release. No
repository-local Dockerfile exists.

NopSCADlib generates HTML/Markdown build notes, assembly images, STL previews
and files, and the bill of materials. The corner bracket also generates:
- six images explaining its actual geometry;
- five images demonstrating `hull()` using a rectangular bar;
- nine images comparing 2D versus 3D construction of the inside corner;
- seven images walking through the actual polygon and outside `cs` hull steps;
- twenty-one elephant-foot images: seven fixed-view A stages without the
  corner correction, seven matching B stages with the working correction,
  and seven local C images for the two-surface simplification test;
- editable SVG diagrams for mounting and print-orientation context.

The current bracket uses the **2D square-minus-circle construction**.
Before generating the documentation, CI compares this profile with the
former 19-point polygon profile for several radii and print-relief settings
using [geometry equivalence checks](../scripts/ci/verify-corner-rounding.sh).

The main design manual keeps only **six actual bracket stages** and a
short map telling readers where each subject lives.

- `docs/chamfer-guide.html` owns the real profile and outside `cs` hull,
  then links to the dedicated elephant-foot page instead of duplicating it.
- `docs/ef-hull-experiment.html` owns all elephant-foot explanation:
  fixed-view A/B construction sequences first, followed by the local
  two-surface simplification experiment and XOR material.
- `docs/hull-guide.html` is only the generic rectangular-bar introduction
  to `hull()`.
- `docs/polygon-guide.html` owns the 2D/3D inside-radius explanation.
- `docs/mounting-options.html` owns fixing and fastener alternatives.

This separation is intentional: experimental geometry is not duplicated
inside the production-model walkthrough.

CI checks the printable bracket with the original per-edge relief method
across nine parameter sets. A **local arm-tip XOR regression** additionally
verifies the current miter correction. Separately,
`verify-ef-two-surface-experiment.sh` renders and quantifies the
reference/candidate/XOR/overcut/undercut volumes for the proposed
two-surface simplification without changing the production model.

The source tree keeps just `scad/corner_bracket.scad` and
`scad/inspection.scad` under `scad/`. Tutorials and generated PNGs are
under `design/`, and Markdown/SCAD documentation inputs under `docs/`.
At build time CI temporarily copies `docs/documentation.scad` to `scad/`
for NopSCADlib discovery, then removes that copy before publishing.

OpenSCAD source remains on `main`; generated outputs go to `gh-pages`.
Documentation generation on Windows/workstations is **not supported**.

## Public site

The [model archive](https://brainboxemb.github.io/2026-011-01.cad.model-archive/)
is published from the `gh-pages` branch. Each model version has its own
page, STL/BOM outputs, source SCAD files and design images. The generated
NopSCADlib `readme.html` is wrapped by `site/model-header.html` and
written as `index.html`.

Publishing runs after successful output validation on pushes to `main`.
Verify the GitHub Pages deployment run before assuming the public page
has refreshed.

### Branch previews on the main homepage

The **public site's front page** automatically lists active pull-request
previews under **Branch previews**. Each entry links to the preview homepage
(`previews/pr-<number>/`) and the corresponding GitHub PR; when available,
it also displays the source branch name. Previews are separate from the
published models and are removed automatically after the PR closes.

`publish-pages.sh` updates this section whenever a preview is added,
refreshed, or removed. `update-preview-index.py` scans the existing
`gh-pages/previews/pr-*/index.html` directories; no PR number or preview
URL is hard-coded in `site/index.html`. Preview metadata is stored in
`preview.json` next to each preview homepage and is HTML-escaped when
displayed. **A PR publication does not overwrite the main homepage**:
the script changes only the generated preview-navigation region.
`test-preview-index.py` verifies links, ordering and deletion.

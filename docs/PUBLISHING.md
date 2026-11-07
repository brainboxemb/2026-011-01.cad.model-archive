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
- ten images walking through the different chamfers and a close-up of
  the elephant-foot/side-bevel junction;
- two images from the combined-hull experiment on a straight arm.

The current bracket uses the **2D square-minus-circle construction**.
Before generating the documentation, CI compares this profile with the
former 19-point polygon profile for several radii and print-relief settings
using [geometry equivalence checks](../scripts/ci/verify-corner-rounding.sh).

The main design manual keeps only **six actual bracket stages**.
The extended bar and real-bracket hull explanation live in
`docs/hull-guide.html`; the nine-stage 2D/3D inside-corner comparison
lives in `docs/polygon-guide.html`. The ten-stage chamfer walkthrough,
including a focused junction close-up, lives in `docs/chamfer-guide.html`.
The `docs/mounting-options.html` comparison contains editable SVG
cross-section diagrams for fixing alternatives. The main manual also
illustrates elephant-foot compensation with SVG diagrams.

CI checks the printable bracket with the original per-edge relief method
across nine parameter sets. A **local arm-tip XOR regression** additionally
verifies that the miter hulls remove at least 90% of the local geometric
mismatch where elephant-foot relief meets the outside side bevels.

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

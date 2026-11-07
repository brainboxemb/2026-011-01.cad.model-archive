# Corner bracket — v0.1

The bracket has been refactored in two stages: the inside radius uses 2D
`square()` and `circle()` operations instead of sampled arc points; the
wood-contact elephant-foot relief now uses two local opening hulls and short diagonal miter hulls
instead of individual straight, diagonal and circular cutting wedges.
The original mounting and captive-nut system is unchanged.
The bracket is a prototype; print tolerances and strength have not been physically verified.

## Source layout

```text
scad/
  corner_bracket.scad       Printable parametric model
  inspection.scad           Optional cutaway/section helper
design/
  design.scad               Six-step model walkthrough
  hull_explained.scad       3D hull tutorial
  rounding_explained.scad   Circle and hull examples
  inside_corner_methods.scad  2D/3D inside-corner demonstration
  chamfer_explained.scad   Eight actual chamfer construction stages
  combined_chamfer_hull.scad  Straight-arm single-hull experiment
  *.png                     CI-generated tutorial images (not committed)
docs/
  documentation.scad        NopSCADlib documentation build source
  hull-guide.md             Hull article
  polygon-guide.md          2D vs 3D rounding article
  chamfer-guide.md          2D profile bevels, side hull and print relief
  mounting-options.md       Illustrated fastener alternatives
figures/                    Editable vector diagrams
tests/                      Profile and full-bracket geometry regression fixtures
```

Only the **two files in `scad/`** belong to the actual bracket design;
the other OpenSCAD files are educational illustrations or documentation.
The build temporarily places the documentation driver in `scad/` because
NopSCADlib expects to discover it there; it is not a third model file.

The model has a 20 mm bracket width, 10 mm nominal wall, 40 mm arms, a
2 mm inside-corner radius and two M4 bolt/nut positions by default.
The `plug` part selector lays out the two separate access plugs on their sides.

## How to view

From the archive root after `bootstrap.ps1`:

```powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/corner_bracket.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/design.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/hull_explained.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/rounding_explained.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/inside_corner_methods.scad"
```

In `design.scad`, use the `design_step` dropdown to inspect six sequential
stages: base profile, outside chamfers, nut pockets, print relief, plugs and
fitted plywood preview.

The generated [design documentation](https://brainboxemb.github.io/2026-011-01.cad.model-archive/models/corner_bracket/v0.1/)
focuses on the six model stages, including a more detailed explanation of
elephant-foot relief.

The separate [Hull Guide](docs/hull-guide.md) starts with a simple
rectangular-bar example, then explains the **actual** outside and inner
relief hulls used in the bracket. `hull_explained.scad` and
`rounding_explained.scad` remain available as teaching examples.

The `rounding_explained.scad` tutorial shows two different kinds of corner:
four circles connected with `hull()` to make rounded **outside** corners,
and a **historical** point-based method for the concave inside corner.

The [Chamfer Guide](docs/chamfer-guide.md) gives eight actual geometry illustrations and two annotated diagrams,
including a junction schematic where the elephant-foot
and outside side-edge bevels meet. CI tests that small miter explicitly:
without the added local hulls, a small flat termination remains even
when the whole-bracket volume difference looks negligible.

The [Polygon and rounded-corner guide](docs/polygon-guide.md) compares two
straightforward constructions of the same **inside** radius:
`square() - circle()` with `union()` **before** `linear_extrude()`
(2D first), and `cube() - cylinder()` with `union()` in **3D**.
Its [standalone OpenSCAD demo](design/inside_corner_methods.scad) has
nine Customizer stages and CI-generated illustrations. The real
`corner_bracket.scad` uses the **2D approach** with `$fn=72` on the
corner circle to preserve the old 5-degree curve segmentation.
An isolated [equivalence fixture](tests/inside-corner-equivalence.scad)
compares the old polygon against the new 2D profile across several radius
and print-relief values during CI. Whole-part STL renders were also compared
locally and yielded matching geometry for the tested configurations.

The [documentation entry point](docs/documentation.scad) creates printable
bracket and paired-plug STLs and NopSCADlib assembly documentation. Its design
images are rendered from `design/design.scad` by the CI documentation workflow.

## Mounting alternatives

The [illustrated mounting options](docs/mounting-options.md) compare inside-to-outside
and outside-to-inside M4 bolts, hex versus thin square nuts, accessible
locking flange nuts, and a possible second **inside counter-bracket**.
The conceptual section drawings are editable SVG files in `figures/`.
The [generated HTML comparison](https://brainboxemb.github.io/2026-011-01.cad.model-archive/models/corner_bracket/v0.1/docs/mounting-options.html)
includes the supplied hardware references and explains which options
would need CAD changes.

## Checks before printing or assembly

- Confirm the actual plywood thickness and round its inside corner to match
  `r_in` (default 2 mm) if needed.
- Check measured M4 nut width/thickness and bolt length, particularly the
  remaining closed outside wall `skin` (default 2.4 mm).
- Verify printing orientation, elephant-foot relief, access-plug clearance,
  strength and mating surfaces on test prints.
- Neither a finished joint strength rating nor bolt-length guarantee is
  implied by the generated documentation.

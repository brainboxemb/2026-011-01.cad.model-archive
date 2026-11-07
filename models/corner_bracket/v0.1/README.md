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
  chamfer_explained.scad     Actual chamfer construction stages
  ef_hull_experiment.scad    Detailed EF two-surface experiment
  combined_chamfer_hull.scad Straight-bar hull experiment
  *.png                      CI-generated tutorial images (not committed)
docs/
  documentation.scad         Short NopSCADlib model walkthrough
  chamfer-guide.md           Actual bracket chamfer construction
  ef-hull-experiment.md      Detailed EF experiment and XOR results
  hull-guide.md              General hull() introduction only
  polygon-guide.md           2D vs 3D inside-radius article
  mounting-options.md        Illustrated fastener alternatives
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

For testing the elephant-foot geometry, `ef_corner_correction` is exposed
in the OpenSCAD Customizer. Keep it `true` for the normal model; set it to
`false` to leave the two main EF hulls active while disabling only the
small arm-tip corrections.

## How to view

From the archive root after `bootstrap.ps1`:

```powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/corner_bracket.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/design.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/hull_explained.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/rounding_explained.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/inside_corner_methods.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/ef_hull_experiment.scad"
```

In `design.scad`, use the `design_step` dropdown to inspect six sequential
stages: base profile, outside chamfers, nut pockets, print relief, plugs and
fitted plywood preview.

## Documentation map

The generated [model walkthrough](https://brainboxemb.github.io/2026-011-01.cad.model-archive/models/corner_bracket/v0.1/)
is the short starting point.

From there the subjects are deliberately separated:

- [Chamfer Guide](docs/chamfer-guide.md) — the **actual bracket**:
  complete polygon, inside radius, outside `cs` hull, elephant-foot
  `ef` hull and the current arm-tip junction.
- [Elephant-foot Hull Experiment](docs/ef-hull-experiment.md) — the
  **experiment only**: both EF hull surfaces, hull result, exact missing
  volume, working reference, exact candidate surfaces, candidate hull,
  XOR, overcut and undercut.
- [Hull Guide](docs/hull-guide.md) — a **generic** rectangular-bar
  introduction to `hull()`; no duplicate bracket walkthrough.
- [Polygon Guide](docs/polygon-guide.md) — the inside-radius construction
  using 2D square/circle and the 3D comparison.
- [Mounting Options](docs/mounting-options.md) — fastener and assembly
  alternatives.

The production SCAD remains under `scad/`. Everything in `design/`
is explanatory or experimental and does not replace the printable model.

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

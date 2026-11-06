# Corner bracket — v0.1

This is the **unmodified geometric construction** from the uploaded model,
with English comments/Customizer labels and a local section-inspection helper.
The bracket is a prototype and its dimensions have not been physically verified.

The model has a 20 mm bracket width, 10 mm nominal wall, 40 mm arms, a
2 mm inside-corner radius and two M4 bolt/nut positions by default.
The `plug` part selector lays out the two separate access plugs on their sides.

## How to view

From the archive root after `bootstrap.ps1`:

```powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/corner_bracket.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/design.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/hull_explained.scad"
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/rounding_explained.scad"
```

In `design.scad`, use the `design_step` dropdown to inspect six sequential
stages: base profile, outside chamfers, nut pockets, print relief, plugs and
fitted plywood preview.

The separate `hull_explained.scad` uses a simple rectangular bar to teach
how `hull()` connects two differently sized layers. Its five intermediate
views appear before the real bracket's chamfer code in the generated
[design documentation](https://brainboxemb.github.io/2026-011-01.cad.model-archive/models/corner_bracket/v0.1/).

The `rounding_explained.scad` tutorial shows two different kinds of corner:
four circles connected with `hull()` to make rounded **outside** corners,
and the bracket's concave **inside** corner drawn from sampled points along
a quarter-circle. It also shows why applying `hull()` to the entire L profile
would incorrectly fill the opening between the arms.

The [documentation entry point](scad/documentation.scad) creates printable
bracket and paired-plug STLs and NopSCADlib assembly documentation. Its design
images are rendered from `design.scad` by the CI documentation workflow.

## Checks before printing or assembly

- Confirm the actual plywood thickness and round its inside corner to match
  `r_in` (default 2 mm) if needed.
- Check measured M4 nut width/thickness and bolt length, particularly the
  remaining closed outside wall `skin` (default 2.4 mm).
- Verify printing orientation, elephant-foot relief, access-plug clearance,
  strength and mating surfaces on test prints.
- Neither a finished joint strength rating nor bolt-length guarantee is
  implied by the generated documentation.

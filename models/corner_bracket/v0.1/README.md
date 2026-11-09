# Corner bracket — v0.1

Outside-corner bracket for two plywood panels, with captive M4 nuts and removable access-window plugs.

The production model now follows the same modelling vocabulary used in the archive-wide [OpenSCAD design concepts](../../../docs/design-concepts.md):

1. build the 2D bracket profile;
2. create the outside side-edge chamfer as **keep geometry**;
3. remove elephant-foot compensation as explicit **cut geometry**;
4. remove the fastener pockets, windows and bolt holes as explicit **cut geometry**;
5. keep display-only plywood and installed plugs separate from printable geometry.

The bracket is still a prototype. Print fit, strength and tolerances have not been physically verified.

## Source layout

~~~text
scad/
  corner_bracket.scad          Printable parametric model
  inspection.scad              Optional cutaway/section helper

design/
  design.scad                  Six-step model walkthrough
  chamfer_explained.scad       Ten edge-treatment stages
  hull_explained.scad          General hull tutorial
  inside_corner_methods.scad   2D/3D inside-corner tutorial
  combined_chamfer_hull.scad   Historical/experimental straight-bar hull idea
  *.png                        CI-generated tutorial images

docs/
  documentation.scad           NopSCADlib documentation source
  chamfer-guide.md             Actual bracket edge treatments
  hull-guide.md                hull() and the outer side chamfer
  polygon-guide.md             Inside-radius constructions
  mounting-options.md          Fastener alternatives

tests/
  inside-corner-equivalence.scad
  elephant-foot-equivalence.scad
~~~

Only `scad/corner_bracket.scad` and `scad/inspection.scad` belong to the printable bracket source. The files under `design/`, `docs/` and `tests/` explain or verify that source.

## Main geometry names

The production source intentionally uses descriptive names:

| Name | Meaning |
| --- | --- |
| `bracket_profile_2d()` | complete 2D side profile |
| `profile_body()` | plain extrusion of that profile |
| `outer_chamfer_envelope_2d()` | temporary convex outside outline |
| `outer_side_chamfer_keep_envelope()` | hull-generated envelope for the outside side chamfer |
| `outer_side_chamfered_body()` | real L profile clipped by that keep envelope |
| `elephant_foot_relief_cuts()` | all small print-compensation volumes that are removed |
| `print_compensated_body()` | side-chamfered body after those relief cuts |
| `top_fastener_cut()` | nut pocket, window and bolt-hole cuts for the top arm |
| `vertical_fastener_cut()` | equivalent cuts for the vertical arm |
| `bracket()` | final printable bracket |

The main public geometry parameters are similarly explicit: `bracket_width`, `wall_thickness`, `horizontal_arm_length`, `vertical_arm_length`, `arm_end_chamfer`, `outer_corner_chamfer`, `side_edge_chamfer`, `elephant_foot_relief` and `inside_corner_radius`.

## How the bracket is built

### 1. 2D profile

`base_profile_2d()` draws the L shape, including the arm-end chamfers and the large outside corner chamfer.

`inside_corner_fill_2d()` adds the rounded inside corner using a simple `square() - circle()` construction.

`bracket_profile_2d()` joins those two pieces and `profile_body()` extrudes the result across `bracket_width`.

### 2. Outside side-edge chamfer

The outside side-edge chamfer is easiest to describe as geometry that should **remain**.

`outer_chamfer_envelope_2d()` deliberately fills the open quadrant of the L, giving a convex outside outline. Two differently sized extrusions of that outline are connected with `hull()` in `outer_side_chamfer_keep_envelope()`.

That envelope is then intersected with the real L-shaped `profile_body()`:

~~~openscad
module outer_side_chamfered_body() {
    intersection() {
        profile_body();

        if (side_edge_chamfer > 0)
            outer_side_chamfer_keep_envelope();
        else
            rotate([90, 0, 0])
                linear_extrude(height = bracket_width, center = true)
                    outer_chamfer_envelope_2d();
    }
}
~~~

`intersection()` does not create the chamfer. It only clips the temporary convex envelope back to the real bracket shape.

### 3. Elephant-foot relief

The print compensation is easier to describe the other way around: as the small pieces of material that must **disappear**.

`elephant_foot_relief_cuts()` contains:

- a straight 45-degree cutter along the horizontal plywood-facing edge;
- a straight cutter along the vertical plywood-facing edge;
- a revolved cutter around the rounded inside corner;
- short diagonal cutters where the relief meets the outside side chamfer.

Those cuts are mirrored to both printable side faces and subtracted:

~~~openscad
module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();
        elephant_foot_relief_cuts();
    }
}
~~~

This is intentionally simpler than the former production experiment that tried to describe the relief with several opening hulls. That hull implementation remains only in the regression fixture so CI can compare both solids.

### 4. Fastener cuts

`top_fastener_cut()` and `vertical_fastener_cut()` describe material to remove for the captive nuts, access windows and bolt paths.

The final bracket is therefore straightforward:

~~~openscad
module bracket() {
    difference() {
        print_compensated_body();
        top_fastener_cut();
        vertical_fastener_cut();
    }
}
~~~

## Walkthroughs

Open the production model:

~~~powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/corner_bracket.scad"
~~~

Open the six-step model walkthrough:

~~~powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/design.scad"
~~~

The detailed [Chamfer Guide](docs/chamfer-guide.md) explains the three different edge treatments:

- `arm_end_chamfer` / `outer_corner_chamfer`: coordinates in the 2D profile;
- `side_edge_chamfer`: `hull()` keep envelope + `intersection()`;
- `elephant_foot_relief`: explicit cutter volumes + `difference()`.

The [Hull Guide](docs/hull-guide.md) explains why `hull()` is useful for the **outside side chamfer** and why it is not automatically the right tool for every other edge treatment.

The [Polygon Guide](docs/polygon-guide.md) explains the rounded inside corner.

## Regression checks

CI verifies two important refactors:

- the current `square() - circle()` inside radius against the former point-based polygon;
- the current direct elephant-foot cutters against the former hull implementation across several `side_edge_chamfer`, `elephant_foot_relief` and `inside_corner_radius` values.

The elephant-foot comparison is a near-equivalence check, not a claim that the two implementations are bit-for-bit identical.

## Mounting alternatives

The [mounting options](docs/mounting-options.md) compare the current captive-nut arrangement with other bolt and nut directions. Those alternatives are design studies; only the current bolt-from-inside/captive-nut arrangement is implemented in v0.1.

## Checks before printing or assembly

- Confirm the real plywood thickness and match its inside corner to `inside_corner_radius`.
- Measure the real M4 nuts and check `nut_across_flats`, `nut_thickness` and `nut_clearance`.
- Confirm the remaining `outside_skin` and actual bolt length.
- Test `elephant_foot_relief`, plug clearance and mating surfaces on a short print before relying on the full bracket.
- No finished joint strength rating is implied by the generated documentation.

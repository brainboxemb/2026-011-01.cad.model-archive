# How hull() is used in the Corner Bracket

`hull()` is useful in the bracket, but only for a specific job: creating the **outside side-chamfer keep envelope**.

The elephant-foot print relief no longer uses hulls in production. It is described directly as cut geometry.

For the shared vocabulary of **keep**, **cut** and **clip** geometry, start with the archive-wide [OpenSCAD design concepts](../../../docs/design-concepts.html).

## 1. First see hull() on a simple bar

### A. Plain bar

![Plain rectangular bar](../design/hull_01_original_bar.png)

A rectangular bar starts with square edges.

### B. Full-size layer

![Wide layer](../design/hull_02_wide_layer.png)

The first thin layer has the full footprint.

### C. Smaller layer

![Wide and narrow layers](../design/hull_03_two_layers.png)

A second layer is smaller.

### D. Connect them

![Hull between the two layers](../design/hull_04_hull.png)

~~~openscad
module sloped_hull() {
    hull() {
        wide_layer();
        narrow_layer();
    }
}
~~~

`hull()` fills the space between the two layers with straight sloping faces.

### E. Result

![Sloped bar](../design/hull_05_result.png)

For this simple convex bar, the hull already has the intended outside shape.

## 2. Why the L bracket needs a helper envelope

The real bracket profile has an inward corner. It is concave.

If we hull the real L directly, `hull()` bridges across the open quadrant. That is normal behaviour: a hull is always convex.

So the production model does not ask `hull()` to preserve the L.

Instead it separates the problem:

1. make the real L-shaped `profile_body()`;
2. make a temporary convex outside envelope;
3. use `hull()` only on that convex envelope;
4. clip the result with the real L.

## 3. The temporary outside outline

`outer_chamfer_envelope_2d()` follows the bracket's outside boundary but deliberately fills the inside opening.

~~~openscad
module outer_chamfer_envelope_2d() {
    polygon([
        [horizontal_arm_length, -vertical_arm_length],
        [horizontal_arm_length,
         wall_thickness - arm_end_chamfer],
        [horizontal_arm_length - arm_end_chamfer,
         wall_thickness],
        [-wall_thickness + outer_corner_chamfer,
         wall_thickness],
        [-wall_thickness,
         wall_thickness - outer_corner_chamfer],
        [-wall_thickness,
         -vertical_arm_length + arm_end_chamfer],
        [-wall_thickness + arm_end_chamfer,
         -vertical_arm_length]
    ]);
}
~~~

This shape is not printable. It is only a helper.

## 4. Build the side-chamfer keep envelope

The first extrusion keeps the full outside perimeter but is narrower than the final bracket.

The second extrusion reaches the full `bracket_width`, but its perimeter is inset by `side_edge_chamfer`.

~~~openscad
module outer_side_chamfer_keep_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(
                height = bracket_width - 2 * side_edge_chamfer,
                center = true
            )
                outer_chamfer_envelope_2d();

            linear_extrude(height = bracket_width, center = true)
                offset(delta = -side_edge_chamfer)
                    outer_chamfer_envelope_2d();
        }
}
~~~

With `side_edge_chamfer = 2`, the outer 2 mm on each broad side face slope inward.

This hull is **keep geometry**: it describes the outer volume we want to allow.

## 5. Clip it with the real bracket

The keep envelope is convex and therefore also occupies the open quadrant of the L.

The real bracket is restored with `intersection()`:

~~~openscad
module outer_side_chamfered_body() {
    intersection() {
        profile_body();
        outer_side_chamfer_keep_envelope();
    }
}
~~~

The two operands have different jobs:

- `profile_body()` preserves the real L opening and rounded inside corner;
- `outer_side_chamfer_keep_envelope()` limits the outside side edges.

`intersection()` only keeps material that belongs to both.

## 6. Why elephant-foot relief does not use hull() anymore

The elephant-foot relief is physically different.

We do not need to invent a new outside envelope. We know exactly which small wedges of material should be removed from the print-facing edges.

So production now uses:

~~~openscad
module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();
        elephant_foot_relief_cuts();
    }
}
~~~

That is easier to read:

~~~text
side-chamfered bracket
        -
small print-relief cutters
        =
print-compensated bracket
~~~

The former opening-hull implementation is retained only in `tests/elephant-foot-equivalence.scad` as a regression reference.

## 7. What happened to the combined-hull experiment?

`design/combined_chamfer_hull.scad` is still useful as an experiment on a straight convex bar.

![Combined hull layers](../design/combined_chamfer_layers.png)

![Combined hull comparison](../design/combined_chamfer_comparison.png)

On a straight convex object, several transitions can sometimes be combined elegantly in one hull.

The full L bracket is different because it has a concave opening and several local edge junctions.

The experiment therefore remains educational, not production architecture.

## 8. Practical rule

Use `hull()` when two simple shapes describe a transition you actually want.

Do not use it just because another feature in the same model uses hull.

For this bracket:

| Feature | Production approach |
| --- | --- |
| arm-end chamfers | 2D profile coordinates |
| large outside corner chamfer | 2D profile coordinates |
| outside side-edge chamfer | convex keep envelope made with `hull()`, then clipped |
| elephant-foot relief | explicit cutters + `difference()` |
| nut/window/bolt spaces | explicit cutters + `difference()` |

That split is easier to explain, test and maintain than forcing all edge treatments into one hull-based method.

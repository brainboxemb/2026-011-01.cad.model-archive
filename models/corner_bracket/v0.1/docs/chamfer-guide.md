# Chamfers on the Corner Bracket — from 2D vertices to 3D relief

This guide follows the **actual v0.1 model**, with ten illustrations
generated from [chamfer_explained.scad](../design/chamfer_explained.scad).
You can open that file in OpenSCAD and select `chamfer_step` to inspect
each stage. The examples use the real model modules whenever possible.

Three different features are easily confused:

| Setting | Default | Which edge changes? | Operation |
| --- | ---: | --- | --- |
| `arm_end_chamfer` | 3 mm | Ends of both arms | Coordinates in the **2D polygon** |
| `outer_corner_chamfer` | 6 mm | Large outside corner joining the arms | Coordinates in the **2D polygon** |
| `side_edge_chamfer` | 2 mm | Long outside edges of the printed *side faces* | `offset()` + `hull()` + `intersection()` |
| `elephant_foot_relief` | 0.6 mm | Printed-side contact edges and junctions with the outer bevel | Two local opening hulls, plus corner-miter hulls |

These operations run at different stages. `arm_end_chamfer` and `outer_corner_chamfer` are part of
the initial **profile**, `side_edge_chamfer` changes the **3D side edges**, and
`elephant_foot_relief` removes printing clearance near **both side faces**.

## 1. Begin with the plain L outline

An ordinary L-shaped `polygon()` starts with sharp ends and a sharp
outer corner. This is a **teaching reference**, not the final model.

![L outline without the end and outside corner chamfers](../design/chamfer_01_sharp_profile.png)

## 2. Cut the arm ends and large outside corner in 2D

The production `base_profile_2d()` draws the arm-end chamfers and the
large outside corner directly into the polygon. In the same 2D step,
`inside_corner_fill_2d(inside_corner_radius)` adds the separate **concave radius** using a
square-minus-circle shape. Its construction is explained in the
[Polygon Guide](polygon-guide.html).

![2D profile with end and outside corner chamfers](../design/chamfer_02_profile_chamfers.png)

The following **actual source coordinates** control the 45° cuts:

```openscad
[horizontal_arm_length, wall_thickness-arm_end_chamfer],       // one side of the top arm's end chamfer
[horizontal_arm_length-arm_end_chamfer, wall_thickness],       // other side: arm_end_chamfer mm back
[-wall_thickness+outer_corner_chamfer, wall_thickness],       // first point at the large outside corner
[-wall_thickness, wall_thickness-outer_corner_chamfer],       // second point: outer_corner_chamfer mm down
[-wall_thickness, -vertical_arm_length+arm_end_chamfer],    // vertical arm-end chamfer
[-wall_thickness+arm_end_chamfer, -vertical_arm_length]     // second point at that end
```

For the defaults, `arm_end_chamfer = 3` means a 3 × 3 mm 45° cut at each
arm end. Likewise, `outer_corner_chamfer = 6` creates a 6 × 6 mm 45° cut across
the large outside corner. No `hull()` is involved here.
The tiny `elephant_foot_relief` corrections at the *wood-facing arm tips* are
also represented by the `tip_top`/`tip_vert` point lists.
They are distinct from these larger cuts.

## 3. Extrude the finished profile across the width

The rounded L becomes a **20 mm wide solid** through
`linear_extrude(height = bracket_width, center = true)`. Rotation puts the
width along the Y axis, so the broad side faces are at
`Y = -10` and `Y = +10`.

![2D profile extruded into the initial 3D bracket](../design/chamfer_03_extruded_profile.png)

```openscad
rotate([90,0,0])
    linear_extrude(height=bracket_width, center=true)
        bracket_profile_2d();
```

The side-face edges are still square. We now create the **2 mm bevel**
along those outside edges.

## 4. Why make a convex outer outline?

The temporary `outer_chamfer_envelope_2d()` contains the entire outside perimeter
of the bracket but fills the open space between its arms. This may
look wrong, but the helper is **not** intended for printing.

![Convex outer outline used as a cutting envelope](../design/chamfer_04_convex_outline.png)

An `offset()` applied directly to the original L would also change
its concave inside corner and the plywood contact region. Instead, we
use the *outer* envelope solely to restrict the outside edges, then
recover the original L by intersection.

## 5. Prepare the two inputs to hull()

The blue extrusion keeps the **full outside outline**, but is only
`bracket_width-2*side_edge_chamfer = 16` mm wide: `Y = -8 ... +8`.

The orange extrusion extends across the **full 20 mm width**,
but `offset(delta=-side_edge_chamfer)` makes its X/Z outline **2 mm smaller**
all around. Its outer faces are at `Y = -10` and `Y = +10`.

![Full outline and offset outline, both extruded](../design/chamfer_05_hull_inputs.png)

```openscad
rotate([90,0,0]) {
    // Full outline, narrower Y range
    linear_extrude(height=bracket_width-2*side_edge_chamfer, center=true)
        outer_chamfer_envelope_2d();
    // Inset outline, full Y range
    linear_extrude(height=bracket_width, center=true)
        offset(delta=-side_edge_chamfer) outer_chamfer_envelope_2d();
}
```

This is different from two stacked flat plates: the **two extrusions
overlap** in the centre and have different side-face extents.

## 6. Hull joins the two outside envelopes

`hull()` wraps both extrusions and connects their outer boundaries.
From the unchanged middle at `Y = ±8` to the smaller outline at
`Y = ±10`, it produces a sloping 2 mm side-edge transition.

![Convex hull combining the full and inset envelopes](../design/chamfer_06_hull_envelope.png)

```openscad
rotate([90,0,0]) hull() {
    linear_extrude(height=bracket_width-2*side_edge_chamfer, center=true)
        outer_chamfer_envelope_2d();
    linear_extrude(height=bracket_width, center=true)
        offset(delta=-side_edge_chamfer) outer_chamfer_envelope_2d();
}
```

The envelope is convex, so the **inside of the L is filled in**.
This is expected and still not a printable part.

## 7. Intersect the hull with the real L

`intersection()` keeps only the material shared by the true
extruded L and the chamfer envelope. This removes the unwanted
filled-in region and retains the actual concave inside radius.

![Actual L bracket with outside side-edge chamfers](../design/chamfer_07_intersection.png)

```openscad
intersection() {
    profile_body();
    outer_side_chamfer_keep_envelope();
}
```

This is the role of `outer_side_chamfered_body()` in the model. Changing `side_edge_chamfer` changes
the side-edge bevel; it does **not** replace the profile's `arm_end_chamfer`,
`outer_corner_chamfer` or `inside_corner_radius`.

## 8. Apply hull-based elephant-foot relief

The bracket rests on a **side face** while printing. Bulging first
layers could prevent the L's inner surfaces from seating against the
plywood. The parameter `elephant_foot_relief = 0.6` mm removes material near the
wood-facing edges at `Y = -10` and `Y = +10`.

**Left:** `outer_side_chamfered_body()` with only the outer side-edge bevels.
**Right:** `print_compensated_body()` after the new inner-opening relief
has been subtracted. Neither has nut holes yet.

![Before and after wood-contact edge relief](../design/chamfer_08_print_relief.png)

Instead of moving separate triangular cutters along each line and
revolving another cutter around the arc, the production code:

1. Builds the empty area between the arms with
   `inside_opening_2d()`. This **convex opening** has a straight
   boundary along both plywood faces and a circular inner transition.
2. At `Y = ±9.4`, uses that original 2D opening; at `Y = ±10`,
   expands it by 0.6 mm with `offset(delta=elephant_foot_relief)`.
3. Uses **one local hull per side** to connect those two profiles.
4. Adds **two more short hulls per printed side** where the relief meets
   the diagonal `side_edge_chamfer` bevels at the arm ends. Those junctions otherwise
   leave a visible flat termination at the corner.
5. Subtracts the opening and miter hulls from the outside-chamfered
   body with `difference()`.

Why not just one hull from one printed side to the other? A global
convex hull would bridge **both expanded ends**, enlarging the opening
through the whole central width. Two local hulls avoid that mistake.

```openscad
module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();                      // outside: side_edge_chamfer hull bevel
        if (elephant_foot_relief > 0) {
            inside_relief_envelope(); // inner plywood-facing edges
            relief_corner_miters();  // diagonal arm-tip junctions
        }
    }
}
```

### Close-up: the corner where two chamfers meet

The broad inner-opening hulls by themselves leave a small unwanted
termination where the elephant-foot allowance meets a diagonal outer
side-edge bevel. This is hard to see in a full model view and barely
changes the overall mesh volume. A separate **small triangular profile**
gets swept along each local diagonal with `hull()`.

![Before, small diagonal hull cutter and completed tip junction](../design/chamfer_10_corner_junction.png)

**Left:** inner-opening hulls only. **Middle:** isolated diagonal miter
cutting hull. **Right:** both opening and miter hulls applied. The
figure crops the horizontal arm-tip corner for inspection; the production
model also handles the opposite side and the other arm.

A dedicated CI test clips the **symmetric difference** with the former
model to just these four junctions. It verifies that adding the
miter hulls removes at least 90% of the local defect volume across the
supported nonzero `side_edge_chamfer`/`elephant_foot_relief` combinations. This supplements the
whole-model 0.1% volume tolerance.

The diagrams locate the small 45-degree contact-edge relief:

![Simplified elephant-foot relief section](../figures/elephant-foot-section.svg)

![Location of plywood-facing relief edges](../figures/elephant-foot-edges.svg)

## 9. Final bracket and regression checks

The final `bracket()` removes the nut access windows and bolt holes
from `print_compensated_body()`.

![Final bracket with chamfers, pockets and relief](../design/chamfer_09_final.png)

The earlier [single-hull straight-bar experiment](hull-guide.html#4-earlier-single-hull-experiment-on-a-straight-bar)
is still documented, but the **actual L bracket has now changed**:
the old `ef_cuts()` wedges were removed. A regression test compares
the complete new and old solids at several `side_edge_chamfer`, `elephant_foot_relief` and `inside_corner_radius`
settings. Expect small differences at intersections of the old
individual cutters; the new construction is an intentional geometric
refactor, **not a physical fit or strength verification**.

For the mathematical principle and its rectangular-bar introduction,
see the separate [Hull Guide](hull-guide.html).

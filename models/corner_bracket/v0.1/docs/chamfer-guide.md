# Chamfers on the Corner Bracket — from 2D vertices to 3D relief

This guide follows the **actual v0.1 model**, with nine illustrations
generated from [chamfer_explained.scad](../design/chamfer_explained.scad).
You can open that file in OpenSCAD and select `chamfer_step` to inspect
each stage. The examples use the real model modules whenever possible.

Three different features are easily confused:

| Setting | Default | Which edge changes? | Operation |
| --- | ---: | --- | --- |
| `c` | 3 mm | Ends of both arms | Coordinates in the **2D polygon** |
| `ce` | 6 mm | Large outside corner joining the arms | Coordinates in the **2D polygon** |
| `cs` | 2 mm | Long outside edges of the printed *side faces* | `offset()` + `hull()` + `intersection()` |
| `ef` | 0.6 mm | Edges where the printed side meets the *plywood contact faces* | Small subtractive cutters |

These operations run at different stages. `c` and `ce` are part of
the initial **profile**, `cs` changes the **3D side edges**, and
`ef` removes printing clearance near **both side faces**.

## 1. Begin with the plain L outline

An ordinary L-shaped `polygon()` starts with sharp ends and a sharp
outer corner. This is a **teaching reference**, not the final model.

![L outline without the end and outside corner chamfers](../design/chamfer_01_sharp_profile.png)

## 2. Cut the arm ends and large outside corner in 2D

The production `sharp_profile()` draws the arm-end chamfers and the
large outside corner directly into the polygon. In the same 2D step,
`inside_corner_2d(r_in)` adds the separate **concave radius** using a
square-minus-circle shape. Its construction is explained in the
[Polygon Guide](polygon-guide.html).

![2D profile with end and outside corner chamfers](../design/chamfer_02_profile_chamfers.png)

The following **actual source coordinates** control the 45° cuts:

```openscad
[armH, t-c],       // one side of the top arm's end chamfer
[armH-c, t],       // other side: c mm back
[-t+ce, t],       // first point at the large outside corner
[-t, t-ce],       // second point: ce mm down
[-t, -armV+c],    // vertical arm-end chamfer
[-t+c, -armV]     // second point at that end
```

For the defaults, `c = 3` means a 3 × 3 mm 45° cut at each
arm end. Likewise, `ce = 6` creates a 6 × 6 mm 45° cut across
the large outside corner. No `hull()` is involved here.
The tiny `ef` corrections at the *wood-facing arm tips* are
also represented by the `tip_top`/`tip_vert` point lists.
They are distinct from these larger cuts.

## 3. Extrude the finished profile across the width

The rounded L becomes a **20 mm wide solid** through
`linear_extrude(height = W, center = true)`. Rotation puts the
width along the Y axis, so the broad side faces are at
`Y = -10` and `Y = +10`.

![2D profile extruded into the initial 3D bracket](../design/chamfer_03_extruded_profile.png)

```openscad
rotate([90,0,0])
    linear_extrude(height=W, center=true)
        profile();
```

The side-face edges are still square. We now create the **2 mm bevel**
along those outside edges.

## 4. Why make a convex outer outline?

The temporary `outer_shape()` contains the entire outside perimeter
of the bracket but fills the open space between its arms. This may
look wrong, but the helper is **not** intended for printing.

![Convex outer outline used as a cutting envelope](../design/chamfer_04_convex_outline.png)

An `offset()` applied directly to the original L would also change
its concave inside corner and the plywood contact region. Instead, we
use the *outer* envelope solely to restrict the outside edges, then
recover the original L by intersection.

## 5. Prepare the two inputs to hull()

The blue extrusion keeps the **full outside outline**, but is only
`W-2*cs = 16` mm wide: `Y = -8 ... +8`.

The orange extrusion extends across the **full 20 mm width**,
but `offset(delta=-cs)` makes its X/Z outline **2 mm smaller**
all around. Its outer faces are at `Y = -10` and `Y = +10`.

![Full outline and offset outline, both extruded](../design/chamfer_05_hull_inputs.png)

```openscad
rotate([90,0,0]) {
    // Full outline, narrower Y range
    linear_extrude(height=W-2*cs, center=true)
        outer_shape();
    // Inset outline, full Y range
    linear_extrude(height=W, center=true)
        offset(delta=-cs) outer_shape();
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
    linear_extrude(height=W-2*cs, center=true)
        outer_shape();
    linear_extrude(height=W, center=true)
        offset(delta=-cs) outer_shape();
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
    profile_extrusion();
    side_chamfer_env();
}
```

This is the role of `body()` in the model. Changing `cs` changes
the side-edge bevel; it does **not** replace the profile's `c`,
`ce` or `r_in`.

## 8. Apply elephant-foot relief on the contact edges

The bracket is printed on one of its flat side faces. A first-layer
bulge can interfere with the plywood surfaces. The model therefore
removes a small triangular section at the junction between the
side faces and **wood-facing edges**, using `ef=0.6` mm.

**Left:** `body()`, before relief. **Right:** the same body after
`difference() { body(); ef_cuts(); }` — with **no nut holes yet**.

![Before and after wood-contact edge relief](../design/chamfer_08_print_relief.png)

The straight contact edges use extruded triangular cutters.
The rounded inside corner uses a swept cutter
(`rotate_extrude()`); angled end transitions have separate
cutters. These details make `ef_cuts()` more complicated than the
simple `cs` outer bevel.

The existing diagrams show **where** the print-bed bulge and
the relief occur:

![Simplified 45-degree elephant-foot relief section](../figures/elephant-foot-section.svg)

![Location of plywood-facing relief edges](../figures/elephant-foot-edges.svg)

## 9. Final body and what is still experimental

The final `bracket()` subtracts the nut access pockets, bolt holes
and elephant-foot relief from the chamfered body.

![Final bracket with chamfers, pockets and relief](../design/chamfer_09_final.png)

We have also started a [combined hull experiment](hull-guide.html#3-experiment-can-hull-also-handle-elephant-foot-relief).
For a **convex straight arm**, one hull can generate both a top
bevel and a lower elephant-foot allowance by joining four
horizontal outlines. That **does not yet prove** equivalence for
the complete L with its rounded inner corner and diagonal joins.
Until the full model is checked, `ef_cuts()` stays in the
printable source.

For the mathematical principle and its rectangular-bar introduction,
see the separate [Hull Guide](hull-guide.html).

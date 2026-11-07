# Chamfers on the Corner Bracket — from 2D vertices to 3D relief

This guide follows the **actual v0.1 model**, with ten illustrations
generated from [chamfer_explained.scad](../design/chamfer_explained.scad).
You can open that file in OpenSCAD and select `chamfer_step` to inspect
each stage. The examples use the real model modules whenever possible.

Three different features are easily confused:

| Setting | Default | Which edge changes? | Operation |
| --- | ---: | --- | --- |
| `c` | 3 mm | Ends of both arms | Coordinates in the **2D polygon** |
| `ce` | 6 mm | Large outside corner joining the arms | Coordinates in the **2D polygon** |
| `cs` | 2 mm | Long outside edges of the printed *side faces* | `offset()` + `hull()` + `intersection()` |
| `ef` | 0.6 mm | Printed-side contact edges and junctions with the outer bevel | Two local opening hulls, plus small local correction hulls |

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

![Full outline and offset outline, both extruded](../design/chamfer_05_cs_hull_inputs.png)

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

![Convex hull combining the full and inset envelopes](../design/chamfer_06_cs_hull_envelope.png)

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

![Actual L bracket with outside side-edge chamfers](../design/chamfer_07_cs_body.png)

```openscad
intersection() {
    profile_extrusion();
    side_chamfer_env();
}
```

This is the role of `body()` in the model. Changing `cs` changes
the side-edge bevel; it does **not** replace the profile's `c`,
`ce` or `r_in`.

## 8. Apply elephant-foot relief along the complete inside L

After `body()` is finished, the outside `cs` chamfers are already correct.
The next task is different: remove a small amount of material along the
**wood-contact side of the L**.

The current production implementation describes that complete inside path once
with `inside_opening_2d()`.

![Inside opening used as the ef reference](../design/chamfer_08_inside_opening.png)

The boundary of this helper follows:

```text
horizontal inside face
        ↓
rounded r_in corner
        ↓
vertical inside face
```

For one Y side, the model makes two very thin versions of that opening:

- the normal opening at `W/2 - ef`;
- the opening expanded by `ef` at `W/2`.

![Two layers used for one ef hull](../design/chamfer_09_ef_layer_inputs.png)

A short `hull()` between those layers creates the 45-degree transition.
Only the part overlapping the real bracket is ultimately removed.

![Relief volume on one side](../design/chamfer_10_ef_one_side.png)

The same local operation is repeated on the opposite Y side.

![Relief volume on both sides](../design/chamfer_11_ef_both_sides.png)

After subtracting those two hulls, the main elephant-foot relief is complete:
both straight inside faces and the rounded corner are handled as one
continuous path.

![Main ef relief before the tiny arm-end correction](../design/chamfer_12_before_end_correction.png)

### The small remaining arm-tip junction

At the very end of each arm, the `ef` relief meets the diagonal `cs`
side chamfer. The broad inside-opening hull does not completely form that
short diagonal meeting surface, leaving a small flat termination.

The production model removes that last tiny piece with a separate local
correction.

![Before correction, correction volume and final junction](../design/chamfer_13_end_correction.png)

The three crops are deliberately read left to right:

**Left:** main elephant-foot relief already applied.  
**Middle:** only the small additional cutting volume.  
**Right:** final `cs` / `ef` junction.

The complete relief is then:

```openscad
module chamfered_body() {
    difference() {
        body();
        if (ef > 0) {
            inside_relief_envelope(); // continuous main relief
            relief_corner_miters();   // four small arm-tip corrections
        }
    }
}
```

![Complete body after cs and ef](../design/chamfer_14_final_relief.png)

The dedicated
[Elephant-foot guide](ef-cs-junction-guide.html)
explains this construction in much more detail and compares it with the former
explicit per-edge cutter implementation.

## 9. Final bracket and regression checks

The final `bracket()` removes the nut access windows and bolt holes
from `chamfered_body()`.

![Final bracket with chamfers, pockets and relief](../design/chamfer_15_final_bracket.png)

The former explicit `ef_cuts()` implementation is preserved in the regression
fixture rather than in the printable model. CI compares that independent
reference with the current hull-based relief at several `cs`, `ef` and `r_in`
settings. The comparison is intentionally geometric; it is **not** a physical
fit or strength verification.

For the mathematical principle and its rectangular-bar introduction,
see the separate [Hull Guide](hull-guide.html).

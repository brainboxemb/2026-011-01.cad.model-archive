# Chamfers on the Corner Bracket

This is the **one detailed walkthrough** of chamfers in the *actual*
[Corner Bracket model](../scad/corner_bracket.scad). It follows the
construction order: **complete 2D polygon → rounded inside corner → 3D
body → outside chamfers → elephant-foot relief → corner junctions**.

The [Polygon Guide](polygon-guide.html) explains *how* the inside radius
is built. The [Hull Guide](hull-guide.html) teaches the general
`hull()` operation with a simple rectangular bar. **This page is where
those ideas are applied to the real bracket.**

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `c` | 3 mm | 45° cuts at the two arm ends, part of the original polygon |
| `ce` | 6 mm | 45° cut at the outside corner, also part of the polygon |
| `cs` | 2 mm | Bevel along the outside edges of the two broad printed faces |
| `ef` | 0.6 mm | Print-bed relief along the plywood contact edges, on both printed faces |
| `r_in` | 2 mm | Rounded *inside* corner of the L; not an edge chamfer |

## 1. The actual profile is already a complete polygon

There is **no preliminary, plain L polygon in the production model**.
`sharp_profile()` defines the *entire* outline of the bracket,
including the outer corner (`ce`), both arm-end chamfers (`c`) and
the short `ef` bevels at the wood-facing arm tips.

![The real complete polygon, before the inside radius is added](../design/chamfer_02_profile_chamfers.png)

The critical points are already in that one `polygon()`:

```openscad
module sharp_profile() {
    polygon(concat(tip_top, [
        [armH, t - c], [armH - c, t], // top arm end, c
        [-t + ce, t], [-t, t - ce],  // outer corner, ce
        [-t, -armV + c], [-t + c, -armV] // upright arm end, c
    ], tip_vert, [[0, 0]]));
}
```

The name `sharp_profile()` only means that its **inside corner**
at `[0,0]` is still sharp. It does **not** mean that its arm
ends or outside corner are unchamfered.

`profile()` then makes **one addition** to this complete polygon:
the small inside fillet made by `inside_corner_2d(r_in)`, using a
2D square minus a circle. That fillet is added with `union()`.
See the [Polygon Guide](polygon-guide.html) for its construction.

![The same polygon after adding only the rounded inside-corner piece](../design/chamfer_02_inside_radius_added.png)

The difference between these two pictures is **only** the small
inside fillet. The arm ends and outside corner do not change.

Finally, `linear_extrude(height = W, center = true)` and
`rotate([90,0,0])` turn this profile into a 20 mm-wide solid:
its broad printed faces lie at **Y = −10 and +10 mm**.

![Extruded bracket before 3D side-edge chamfers](../design/chamfer_03_extruded_profile.png)

## 2. Outside side-edge chamfers: `cs`

The `c` and `ce` cuts above were drawn in **2D**. The outer
side-edge bevel `cs` is different: it changes the **3D thickness
edges** near Y = ±10.

The model constructs a temporary **convex outer envelope**,
`outer_shape()`. It *deliberately fills the open inside of the L*,
because this is only a helper for the outside edges.

![Convex outside helper used for the side chamfer](../design/chamfer_04_convex_outline.png)

Two overlapping solids form the input to `hull()`:

| First input | Second input |
| --- | --- |
| Full outside outline | Outline inset using `offset(delta = -cs)` |
| Width `W - 2*cs = 16` mm | Full width `W = 20` mm |
| Y from −8 to +8 mm | Y from −10 to +10 mm |

![The two inputs of the side-edge hull](../design/chamfer_05_hull_inputs.png)

```openscad
module side_chamfer_env() {
    rotate([90,0,0]) hull() {
        linear_extrude(height=W-2*cs, center=true)
            outer_shape();                   // full outline, narrow Y
        linear_extrude(height=W, center=true)
            offset(delta=-cs) outer_shape(); // inset outline, full Y
    }
}
```

The outer boundary moves inward by **2 mm** between Y = ±8
and Y = ±10. `hull()` joins these boundaries with sloping
faces. The resulting helper is still convex and fills the L opening.

![Convex hull envelope before clipping back to the real L](../design/chamfer_06_hull_envelope.png)

The **next operation is essential**:
`intersection()` with the true extruded `profile()` removes
the unwanted convex fill. Only the real L with its outside
side-edge bevels remains.

![Actual body after the outside side-edge hull and intersection](../design/chamfer_07_intersection.png)

## 3. Elephant-foot relief: the second hull construction

The bracket is printed on a broad Y-facing side. With the defaults,
`W=20` and `ef=0.6`, each print side gets its own local transition
between **Y=9.4 mm** and **Y=10.0 mm** (and mirrored at negative Y).

This section deliberately follows the **same five-step pattern** as the
outside `cs` hull above.

### A. First hull surface — unchanged cutter profile

The elephant-foot operation does not hull the L-shaped bracket itself.
It hulls a **cutting shape on the wood side of the L**.

In X/Z, `inside_opening_2d()` occupies the area at **x ≥ 0 and z ≤ 0**,
so its boundary lies directly against both wood-contact faces: `z=0` for
the horizontal arm and `x=0` for the vertical arm. At the inside corner,
the cutter boundary follows the same `r_in` curve as the bracket.

The first thin copy of that cutter is placed at Y=9.4 mm without an
offset:

![First elephant-foot hull surface](../design/efh_02_inner_main_input.png)

```openscad
opening_layer(W/2 - ef);
```

### B. Second hull surface — expanded opening

At the actual print face, Y=10.0 mm, the same opening is expanded by
`ef=0.6`:

![Second elephant-foot hull surface](../design/efh_03_outer_main_input.png)

```openscad
opening_layer(W/2, ef);
```

### C. Both hull surfaces together

These are the two children passed to `hull()` for the +Y print side:

![Both elephant-foot hull surfaces](../design/efh_04_both_main_inputs.png)

The −Y side uses the mirrored pair.

### D. Resulting hull volume

`hull()` connects the two surfaces with the 45° transition:

![Elephant-foot hull volume](../design/efh_05_main_hull.png)

```openscad
module inside_relief_envelope() {
    if (ef > 0)
        for (side=[-1,1])
            hull() {
                opening_layer(side*(W/2-ef));
                opening_layer(side*W/2, ef);
            }
}
```

### E. Subtract the hull from the real body

Subtracting both local hulls from `body()` gives the main
elephant-foot relief along the straight plywood-contact faces and the
rounded inside corner:

![Bracket after the two main elephant-foot hulls](../design/efh_06_main_result.png)

That is the complete **second hull walkthrough**: input A, input B,
both inputs, hull, subtraction result.

## 4. Arm-tip junction

At the arm end, the main elephant-foot hull meets the existing diagonal
`cs` side bevel. The two main hulls leave a small local mismatch:

![Exact missing arm-tip cutting volume](../design/efh_07_missing_tip_volume.png)

The current production model adds a short local miter hull at that
junction. This gives the working reference result:

![Working arm-tip result](../design/efh_09_reference_result.png)

```openscad
module chamfered_body() {
    difference() {
        body();
        if (ef > 0) {
            inside_relief_envelope();
            relief_corner_miters();
        }
    }
}
```

Whether that local correction can be folded back into **only the two
main hull surfaces** is deliberately kept out of this construction
guide. It is tested step by step, including the exact input surfaces,
candidate hull, XOR, overcut and undercut, in the
[Elephant-foot Hull Experiment](ef-hull-experiment.html).

## 5. What is checked, and what is not

The CI test `verify-elephant-foot-hull.sh` compares the
complete bracket with the former per-edge cutter implementation,
including its mounting holes. A second check isolates the
four arm-tip junctions. Both tests passed for the supported
parameter combinations in PR #10.

The geometry has **not** yet been physically test-printed;
clearance, strength and the visual quality of every bevel
still need checking.

For a first introduction to `hull()`, continue with the
[short Hull Guide](hull-guide.html). For the mathematical
construction of the inside radius, use the
[Polygon Guide](polygon-guide.html).

# Elephant-foot relief on the Corner Bracket

This page explains the elephant-foot compensation in the Corner Bracket from
the beginning.

It compares two real implementations:

- the **former per-edge cutter solution**, preserved in
  `tests/elephant-foot-equivalence.scad`;
- the **current hull-based production solution** in
  `scad/corner_bracket.scad`.

The aim is not to prove that one implementation is cleverer. The aim is to make
the geometry understandable enough that a future change can be judged on its
actual merits.

## 1. First: what problem are we solving?

The bracket has two wood-contact faces:

- the underside of the horizontal arm;
- the inside face of the vertical arm.

Those faces meet through the rounded inside corner `r_in`.

The elephant-foot parameter `ef` removes a small amount of material near the
two broad printed side faces of the bracket. With the default values:

```text
W  = 20 mm
ef = 0.6 mm
```

the relief acts only in the first 0.6 mm from each Y side.

The intended path is continuous:

```text
horizontal inside face
        ────────────────┐
                        )
                       )  rounded inside corner r_in
                      )
                      │
                      │ vertical inside face
                      │
```

The relief should follow that complete path on **both** broad Y sides of the
bracket.

The small arm-end bevels in the 2D profile are a separate but related detail.
The production profile already contains:

```openscad
tip_top  = (ef > 0)
    ? [[armH - ef, 0], [armH, ef]]
    : [[armH, 0]];

tip_vert = (ef > 0)
    ? [[-ef, -armV], [0, -armV + ef]]
    : [[0, -armV]];
```

Those two point pairs make the wood-facing relief continue around the two arm
tips in the X/Z profile itself. Both the former and the current implementation
use this same profile geometry.

So the comparison below is about the **long inside edges, the rounded corner,
and the junction with the side chamfer `cs`**.

![Simplified elephant-foot relief section](../figures/elephant-foot-section.svg)

![Location of the plywood-facing relief edges](../figures/elephant-foot-edges.svg)

## 2. The bracket before elephant-foot relief

Before `ef` is applied, the model has already built the real L and applied the
normal `cs` side-edge chamfers.

![Bracket after cs, before ef](../design/chamfer_07_cs_body.png)

This solid is `body()`.

That ordering matters:

```text
2D L profile
   ↓
extrude over W
   ↓
apply cs
   ↓
body()
   ↓
apply ef
```

We do **not** rebuild the bracket for `ef`. We start from the already valid
`body()`.

---

# Part A — former solution: explicit cutters for every part of the path

The former implementation is preserved in
`tests/elephant-foot-equivalence.scad` as `former_ef_cuts()`.

Its idea is very direct:

> If the relief has a straight part, make a straight cutter.  
> If it turns around a radius, make a curved cutter.  
> If it meets a diagonal `cs` edge, make a diagonal cutter.

That makes the physical intent fairly easy to recognise in the code.

## 3. Former step 1: define the 45-degree wedge

The basic relief is a triangular cross-section.

In the historical code the profile is:

```openscad
module former_wedge_profile() {
    polygon([
        [W/2-ef-1, -1],
        [W/2+1,    -1],
        [W/2+1,    ef+1]
    ]);
}
```

The extra 1 mm around the useful triangle is deliberate overlap. The cutter is
allowed to extend outside the part because it will later be subtracted from the
real bracket.

Conceptually the useful part is simply:

```text
       /
      /  ef
_____/
```

## 4. Former step 2: cut the horizontal inside edge

The wedge profile is extruded along the horizontal arm.

That handles the straight part from the inside radius towards the horizontal
arm tip.

In simplified form:

```openscad
translate([r_in, 0, 0])
    rotate([90, 0, 90])
        linear_extrude(height = armH + 1 - r_in)
            former_wedge_profile();
```

This is easy to understand: one straight edge gets one straight cutter.

## 5. Former step 3: cut the vertical inside edge

The same wedge is rotated again and extruded along the vertical arm.

So the second straight part gets a second explicit cutter.

Again, the logic is local and direct:

```text
horizontal edge → one wedge extrusion
vertical edge   → one wedge extrusion
```

## 6. Former step 4: make a separate curved cutter for `r_in`

The two straight cutters do not automatically follow the rounded inside corner.

The old implementation therefore creates a third cutter with
`rotate_extrude()`.

That cutter sweeps a small polygon around the inside radius.

This works, but it introduces a second geometric construction method:

- straight edges use `linear_extrude()`;
- the radius uses `rotate_extrude()`.

The historical code also contains small angle margins such as 89° and 92° so
the curved cutter overlaps the straight cutters instead of leaving tiny gaps.

That is practical, but it is one of the reasons the old implementation is less
generic than it first appears.

## 7. Former step 5: handle the `cs` / `ef` junction explicitly

At each arm tip the inside relief reaches a diagonal side chamfer created by
`cs`.

The former implementation handles that with
`former_edge_wedge()`.

There are two diagonal cases per Y side:

- one at the horizontal arm tip;
- one at the vertical arm tip.

The whole construction is mirrored to the other Y side.

So the old solution is effectively:

```text
per Y side:
    straight horizontal cutter
    straight vertical cutter
    curved r_in cutter
    diagonal horizontal-tip cutter
    diagonal vertical-tip cutter

mirror to the other Y side
```

## 8. What is good about the former solution?

Its strongest property is **locality**.

If you want to know what cuts the horizontal edge, there is a horizontal-edge
cutter. If you want to know what happens at the radius, there is a radius
cutter.

That is useful when debugging a single edge.

It also already treats the `cs` / `ef` arm-tip junction as a local problem,
which turned out to be geometrically correct.

## 9. What is awkward about the former solution?

The inside L is one continuous physical path, but the code describes it as
several unrelated constructions.

That creates duplicated geometric knowledge:

- the straight horizontal edge has its own coordinates;
- the straight vertical edge has its own coordinates;
- the radius has its own centre and angular sweep;
- the arm tips have their own local coordinate frames.

If `r_in`, the arm dimensions, or the way the inside corner is represented
changes, more than one construction may need to be checked.

The old solution also relies on deliberate overlap values and special angular
margins. They are not wrong, but they make the code harder to generalise.

---

# Part B — current solution: describe the whole inside L once

The current production implementation takes a different approach.

Instead of constructing a cutter for every edge, it first describes the
**empty space between the two arms**.

The boundary of that empty space is exactly the path the relief must follow.

## 10. Current step 1: describe the inside opening

The production module is `inside_opening_2d()`.

The important idea is not the large temporary square. The important part is its
boundary:

```text
horizontal inside face
        ↓
rounded r_in corner
        ↓
vertical inside face
```

The rounded corner comes from the same `inside_corner_2d(r_in)` geometry that
is already used to build the real bracket profile.

That gives the current approach its main architectural advantage:

> the bracket and the elephant-foot relief derive the inside radius from the
> same geometric definition.

The opening is shown here as a thin 3D illustration:

![Inside opening used by the current ef construction](../design/chamfer_08_inside_opening.png)

The large filled region is only a helper. The boundary is what matters.

## 11. Current step 2: make two very thin opening layers

For one Y side, the model makes two almost-zero-thickness layers.

The inner layer is `ef` away from the outside face and uses the normal opening:

```text
Y = W/2 - ef
expansion = 0
```

The outer layer lies at the side face and expands the opening by `ef`:

```text
Y = W/2
expansion = ef
```

The two inputs are visible here:

![Two opening layers for one ef side](../design/chamfer_09_ef_layer_inputs.png)

The distance between the layers and the amount of expansion are both `ef`.
With the defaults they are both 0.6 mm, so the transition is 45 degrees.

## 12. Current step 3: hull the two layers on one side

The production code connects those two layers with `hull()`:

```openscad
hull() {
    opening_layer(W / 2 - ef);
    opening_layer(W / 2, ef);
}
```

This produces one continuous cutter following:

- the horizontal inside face;
- the complete rounded inside corner;
- the vertical inside face.

There is no separate straight-edge cutter and no separate
`rotate_extrude()` for the radius.

To make the effect readable, the next illustration shows only the part of that
cutter that actually overlaps the bracket:

![Material removed by one side of the ef hull](../design/chamfer_10_ef_one_side.png)

## 13. Current step 4: repeat the same operation on the other Y side

The bracket has two broad side faces, so the same short hull is mirrored to the
other side.

The code intentionally uses **two separate hulls**:

```openscad
for (side = [-1, 1])
    hull() {
        opening_layer(side * (W / 2 - ef));
        opening_layer(side * W / 2, ef);
    }
```

A single hull connecting both outside faces would span too much of the width.
Keeping each transition local prevents the expanded opening from affecting the
middle of the bracket.

The two removal zones together are shown here:

![Material removed by both ef side hulls](../design/chamfer_11_ef_both_sides.png)

## 14. Current step 5: subtract the main relief

After subtracting `inside_relief_envelope()`, the main elephant-foot relief is
already complete.

At this stage:

- the horizontal inside face is relieved;
- the rounded corner is relieved;
- the vertical inside face is relieved;
- both Y sides are handled.

![Bracket after the main ef relief, before the end correction](../design/chamfer_12_before_end_correction.png)

This is the most important intermediate result when judging the current
solution.

The remaining problem is small.

## 15. Current step 6: inspect the arm tips

At an arm tip, the main `ef` relief reaches an edge that is already diagonal
because of `cs`.

The broad inside-opening hull follows the L correctly, but it does not fully
form that short diagonal meeting surface.

The result is a small flat termination.

This is **not** a failure of the complete elephant-foot relief. It is one local
junction.

The next illustration deliberately zooms in on that small area:

![Before correction, correction volume, and final junction](../design/chamfer_13_end_correction.png)

Read it from left to right:

**Left — main relief only**

The bracket already has the complete continuous `ef` relief. Only the tiny
arm-tip junction is unfinished.

**Middle — extra local cutter**

The red object is the small additional cutting volume. It is not part of the
bracket.

**Right — final junction**

After subtracting the small local cutter, the `ef` transition continues into
the diagonal `cs` bevel.

## 16. Current step 7: how that local cutter is made

The production helper is named `relief_corner_miters()`.

The name is less important than the construction.

A small triangular profile is placed at each end of the short diagonal
junction. A local `hull()` connects the two triangles.

This is repeated for:

- horizontal arm tip, front Y side;
- horizontal arm tip, rear Y side;
- vertical arm tip, front Y side;
- vertical arm tip, rear Y side.

So the current implementation still contains **four local special cases** in
the final arm-tip junctions.

That is the price of keeping the main inside-L relief generic.

## 17. Current step 8: final relief

The complete production operation is:

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

The resulting body is shown here:

![Complete body after cs and ef relief](../design/chamfer_14_final_relief.png)

The nut pockets and holes are added afterwards:

![Final bracket](../design/chamfer_15_final_bracket.png)

---

# Part C — old versus current

## 18. What did the redesign actually simplify?

It did **not** remove every special case.

The important simplification is narrower:

> The long horizontal edge, rounded inside corner and long vertical edge are no
> longer three different constructions. They are one continuous
> `inside_opening_2d()` boundary.

The arm-tip `cs` / `ef` junction still needs local treatment.

That is why the current solution should not be described as "the simple
solution". It is better described as **a more unified main relief with a small
local finishing step**.

## 19. Side-by-side comparison

| Question | Former per-edge cutters | Current opening + hull |
| --- | --- | --- |
| Straight horizontal relief | Dedicated wedge | Part of one opening boundary |
| Straight vertical relief | Dedicated wedge | Part of one opening boundary |
| Rounded `r_in` relief | Separate `rotate_extrude()` | Same opening boundary |
| Front/rear Y sides | Mirrored cutters | One local hull per side |
| `cs` / `ef` arm-tip junction | Dedicated diagonal wedge | Small local triangular hull |
| Uses same inside-radius definition as bracket | Indirectly / duplicated construction | Yes |
| Easy to understand one edge in isolation | Very good | Less direct |
| Easy to change the entire inside path consistently | Less good | Better |
| Amount of special geometry | Several explicit cutters | Main relief generic, tips still special |
| Overall code concept | Concrete/local | More abstract |
| Best use | Historical reference and debugging | Production baseline |

## 20. Regression: how similar are the two solids?

The repository keeps the former implementation in
`tests/elephant-foot-equivalence.scad`.

The CI script `verify-elephant-foot-hull.sh` renders both implementations for
multiple combinations of:

- `cs`;
- `ef`;
- `r_in`, including disabled and larger-radius cases.

It then calculates the symmetric difference between the old and new STL
volumes.

The test requires the total difference to remain below **0.1% of the former
solid volume**.

There is also a separate test focused only on the four arm-tip junctions. This
is necessary because a visually obvious defect on a 0.6 mm bevel can be far too
small to matter in a whole-model volume percentage.

For non-zero `cs` and `ef`, CI requires the local end correction to remove
at least **90% of the arm-tip difference** that is present before that
correction.

These are regression checks, not a physical strength or fit test. They tell us
that the redesign stays very close to the established geometry over the tested
parameter combinations.

## 21. Which solution should we keep?

For the production model, keep the **current opening + hull solution**.

The reason is not that it has fewer lines or that it is easier to explain. It
does not clearly win on either of those points.

The reason is that the most important geometric feature — the complete
wood-contact path through horizontal face, `r_in`, and vertical face — is now
defined once.

That gives a stronger relationship between:

```text
real bracket inside geometry
            and
elephant-foot relief geometry
```

The former cutter solution is still valuable and should **not** be deleted from
the regression fixture. It is an excellent independent reference because it
constructs the same intended relief in a completely different way.

So the recommended division is:

```text
production:
    current inside-opening + hull implementation

regression/reference:
    former explicit per-edge cutter implementation
```

## 22. What should a future redesign improve?

A future replacement is only worthwhile if it improves the current weak point
without losing the current strong point.

The strong point to preserve is:

> one continuous definition for the whole inside-L relief.

The weak point is:

> `relief_corner_miters()` is relatively difficult code for a very small
> arm-tip junction.

So a future experiment should focus narrowly on the arm tips.

Do **not** redesign the horizontal edge, radius and vertical edge merely to make
the four small end junctions look more elegant in source code.

## 23. How to inspect the current solution in OpenSCAD

Open
[`design/chamfer_explained.scad`](../design/chamfer_explained.scad)
and walk through these stages in order:

| Stage | Purpose |
| --- | --- |
| `07_cs_body` | Real bracket with `cs`, before `ef` |
| `08_inside_opening` | One 2D definition for the complete inside path |
| `09_ef_layer_inputs` | Two layers used for one side of the `ef` hull |
| `10_ef_one_side` | Material removed on one Y side |
| `11_ef_both_sides` | Same relief on both Y sides |
| `12_before_end_correction` | Main `ef` relief complete |
| `13_end_correction` | Remaining arm-tip problem and its local cutter |
| `14_final_relief` | Complete `cs + ef` body |
| `15_final_bracket` | Final bracket including holes and pockets |

For the simpler convex-beam introduction to `hull()`, see the
[beam tutorial](../../../../examples/hull_operations/v0.1/README.md).

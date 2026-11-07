# Corner Bracket: `cs` and `ef` — explained from the actual model

This page explains the **current production solution** in
[`corner_bracket.scad`](../scad/corner_bracket.scad).

It is intentionally not another experiment. The goal is to make the existing
geometry understandable before changing it again.

## The short version

There are two different operations:

1. **`cs`** makes the long outside side-edge chamfers.
2. **`ef`** removes a small amount of material along the complete inside L:
   horizontal contact face → rounded inside corner → vertical contact face.

The normal `ef` relief already works along almost the complete L.

There is only one awkward place: **at each arm tip, the `ef` relief meets the
diagonal `cs` chamfer**. The production model adds a very small local
`hull()` there to make that junction continue cleanly.

That is why the current solution has two parts:

```text
main ef relief along the complete inside L
                    +
small local correction where `ef` meets `cs` at the arm tips
```

## 1. Start with the real L-shaped bracket

The bracket is defined as an L profile in the **X/Z plane** and extruded over
its width `W` in **Y**.

The important point is simply this:

```text
X/Z : shape of the L
Y   : width of the bracket
```

The rounded inside corner is part of the L profile itself.

The model first creates the plain extrusion and then applies `cs`.

![Bracket after the normal cs operation](../design/chamfer_07_intersection.png)

## 2. What `cs` does

`cs = 2` creates the long chamfers at the two outside side faces.

The model does this with two temporary shapes:

- the full outside outline, but narrower in Y;
- the same outside outline inset by `cs`, but at full width.

A `hull()` connects those two shapes.

That hull is deliberately **convex** and therefore fills the open part of the L.
That looks wrong by itself, but it is only a helper envelope.

The real L is recovered with:

```openscad
intersection() {
    profile_extrusion();
    side_chamfer_env();
}
```

The result is `body()`: the real L bracket with the outside `cs` chamfers.

## 3. What `ef` has to follow

The elephant-foot compensation is not a new side profile and it does not need a
special "print coordinate system".

It follows the **inside boundary of the L**:

```text
horizontal inside face
        ────────────────┐
                        )
                       )   rounded inside corner r_in
                      )
                      │
                      │ vertical inside face
                      │
```

The production code describes the empty space between the two arms with
`inside_opening_2d()`.

That opening has exactly the boundary we need:

- the horizontal inside face;
- the rounded `r_in` corner;
- the vertical inside face.

So we can modify the opening instead of constructing separate cutters for every
straight edge and for the radius.

## 4. The main `ef` relief

For one Y side, the model creates two very thin opening layers:

```text
Y = W/2 - ef        normal opening
Y = W/2             opening expanded by ef
```

Then it hulls those two layers:

```openscad
hull() {
    opening_layer(W / 2 - ef);
    opening_layer(W / 2, ef);
}
```

Because the two layers are only `ef` apart, this makes a short 45-degree
transition near that side of the bracket.

The same operation is repeated at the other Y side.

This is important: **there is not one global hull from one side of the bracket
to the other**. Each side gets its own short local hull.

The result follows the complete inside L automatically, including the rounded
corner.

![Before and after the main print-relief operation](../design/chamfer_08_print_relief.png)

The orange/right-hand example includes the relief; the blue/left-hand example
shows the body before it is removed.

## 5. What still goes wrong after the normal `ef` relief?

At this point the **main elephant-foot relief is already finished**.

Along the long horizontal inside face it works.

Around the rounded inside corner it works.

Along the long vertical inside face it works.

So the remaining problem is **not the L shape itself**.

The only place that still needs attention is the very end of each arm.

At an arm tip, the inside `ef` relief arrives at an edge that is already
sloping because of `cs`.

That creates this situation:

```text
normal ef relief
      ↓
--------------------                     \   cs side chamfer
                      \
```

The main `ef` hull follows the inside L correctly, but it does not automatically
continue through that last small diagonal piece.

The result is a **short flat termination** at the meeting point.

That tiny flat piece is the defect we were trying to understand.

It is important to keep the scale of the problem clear:

> The complete elephant-foot construction works. Only the small meeting point
> between `ef` and `cs` at an arm tip needs an extra correction.

## 6. Show the problem before fixing it

The left-hand crop below shows the bracket **after the normal `ef` relief**,
but **before** the extra local correction.

![The local cs/ef junction correction](../design/chamfer_10_corner_junction.png)

Read the three crops from left to right:

**Left — normal `ef` only**

This is the important starting point.

The long `ef` relief is already present. The rounded inside corner is already
correct. Only the very end of the relief stops too abruptly where it reaches
the diagonal `cs` edge.

**Middle — the extra material to remove**

The red shape is not part of the bracket. It is a tiny helper volume that will
be subtracted.

Its only purpose is to continue the relief through that short diagonal
junction.

**Right — final corner**

After subtracting the red helper volume, the `ef` transition continues
cleanly into the `cs` chamfer.

Nothing else in the bracket changes.

## 7. How the small local correction is made

Only now do we need the slightly more technical construction.

The correction uses two very small triangular helper profiles placed along the
diagonal `cs` edge.

A short `hull()` connects those two triangles.

That creates a small swept volume exactly where the flat termination was.

The same small operation is repeated at:

- the horizontal arm tip;
- the vertical arm tip;
- the front Y side;
- the rear Y side.

So there are four equivalent local junctions in total.

In the source code this helper is called:

```openscad
relief_corner_miters()
```

The name is less important than its job:

> remove only the tiny leftover piece where the normal elephant-foot relief
> reaches the diagonal side chamfer.

The complete production operation is therefore:

```openscad
module chamfered_body() {
    difference() {
        body();                       // real L with cs

        if (ef > 0) {
            inside_relief_envelope(); // main ef relief along the complete L
            relief_corner_miters();   // only the four small end corrections
        }
    }
}
```

Or in plain language:

```text
make the L bracket
      ↓
apply cs
      ↓
apply the normal ef relief along the whole inside L
      ↓
inspect the arm tips
      ↓
remove four tiny leftover junction pieces
      ↓
finished chamfered body
```

## 8. Why not replace this with one giant hull?

A global `hull()` around the complete L is tempting because the straight beam
example works so nicely.

The problem is that an L is **concave**.

A global hull always returns a convex envelope, so it bridges across the open
inside corner. You can intersect that helper with other geometry afterwards,
but it does not remove the need to handle the local `cs` / `ef` junction
correctly.

The current production approach therefore stays deliberately local:

- one short opening hull per Y side for the main `ef` relief;
- one small small local hull per arm tip and Y side for the junction.

That is less elegant than a single universal hull, but it matches the geometry
we actually need and keeps the correction confined to the problem area.

## 9. How to inspect it yourself

Open
[`design/chamfer_explained.scad`](../design/chamfer_explained.scad)
in OpenSCAD.

The most useful Customizer stages are:

| Stage | What to look at |
| --- | --- |
| `07_intersection` | L bracket after `cs`, before `ef` |
| `08_print_relief` | before/after the main `ef` relief |
| `10_corner_junction` | before correction → correction volume → final junction |
| `09_final` | complete bracket with pockets and holes |

For the simpler rectangular explanation of how `hull()` can join two
chamfered inputs, see the
[beam hull example](../../../../examples/hull_operations/v0.1/).

## 10. What should be changed in the future?

Treat the current geometry as the baseline.

If the arm-tip correction is changed later, test only this question first:

> Does the new method produce the same clean `cs` / `ef` junction without
> changing the rest of the L?

Do not redesign the complete elephant-foot relief merely to change that small
junction.

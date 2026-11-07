# Corner Bracket: same idea as the beam, now on the L

The L is now shown **lying on its printed side**, so the pictures read the same
way as the beam experiment.

There are only four steps.

## 0. L with the normal `cs` chamfer

![L with cs](../design/junction_00_l_with_cs.png)

This is the real bracket `body()`, already including the normal side chamfer.

## 1. The two `ef` inputs

![Two transparent ef inputs on the L](../design/junction_01_ef_inputs.png)

The complete L stays faintly visible underneath.

The colored shapes are the two real inputs to the elephant-foot transition:

- blue: the already-`cs`-chamfered L one `ef` inward from the print face;
- orange: the already-`cs`-chamfered L at the print face, then made
  `ef` smaller.

Both inputs therefore already contain the `cs` geometry before any new
`hull()` is made.

Internally the horizontal and vertical arms are hulled separately. That avoids
a global hull filling the concave inside corner, but visually they remain one L.

## 2. Hull result

![Hull result on the L](../design/junction_02_ef_hull.png)

The green volume is the union of those two local arm hulls.

This is the direct L-shaped equivalent of the successful beam construction.

## 3. Resulting L

![Resulting L](../design/junction_03_result.png)

The new transition replaces only the outer `ef`-deep printed-side layer.
Everything farther inward remains the original `body()`.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and switch the `junction_step` dropdown through the same four stages.

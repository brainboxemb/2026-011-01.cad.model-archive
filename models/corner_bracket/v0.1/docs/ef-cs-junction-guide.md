# Corner Bracket: the beam construction on the real L

The L is shown in print orientation and the elephant-foot step now uses the
**same two kinds of input as the beam demo**.

The starting L contains the normal `c`, `ce` and `cs` chamfers, but no
`ef` yet.

## 0. Clean L with `cs` only

![Clean L with cs](../design/junction_00_l_with_cs.png)

There is no elephant-foot correction in this scene.

## 1. The two `ef` inputs

![Two ef inputs](../design/junction_01_ef_inputs.png)

This should now read exactly like the beam.

For this illustration only, the two inputs are shown as an **exploded view** so
the lower plate cannot disappear behind the upper volume:

- **blue:** one thin **L-shaped bottom plate**. It is derived from the
  already-`cs`-chamfered footprint and then made `ef` smaller;
- **orange:** the complete already-`cs`-chamfered **L volume from height
  `ef` upward**.

The exploded spacing is visual only. The actual `hull()` uses both inputs at
their real positions.

## 2. Hull result

![Hull result](../design/junction_02_ef_hull.png)

A single global hull of a concave L would fill its inside corner. Therefore the
implementation hulls the horizontal and vertical arm separately and unions the
two results.

That split is only an internal implementation detail. The inputs shown in the
previous image are still one bottom L plate and one upper L volume.

## 3. Resulting L

![Resulting L](../design/junction_03_result.png)

The result is the upper clean `cs` L plus the two local hull transitions down
to the smaller bottom plate.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and use the `junction_step` dropdown.

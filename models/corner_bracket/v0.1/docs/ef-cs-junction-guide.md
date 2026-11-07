# Corner Bracket: same idea as the beam, now on a clean L

The L is shown in print orientation and the walkthrough has only four steps.

One important detail is now explicit: the first scene is **not** the production
`body()`, because that already contains the elephant-foot adjustment in
`tip_top` and `tip_vert`.

For this explanation the starting L is rebuilt with:

- the same arm geometry;
- the same end chamfers `c`;
- the same outside corner chamfer `ce`;
- the same side chamfer `cs`;
- **no `ef` anywhere yet**.

That gives a clean baseline.

## 0. Clean L with `cs` only

![Clean L with cs](../design/junction_00_l_with_cs.png)

The arm tips are still sharp at the print/contact edge. If an elephant-foot
bevel is visible here, the demo is wrong.

## 1. Add the two `ef` inputs

![Two transparent ef inputs](../design/junction_01_ef_inputs.png)

Now `ef` is introduced for the first time.

Both colored inputs are derived from the already-`cs`-chamfered clean L:

- blue: normal cs-aware L one `ef` inward from the printed side;
- orange: cs-aware L at the printed side, then made `ef` smaller.

## 2. Hull result

![Hull result](../design/junction_02_ef_hull.png)

The two local arm hulls create the elephant-foot transition while preserving the
concave L corner.

## 3. Resulting L

![Resulting L](../design/junction_03_result.png)

Everything inward of the transition stays the clean `cs` body. Only the outer
printed-side layer is replaced by the new `ef` transition.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and use the `junction_step` dropdown.

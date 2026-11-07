# Hull operations on one simple beam

This page deliberately starts with **one rectangular beam**. The purpose is to
understand the two operations before looking at the Corner Bracket.

The camera, beam dimensions and orientation stay the same in every image.

## 0. Start: unchanged beam

![Plain rectangular beam](renders/00_plain_beam.png)

There is no chamfer and no elephant-foot correction yet.

## 1. Operation A: side chamfer `cs`

![Beam with side chamfer only](renders/01_side_chamfer.png)

Only the long outside edges change.

The construction is easiest to read as three cross-sections:

1. a narrower section at the outer face;
2. the normal full section farther inward;
3. `hull()` connects those sections.

So the important sequence is:

**beam → hull between two sections → beveled outside edge**

Nothing about the elephant-foot correction is involved yet.

## 2. Operation B: elephant-foot relief `ef`

![Beam with elephant-foot relief only](renders/02_elephant_foot.png)

Now return to the original beam and ignore `cs`.

The correction acts only in the small region at the print-bed edge. A short
`hull()` defines the relief volume between the original edge and an inset
section. That small volume is then removed from the beam.

Read this operation as:

**beam → make small relief volume → subtract it → corrected bottom edge**

## 3. Both operations on the same beam

![Beam with both operations](renders/03_combined.png)

Only after the two operations are clear separately are they combined:

1. start with the same beam;
2. apply the side chamfer `cs`;
3. apply the elephant-foot relief `ef`.

This is the geometry relationship that should later be translated back to the
real L-shaped Corner Bracket.

## Source

The complete minimal OpenSCAD example is in
[`scad/hull_operations.scad`](scad/hull_operations.scad).

Set `scene` to `0`, `1`, `2` or `3` to inspect the same four states
locally.

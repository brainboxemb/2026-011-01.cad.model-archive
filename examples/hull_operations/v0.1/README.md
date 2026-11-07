# Hull operations on a simple beam

This is a deliberately small teaching model.

The Corner Bracket documentation became difficult to read because the viewer had
to understand the L-profile, the inside radius, the side chamfer and the
elephant-foot correction at the same time. This example removes all unrelated
geometry.

## Start with one beam

The reference object is only a rectangular beam:

- length: 70 mm
- width: 24 mm
- height: 20 mm

Nothing is hidden in the first image.

## Four scenes

Set `scene` in `scad/hull_operations.scad`:

1. `scene = 0` — plain beam
2. `scene = 1` — side chamfer (`cs`) only
3. `scene = 2` — elephant-foot relief (`ef`) only
4. `scene = 3` — both operations on the same beam

The camera angle should remain identical for all four renders. The purpose is
to make the changed surfaces visually comparable, not to produce attractive
perspective views.

## What the two operations mean

### 1. Side chamfer: `cs`

The side chamfer changes the outer side edges. In this demo, a `hull()`
connects narrower outer-face sections with the full middle section. The result
is a beam whose long outside edges are beveled.

### 2. Elephant-foot relief: `ef`

The elephant-foot correction changes only the small region at the print-bed
edge. The demo constructs the relief volume with a short `hull()` and subtracts
that volume from the beam.

This operation should therefore be read as:

**beam → small relief volume → subtract relief volume → corrected beam**

not as a mysterious second shape unrelated to the beam.

## Next step

Only after these four scenes are understandable should the same two operations
be shown on the real Corner Bracket. That second explanation should use the
same order and the same terminology.

# Beam experiment: chamfer first, then build the elephant-foot hull

This version tests one specific idea:

**do not feed a square upper block into the elephant-foot hull.**

Instead:

1. build the normal `cs` chamfer first;
2. take that already-chamfered beam above height `ef`;
3. hull it to an `ef`-inset bottom footprint.

That means the elephant-foot construction starts from the geometry that already
contains the side chamfer.

## 0. Beam

![Beam](renders/00_plain.png)

## 1. `cs`: two transparent inputs

![cs inputs](renders/01_cs_inputs.png)

Blue and orange are the two objects passed to the normal `cs` hull.

## 2. `cs`: result

![cs result](renders/02_cs_result.png)

This is the already-chamfered beam.

## 3. `ef`: two transparent inputs

![ef inputs](renders/03_ef_inputs.png)

This is the important change.

- blue: the bottom footprint, inset by `ef` on all four sides;
- orange: the **already `cs`-chamfered upper body**, clipped from `z = ef`
  upward.

So the orange object is no longer a rectangular block.

## 4. Hull those two objects

![combined result](renders/04_combined_result.png)

The elephant-foot transition is now created directly from the existing
chamfered geometry.

There is no later

```openscad
intersection() {
    cs_hull();
    ef_hull();
}
```

between two independently built envelopes.

Instead the sequence is:

```openscad
hull() {
    ef_input_bottom();
    ef_input_upper_chamfered();
}
```

## 5. Inspect the meeting corner

![corner close-up](renders/05_corner.png)

This close-up is the actual test: does using the already-chamfered upper body as
the second hull input remove the small termination at the `cs`/`ef` meeting
corner?

## Source

[`scad/hull_operations.scad`](scad/hull_operations.scad)

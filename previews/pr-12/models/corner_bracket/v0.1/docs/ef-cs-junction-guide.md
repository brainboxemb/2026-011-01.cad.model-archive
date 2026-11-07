# Corner Bracket: same construction as the beam

This walkthrough now checks the two `ef` inputs **separately first**.

That is deliberate: before looking at `hull()`, the lower input must clearly
be a flat L-shaped plate, just like the plate under the beam.

The clean starting L contains `c`, `ce` and `cs`, but no `ef`.

## 0. Clean L with `cs`

![Clean L with cs](../design/junction_00_l_with_cs.png)

No elephant-foot geometry is present yet.

## 1. Lower `ef` input only

![Lower L plate](../design/junction_01_lower_plate.png)

This image shows **nothing except the lower input**.

The construction is now literally the same as in the beam demo:

1. put the complete already-`cs`-chamfered L in print orientation;
2. take a thin slab exactly at print-bed `Z=0`;
3. project that slab to obtain the real bottom footprint;
4. apply `offset(-ef)`;
5. extrude that result as the lower plate.

So this plate is no longer an X/Z section that is rotated afterward. It is
derived directly from the final print-oriented 3D L, which fixes both its
orientation and its position.

## 2. Upper `ef` input only

![Upper L volume](../design/junction_02_upper_volume.png)

This is the complete already-`cs`-chamfered L from height `ef` upward.

## 3. Both inputs, exploded

![Exploded inputs](../design/junction_03_ef_inputs.png)

Now the same two inputs are shown together:

- blue lower L plate;
- orange upper L volume.

They are moved apart only for this illustration.

## 4. Hull result

![Hull result](../design/junction_04_ef_hull.png)

Because a global hull would fill the concave inside corner, the two arms are
hulled separately internally and then united.

## 5. Resulting L

![Resulting L](../design/junction_05_result.png)

This is the resulting one-sided elephant-foot experiment.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and use the `junction_step` dropdown.

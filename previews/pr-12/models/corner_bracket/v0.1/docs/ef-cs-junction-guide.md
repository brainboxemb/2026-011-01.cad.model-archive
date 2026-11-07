# Corner Bracket: the beam construction on an L

This experiment is now written directly in **print coordinates**, just like the
beam demo.

That means:

- X/Y is the footprint on the print bed;
- Z is the print height / bracket width;
- no rotation is used inside the elephant-foot construction.

The production model is still unchanged.

## 0. L with `cs`

![L with cs](../design/junction_00_l_with_cs.png)

This is `cs_body()`.

It is built from the clean L profile and the normal `cs` hull. There is no
`ef` in the profile or at the arm tips.

## 1. The two `ef` inputs

![Two ef inputs](../design/junction_01_ef_inputs.png)

This is now the same construction as the beam:

**Blue — `ef_input_bottom()`**

The actual bottom footprint of `cs_body()` is taken at the print bed. That
already contains the `cs` geometry. Only then is `offset(-ef)` applied.

The result is one thin L-shaped plate at exactly the same X/Y position as the
bracket.

**Orange — `ef_input_upper()`**

This is the complete `cs_body()` from `Z = ef` upward.

For this illustration only, the orange volume is moved straight upward in Z so
the blue plate is visibly **under** it. There is no X/Y displacement. The real
`hull()` uses the unshifted geometry at the actual `ef` height.

So both inputs already contain the normal chamfer before the elephant-foot hull
is created.

## 2. Hull result

![EF hull result](../design/junction_02_ef_hull.png)

The only L-specific complication is the concave inside corner.

A single global `hull()` would close that corner. Therefore the horizontal
and vertical arm are hulled separately and the two hull results are united.

That split happens only inside the hull operation. The visible inputs in step 1
remain one lower L plate and one complete upper L volume.

## 3. Result

![Result](../design/junction_03_result.png)

This is the upper `cs` L plus the two local transitions down to the lower
plate.

The key comparison with the beam is therefore direct:

```text
beam:    cs_body -> bottom footprint -> offset(-ef) -> upper cs body -> hull
bracket: cs_body -> bottom footprint -> offset(-ef) -> upper cs L    -> hull
```

The shape changes from a straight beam to an L; the construction order does
not.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and use the `junction_step` dropdown.

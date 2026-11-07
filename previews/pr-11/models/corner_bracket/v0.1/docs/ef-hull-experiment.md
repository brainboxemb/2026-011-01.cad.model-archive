# Elephant-foot relief on the Corner Bracket

This page explains the elephant-foot geometry in **three separate blocks**.

1. First build the normal elephant-foot relief using only the two main hulls.
2. Repeat the same steps and then add the small arm-tip correction.
3. Only after those two constructions are clear, test whether the correction
   can be absorbed into the original two hull surfaces.

The images in blocks A and B use the **same complete bracket, camera angle
and scale**. Blue/orange/red therefore always refer to geometry at the same
physical location.

The real model exposes:

```openscad
ef_corner_correction = true;
```

Set it to `false` to compare the model with only the two main EF hulls.

---

# A. Elephant foot with the two main hulls

This first sequence deliberately contains **no arm-tip correction**.

## A1. Start with the complete bracket

The bracket already has its normal 2D profile, the outside `cs` side
chamfers, bolt holes and nut pockets. No elephant-foot relief has been
subtracted yet.

![A1 — complete bracket before elephant-foot relief](../design/efh_A01_before_ef.png)

This complete bracket stays visible throughout the next steps so the hull
surfaces never lose their relationship to the model.

## A2. First hull surface

The first thin surface is placed **0.6 mm inside the print face**, at
Y = 9.4 mm.

![A2 — first hull surface in position on the bracket](../design/efh_A02_surface_a.png)

It follows the two wood-contact edges of the L and the rounded inside
corner.

```openscad
opening_layer(W/2 - ef);
```

With `W = 20` and `ef = 0.6`, this means Y = 9.4 mm.

## A3. Second hull surface

The second surface is on the actual print face, Y = 10.0 mm. Its profile
is expanded outward by `ef = 0.6`.

![A3 — second hull surface in position on the bracket](../design/efh_A03_surface_b.png)

```openscad
opening_layer(W/2, ef);
```

## A4. Both hull surfaces

Now show the two surfaces together:

![A4 — both elephant-foot hull surfaces](../design/efh_A04_both_surfaces.png)

- **Blue:** unchanged profile at Y = 9.4 mm.
- **Orange:** expanded profile at Y = 10.0 mm.

These are the two children of one `hull()` on this print side. The
opposite Y side uses the mirrored pair.

## A5. Hull between those two surfaces

`hull()` fills the volume between the blue and orange surfaces:

![A5 — main elephant-foot hull volume](../design/efh_A05_main_hull.png)

```openscad
hull() {
    opening_layer(W/2 - ef);
    opening_layer(W/2, ef);
}
```

This is the main 45° elephant-foot relief for one print side.

## A6. Subtract the main hulls

The same construction is mirrored on the other print side and both hull
volumes are subtracted from the bracket.

![A6 — complete bracket with only the two main EF hulls](../design/efh_A06_main_result.png)

This corresponds to:

```openscad
ef_corner_correction = false;
```

Most of the relief is now correct.

## A7. Where is the remaining problem?

The four red markers show the only places still under discussion:

![A7 — four arm-tip locations that still need attention](../design/efh_A07_problem_locations.png)

There are four locations because there are two arm ends on two print-facing
Y sides.

This is the important baseline: **the main elephant-foot hull works; the
remaining issue is local to those four arm-tip junctions.**

---

# B. Repeat the same construction with the working correction

This sequence repeats A using the **same camera, same scale and same bracket**.
The first five steps are intentionally almost identical. Only then is the
small arm-tip correction added.

## B1. Same starting bracket

![B1 — same complete bracket before EF relief](../design/efh_B01_before_ef.png)

## B2. Same first hull surface

![B2 — same first hull surface](../design/efh_B02_surface_a.png)

## B3. Same second hull surface

![B3 — same second hull surface](../design/efh_B03_surface_b.png)

## B4. Same two hull surfaces together

![B4 — same two hull surfaces](../design/efh_B04_both_surfaces.png)

## B5. Same main hull

![B5 — same main elephant-foot hull](../design/efh_B05_main_hull.png)

Up to this point, B is geometrically identical to A.

## B6. Add the correction at the four arm-tip locations

At whole-bracket scale the actual correction is too small to read clearly,
so the same four red location markers are used:

![B6 — four locations where the arm-tip correction is added](../design/efh_B06_corner_correction.png)

The exact correction shape is shown later in **C1**, after zooming into one
of these four locations.

Conceptually the working construction is:

```openscad
difference() {
    body();

    inside_relief_envelope(); // main EF hulls
    relief_corner_miters();   // small arm-tip corrections
}
```

## B7. Working bracket

With the correction enabled, the complete bracket becomes:

![B7 — complete working bracket](../design/efh_B07_working_result.png)

This corresponds to:

```openscad
ef_corner_correction = true;
```

Blocks A and B now establish exactly what changes: **only the four small
arm-tip locations.**

---

# C. Can the correction be absorbed into the original two hull surfaces?

Only now do we zoom into one horizontal arm end on the +Y print side.

The question is not whether the current model works; block B already shows
that. The question is whether we can simplify B so that the corrected result
comes from only two improved hull surfaces.

## C1. Exact missing relief at one arm tip

The red volume is the local difference between A and B at one marked arm tip:

![C1 — exact missing local relief volume](../design/efh_07_missing_tip_volume.png)

## C2. Exact two surfaces taken from the working relief

Rather than guessing how the profiles should change, take exact
`projection(cut=true)` cross-sections of the working B relief at the same
two Y positions:

![C2 — exact working cross-sections at Y=9.4 and Y=10](../design/efh_10_exact_reference_inputs.png)

## C3. Hull those exact two surfaces

![C3 — hull of the exact working cross-sections](../design/efh_11_exact_two_surface_hull.png)

## C4. Result of that two-surface candidate

![C4 — bracket result from the exact two-surface candidate](../design/efh_12_exact_candidate_result.png)

## C5. Compare with the working B result

The XOR is not empty:

![C5 — XOR between two-surface candidate and working result](../design/efh_13_exact_candidate_xor.png)

Split into:

![C6 — candidate overcut](../design/efh_14_exact_candidate_overcut.png)

![C7 — candidate undercut](../design/efh_15_exact_candidate_undercut.png)

For the default `cs=2`, `ef=0.6` case:

| Local arm-tip volume | mm³ |
| --- | ---: |
| Working reference | 1.2433 |
| Exact two-surface candidate | 2.4922 |
| XOR | 1.9006 |
| Overcut | 1.5743 |
| Undercut | 0.3263 |

So the current test says only this:

> Two surfaces at the existing Y = 9.4 and Y = 10.0 positions do not
> reproduce the working B geometry, even when those two surfaces are exact
> sections of the working relief.

That does **not** rule out a different construction using additional
sections or another decomposition.

## Related pages

- [Chamfer Guide](chamfer-guide.html) — the normal bracket construction.
- [Hull Guide](hull-guide.html) — basic `hull()` operation.
- [Polygon Guide](polygon-guide.html) — the separate 2D inside-radius
  construction.

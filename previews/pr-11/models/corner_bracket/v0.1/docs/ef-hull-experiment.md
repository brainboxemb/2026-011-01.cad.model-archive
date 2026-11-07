# Elephant-foot hull experiment

This page isolates **one horizontal arm tip on the +Y print side** and
shows the elephant-foot construction step by step. It is an experiment,
not a second production model.

The goal is very specific:

> Can the complete elephant-foot junction be made with the same **two
> hull input surfaces** that already create the main relief, if those
> surfaces are shaped correctly?

The production model remains the reference. The experiment first shows
the current two-surface hull, then derives a stronger candidate from the
**exact cross-sections of the working reference cutter**. That avoids
guessing what the corrected hull surfaces ought to look like.

## Reading order

The sequence is deliberately the same as the earlier `cs` hull
walkthrough:

**surface A → surface B → both surfaces → hull → result → defect → corrected
reference → new surfaces → new hull → result → XOR**

All rendered images are local crops around the arm tip. The OpenSCAD
operations themselves use the full production geometry before the crop is
applied.

## A. Current two-surface elephant-foot hull

### 1. Source opening profile

The main elephant-foot cutter starts with the open quadrant between the
two L arms, including the rounded inside-corner boundary.

![Source opening profile](../design/efh_01_opening_profile.png)

This is the same `inside_opening_2d()` used by the production model.

### 2. First hull surface — Y = 9.4 mm

The first thin surface uses the original opening. With the default
`W=20` and `ef=0.6`, it sits 0.6 mm inside the printed face:

![First EF hull surface](../design/efh_02_inner_main_input.png)

```openscad
opening_layer(W/2 - ef);
```

### 3. Second hull surface — Y = 10.0 mm

The second surface lies on the print face and expands the opening by
`ef=0.6`:

![Second EF hull surface](../design/efh_03_outer_main_input.png)

```openscad
opening_layer(W/2, ef);
```

### 4. Both hull surfaces together

These are the **only two children** passed to the main elephant-foot
`hull()` on this side:

![Both EF hull surfaces](../design/efh_04_both_main_inputs.png)

The blue surface is the unchanged opening at Y=9.4. The orange surface
is the expanded opening at Y=10.0.

### 5. The resulting main hull

OpenSCAD makes the smallest convex solid containing both surfaces:

![Main EF hull](../design/efh_05_main_hull.png)

### 6. Result after subtracting only that hull

Subtracting the main hull from `body()` creates the correct relief along
the long plywood-contact edge and the inside radius, but the arm-tip
junction is not yet identical to the working reference:

![Result with only the main EF hull](../design/efh_06_main_result.png)

### 7. Exact missing tip volume

Instead of describing the problem verbally, subtract the main-hull cutter
from the proven working cutter. The remaining red solid is the **exact
cutting volume that is still missing** at this arm tip:

![Exact missing arm-tip cutting volume](../design/efh_07_missing_tip_volume.png)

This is the shape that a successful two-surface solution must somehow
generate without disturbing the rest of the relief.

## B. Working reference

### 8. Working cutter

The proven reference is the union of:

- the same main two-surface opening hull; and
- the small local arm-tip miter hull.

The image shows only the material-removing part that intersects the actual
bracket:

![Working EF cutter](../design/efh_08_reference_cutter.png)

### 9. Working result

Subtracting that cutter gives the current production geometry:

![Working arm-tip result](../design/efh_09_reference_result.png)

This result is the target for the next experiment.

## C. Strongest two-surface experiment

A weak experiment would guess a new tip polygon. This page does something
stronger: it takes **the exact cross-sections of the working cutter itself**
at the same two Y positions.

If any choice of those two surfaces can reproduce the working cutter with
one hull, this is the most direct candidate.

### 10. Exact reference surfaces

The blue and orange plates below are sliced directly out of the working
cutting volume at Y=9.4 and Y=10.0:

![Exact reference cross-sections used as hull inputs](../design/efh_10_exact_reference_inputs.png)

No hand-calculated `cs` point is used here. The shapes already include
whatever the working geometry does at the arm tip.

### 11. Hull of the exact reference surfaces

Those two exact surfaces are now passed to one `hull()`:

![Hull of the exact reference surfaces](../design/efh_11_exact_two_surface_hull.png)

This is the direct test of the proposed simplification.

### 12. Candidate bracket result

Subtracting that candidate hull from the actual body gives:

![Result of the exact two-surface candidate](../design/efh_12_exact_candidate_result.png)

### 13. XOR against the working reference

The symmetric difference between the candidate cutter and the working
reference is rendered explicitly:

![XOR between exact two-surface candidate and reference](../design/efh_13_exact_candidate_xor.png)

If this image is empty, the two-surface solution is equivalent. If material
is visible, the candidate is not yet equivalent.

### 14. Candidate overcut

This view contains only material removed by the candidate but **not** by
the working reference:

![Overcut caused by the exact two-surface candidate](../design/efh_14_exact_candidate_overcut.png)

### 15. Candidate undercut

This view contains only material removed by the working reference but
**missed** by the candidate:

![Undercut left by the exact two-surface candidate](../design/efh_15_exact_candidate_undercut.png)

## What this experiment does — and does not — prove

The experiment deliberately asks only one question: whether **two hull
surfaces at the existing Y positions** can reproduce the current working
arm-tip cutter.

It does **not** claim that every possible hull-based reformulation has
been exhausted. A solution with additional Y sections, a different
decomposition, or a different constructive operation would be a separate
experiment.

The numerical regression for the candidate, XOR, overcut and undercut is
run in CI by `verify-ef-two-surface-experiment.sh`. Keep the production
model unchanged until the experiment is equivalent across the required
parameter set.

## Related pages

- [Chamfer Guide](chamfer-guide.html) — the actual bracket construction,
  without experimental alternatives.
- [Hull Guide](hull-guide.html) — a short general introduction to
  `hull()`.
- [Polygon Guide](polygon-guide.html) — the separate 2D inside-radius
  construction.

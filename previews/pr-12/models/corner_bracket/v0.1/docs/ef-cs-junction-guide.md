# Corner Bracket: minimal cs/ef hull experiment

This page applies the successful beam idea to the **real Corner Bracket**
without redesigning the whole model.

The production model already has two local elephant-foot hulls: one for each
printed side. The experiment keeps that structure and asks one narrow question:

> Can we keep the same two hulls, but derive their input profiles from the
> already-`cs`-chamfered `body()`?

The production file is **not changed** by this experiment.

## 0. Start from the existing `body()`

![Existing body with cs chamfer](../design/junction_00_cs_body.png)

This is the real bracket body after the existing side-edge chamfer `cs`, but
before the broad elephant-foot hull is subtracted.

## 1. Current elephant-foot hull inputs

![Current transparent ef inputs](../design/junction_01_current_inputs.png)

The current construction uses two thin opening profiles on each printed side:

- blue: the normal inside opening at `Y = W/2-ef`;
- orange: the same abstract opening expanded by `ef` at `Y = W/2`.

The orange profile is **not derived from the actual `cs`-chamfered body**.
That is the same mismatch the beam experiment exposed.

## 2. Current local hull

![Current local ef hull](../design/junction_02_current_hull.png)

The existing hull is perfectly sensible along most of the contact edge.

## 3. Current result before the special corner correction

![Current arm-tip defect](../design/junction_03_current_problem.png)

This is the isolated problem: the broad `ef` hull reaches the diagonal
`cs` side bevel at the arm tip with the small unwanted termination.

The production model currently fixes this afterward with
`relief_corner_miters()`.

## 4. Actual `cs` section one `ef` inward

![Inner actual cs section](../design/junction_04_inner_cs_section.png)

Instead of assuming an abstract opening shape, the experiment takes a real
cross-section of `body()` at `Y = W/2-ef`.

## 5. Actual `cs` section at the printed side

![Outer actual cs section](../design/junction_05_outer_cs_section.png)

The outer section already contains the diagonal geometry produced by `cs` at
the arm tip. This is the information missing from the current outer `ef`
input.

## 6. Proposed inputs: same two positions, cs-aware geometry

![Proposed transparent inputs](../design/junction_06_proposed_inputs.png)

The experiment keeps the same two Y positions and the same one-hull-per-side
structure.

The only conceptual change is how the profiles are obtained:

- blue: opening next to the **actual cs body** at `Y = W/2-ef`;
- orange: opening next to the **actual cs body** at `Y = W/2`, then expanded
  by `ef`.

So the outer input already knows about the side chamfer before the elephant-foot
hull is made.

## 7. Proposed local hull

![Proposed cs-aware local hull](../design/junction_07_proposed_hull.png)

This is still one local `hull()` on one printed side. The experiment is not
introducing a new global hull or changing the concave L construction.

## 8. Proposed result

![Proposed bracket result](../design/junction_08_proposed_result.png)

The result is the real `body()` minus the same two local relief hulls, but with
the cs-aware inputs.

No separate `relief_corner_miters()` is applied in this experimental result.

## 9. Direct comparison

![Current and proposed arm-tip result](../design/junction_09_compare.png)

Left: current broad elephant-foot hulls before the extra miter correction.

Right: the minimal cs-aware-input experiment.

The purpose of this file is to decide whether the production change can really
be limited to **how the two existing hull inputs are constructed**.

## Interactive source

Open
[`design/ef_cs_junction_explained.scad`](../design/ef_cs_junction_explained.scad)
and use the `junction_step` Customizer dropdown to inspect every stage.

# Beam experiment: build the bottom like the top

Yes: on the beam there is no need to explain `ef` as a completely different
kind of operation.

Both constructions can be shown with the same pattern:

**two solids → `hull()` → intersect with the beam**

The only difference is the direction in which the transition is built.

## 0. Reference beam

![Reference beam](renders/00_plain.png)

The normal end-profile chamfer `c` is already part of the beam. The complete
bottom perimeter is still sharp.

## 1. `cs`: two transparent hull inputs

![Transparent cs inputs](renders/01_cs_inputs.png)

The two objects are:

- blue: the full side outline, stopping `cs` before the printed side face;
- orange: the inset outline, extending to the full printed-side width.

The helper extends below the beam, so this hull does **not** touch the bottom
edge. That edge is reserved for `ef`.

## 2. `cs`: hull result

![cs hull result](renders/02_cs_result.png)

The hull creates the normal side-edge bevel. Intersecting it with the real beam
keeps only the required solid.

## 3. `ef`: two transparent hull inputs

![Transparent ef inputs](renders/03_ef_inputs.png)

The bottom now uses the same idea instead of a separate opening/cutter model:

- blue: the bottom footprint, inset by `ef` on **all four sides**;
- orange: the full footprint starting `ef` above the print bed.

That means the bottom hull includes both:

- the two long bottom edges;
- the two bottom edges on the **kopse kanten**.

## 4. `ef`: hull result

![ef hull result](renders/04_ef_result.png)

The hull restores the full footprint over a height of `ef`. Intersecting this
envelope with the beam gives a continuous elephant-foot relief around the
complete bottom perimeter.

## 5. Combine the two hull envelopes

![Combined cs and ef hulls](renders/05_combined.png)

The beam is now simply the intersection of three things:

1. the real beam;
2. the `cs` hull envelope;
3. the `ef` hull envelope.

No special corner correction has been added here.

## 6. Inspect the meeting corner

![Close-up where cs and ef meet](renders/06_corner.png)

This is the important experiment: does constructing the bottom with its own
hull make the `cs`/`ef` junction correct by construction?

If this beam corner is clean, the next step is to test whether the same
envelope approach can be transferred to the concave L-shaped Corner Bracket.
The L shape is the complication there; the basic hull principle is not.

## Source

The complete experiment is in
[`scad/hull_operations.scad`](scad/hull_operations.scad).

# Corner bracket — v0.1

Simplified outside-corner bracket for two plywood panels.

The current fastening is deliberately simple:

- **two M5 DIN 7991 countersunk bolts per arm**;
- four bolts total;
- bolts enter from the **outside**;
- each bolt passes through the bracket and plywood;
- washer and nut remain accessible on the inside.

The former captive-nut pockets, access windows and printed plugs are no longer part of the production model.

The bracket is still a prototype. Print fit, bolt stack-up, plywood fit and mechanical strength still need physical verification.

## Geometry at a glance

~~~text
2D L profile
    ↓
outside side-chamfer keep envelope
    ↓
continuous elephant-foot side relief
    ↓
4 × M5 countersunk bolt cuts
    ↓
final bracket
~~~

For the shared modelling language behind **keep**, **cut** and **clip** geometry, see the archive-wide [OpenSCAD design concepts](../../../docs/design-concepts.md).

## 1. Main L profile

`base_profile_2d()` contains the L outline, the arm-end chamfers and the large outside corner chamfer.

`inside_corner_fill_2d()` adds the rounded inside corner.

The tiny elephant-foot bevel on the two **arm end faces** is kept in this 2D profile. Two extra 3D cutters would only make the model harder to read.

`bracket_profile_2d()` combines the profile and `profile_body()` extrudes it across `bracket_width`.

## 2. Outside side-edge chamfer

The outside side chamfer is described as geometry that is allowed to **remain**.

`outer_side_chamfer_keep_envelope()` uses `hull()` to connect two differently sized convex outer profiles.

`outer_side_chamfered_body()` then clips that temporary envelope with the real L-shaped body.

## 3. Elephant-foot relief

The plywood-facing print relief is intentionally kept as **one continuous shape per broad print side**:

~~~text
horizontal contact edge
        ↓
rounded inside corner
        ↓
vertical contact edge
~~~

`inside_opening_2d()` describes that complete opening once.

`inside_side_relief_cuts()` makes one local `hull()` on each printable broad side, between the normal opening one relief-depth inward and the enlarged opening at the print face.

That produces the complete 45-degree relief around the straight contact edges **and** the rounded inside corner in one operation per side.

Only the small junction where this relief reaches the diagonal outside side chamfer needs a local correction.

That correction is one simple triangular prism, placed with ordinary `translate()`, `rotate()` and `mirror()` calls. The old general `multmatrix()` construction is no longer needed.

~~~openscad
module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();
        inside_side_relief_cuts();
        arm_tip_relief_cuts();
    }
}
~~~

So the split is:

- **main side relief:** one continuous cut per broad side;
- **arm-tip correction:** only the small transition to `side_edge_chamfer`;
- **arm end-face relief:** part of the 2D profile.

## 4. Four M5 countersunk bolts

The production model currently uses two bolts per arm, `bolt_diameter = 5` and `bolt_length = 30`.

`bolt_cuts()` applies the same `countersunk_bolt_cut()` twice on the horizontal arm and twice on the vertical arm.

~~~openscad
module bracket() {
    difference() {
        print_compensated_body();
        bolt_cuts();
    }
}
~~~

The default model uses a 12 mm bracket wall and 10 mm plywood. It echoes the minimum bolt stack and the closest approach between perpendicular bolt tips.

## Walkthroughs

Open the production model:

~~~powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/scad/corner_bracket.scad"
~~~

Open the six-step walkthrough:

~~~powershell
.\scripts\open-model.ps1 -Model "models/corner_bracket/v0.1/design/design.scad"
~~~

The [Chamfer Guide](docs/chamfer-guide.md) shows the profile, outside side chamfer, continuous elephant-foot side relief and arm-tip correction.

The [Hull Guide](docs/hull-guide.md) explains the two places where `hull()` is useful: outside chamfer as **keep geometry**, and continuous inside print relief as **cut geometry**.

The [Polygon Guide](docs/polygon-guide.md) explains the rounded inside corner.

The [Mounting Guide](docs/mounting-options.md) documents the current 4× M5 outside-to-inside arrangement.

## Experiments and regression fixtures

The general hull examples remain under `design/`.

Older elephant-foot implementations remain useful as test/reference material under `tests/`; they are not production geometry.

The arm-tip simplification is intended to preserve the old geometry while replacing the hard-to-read local `multmatrix()` transform with fixed rotations.

## Before printing

- Confirm the real plywood thickness.
- Confirm the inside plywood corner clears `inside_corner_radius`.
- Measure the actual M5 head, washer and nut.
- Recalculate `bolt_length` if any stack dimension changes.
- Check the countersunk head still leaves enough printed material.
- Print a short fit sample for `elephant_foot_relief` before relying on the full bracket.

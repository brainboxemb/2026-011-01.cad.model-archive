# Corner bracket — M5 mounting

The current v0.1 bracket deliberately uses a simple fastening arrangement:

- **two bolts per arm**;
- **four M5 bolts total**;
- DIN 7991-style countersunk socket-head bolts;
- bolts enter from the **outside**;
- each bolt passes through the printed bracket and plywood;
- a washer and hex nut remain accessible on the inside.

There are no captive-nut pockets, access windows or printed plugs in the current production model.

## Default stack

| Item | Default |
| --- | ---: |
| Bracket wall | 12 mm |
| Plywood | 12 mm |
| Washer | 1.0 mm |
| M5 nut | 4.7 mm |
| Extra thread allowance | 1 mm |
| Calculated minimum | 30.7 mm |
| Selected bolt | M5 × 35 mm |

These are design defaults, not a hardware guarantee. Measure the actual washer, nut and countersunk bolt before printing the final bracket.

## Bolt positions

Each arm has two bolt positions.

The first bolt is placed beyond the inside face of the other plywood panel by `bolt_offset`.

The second bolt is another `bolt_spacing` farther along the arm.

With the current defaults the centres are 24 mm and 38 mm from the inner-corner reference along each arm.

## Countersunk head

`countersunk_bolt_cut()` creates the M5 clearance hole, the 90-degree countersink for the DIN 7991 head, the shallow head recess, and a small **flat cylindrical edge relief** at both faces of the printed bracket.

`bolt_hole_edge_relief` controls that small flat step; the current default is **0.2 mm**. At the outside face it is slightly larger than the countersunk-head opening; at the inside face it is slightly larger than the M5 through-hole. It is deliberately **not** another conical chamfer.

The washer and nut remain serviceable from inside the joint.

## Perpendicular bolt-tip clearance

The horizontal and vertical bolts point toward the same inside corner.

The model calculates `tip_gap` and prints a warning if the perpendicular bolt tips come too close.

The current default uses `bolt_y_offset = 3`, which gives the closest perpendicular M5×35 bolt tips about 1 mm clearance. If the warning appears after changing dimensions, use a shorter bolt, change the bolt positions, or increase `bolt_y_offset`.

## Plywood drilling

The plywood preview includes matching `plywood_hole_diameter` holes.

The bracket can therefore be used as a drilling template after a physical fit check.

The plywood preview and hardware ghosts are not included in the STL.

## Historical alternatives

Earlier versions explored captive M4 nuts, access windows, plugs, T-nuts and inside counter-brackets.

Those remain design history, but they are **not part of the current production bracket**.

The current direction is intentionally simpler: four accessible M5 fasteners first, then only add more complicated mounting features if a real assembly problem justifies them.

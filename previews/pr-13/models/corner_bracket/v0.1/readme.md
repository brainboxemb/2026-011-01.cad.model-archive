<a name="TOP"></a>
# V0.1
# Corner bracket — v0.1

Outside-corner bracket for two 10 mm plywood panels. The original
parametric design is in [corner_bracket.scad](scad/corner_bracket.scad).
It has two captive-nut pockets accessible from the wood-facing surfaces
and two removable plugs that conceal the access windows after assembly.

**This is a work in progress.** Test-fit the M4 fasteners, nuts, printed
clearances, plywood corner relief and printed-part strength before use.
All dimensions below are millimetres.

## Design walkthrough

The six pictures show how the bracket is built, from a flat drawing to the finished part. Each step first explains **what happens and why**, then shows the corresponding OpenSCAD code. You do not need to understand every line at once. The complete model is in [corner_bracket.scad](scad/corner_bracket.scad); you can explore the steps in [design.scad](design/design.scad). All dimensions are in millimetres.

### 1. Draw the L profile and round its inside corner in 2D

For a visual explanation of the **arm-end and outside corner chamfers**
(`c` and `ce`), see the [Chamfer Guide](docs/chamfer-guide.html).

**Start with a simple L shape.** `polygon()` connects the vertices
around the bracket's outline. The two arm-end bevels and the outside
corner chamfer are included directly. The inner corner is initially
sharp at `(0, 0)`.

**Add a small rounded piece using ordinary 2D shapes.** Place a
`r_in × r_in` square just inside the sharp corner. Subtract a
`circle(r = r_in)` whose centre is at `(r_in, -r_in)`.
The remaining piece curves into the corner. `union()` joins it
to the L without affecting the opposite edges.

**Then give the finished 2D outline thickness.** `linear_extrude()`
produces the 20 mm wide bracket (`W`), and `rotate()` orients it.
The `$fn = 72` setting on this circle gives 5-degree steps, matching
the old 19-point inside radius. `r_in = 0` leaves a sharp corner.

![L-shaped polygon profile](design/01_profile.png)

**Relevant OpenSCAD code:**

    module inside_corner_2d(r) {
        difference() {
            translate([0, -r]) square([r, r]);
            translate([r, -r]) circle(r = r, $fn = 72);
        }
    }

    tip_top  = (ef > 0) ? [[armH - ef, 0], [armH, ef]] : [[armH, 0]];
    tip_vert = (ef > 0) ? [[-ef, -armV], [0, -armV + ef]] : [[0, -armV]];

    module sharp_profile() {
        polygon(concat(tip_top, [
            [armH, t - c],           // top-arm end
            [armH - c, t],
            [-t + ce, t],
            [-t, t - ce],            // outside corner
            [-t, -armV + c],
            [-t + c, -armV]          // vertical-arm end
        ], tip_vert, [[0, 0]]));
    }

    module profile() {
        union() {
            sharp_profile();
            if (r_in > 0) inside_corner_2d(r_in);
        }
    }

    module profile_extrusion() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                profile();
    }

### 2. Outer side-edge chamfers

**New to `hull()`?** Read the [illustrated Hull Guide](docs/hull-guide.html)
for the underlying operation, then the [Chamfer Guide](docs/chamfer-guide.html)
for **nine pictures of this actual model**: the polygon bevels, both hull
inputs, their convex envelope, clipping to the L and the print relief.

The sharp *side* edges get a bevel. The code first creates two versions
of the outside outline: one narrower in width and one with a smaller
perimeter. `hull()` connects them with sloping surfaces.
`intersection()` then trims the original L profile to that shape.
The two pieces still meet the plywood on flat faces. The parameter
`cs = 2` controls this bevel; `c` and `ce` belong to the 2D
polygon from Step 1.

![Outer side-edge chamfers](design/02_edge_chamfers.png)

**Relevant OpenSCAD code:**

    module outer_shape() {
        polygon([
            [armH, -armV], [armH, t - c], [armH - c, t], [-t + ce, t],
            [-t, t - ce], [-t, -armV + c], [-t + c, -armV]
        ]);
    }
    
    module side_chamfer_env() {
        rotate([90, 0, 0]) hull() {
            linear_extrude(height = W - 2 * cs, center = true) outer_shape();
            linear_extrude(height = W, center = true) offset(delta = -cs) outer_shape();
        }
    }
    
    module body() {
        intersection() {
            rotate([90, 0, 0]) linear_extrude(height = W, center = true) profile();
            if (cs > 0) side_chamfer_env();
            else rotate([90, 0, 0]) linear_extrude(height = W, center = true) outer_shape();
        }
    }

### 3. Captive nuts and access windows

**Now make room for the bolts and nuts.** OpenSCAD can treat ordinary shapes as cutting tools. Put a cylinder or box where you want a hole, then use `difference()` to subtract it from the bracket.

For each arm, the code makes four spaces: a hexagonal pocket for an M4 nut, a short slot to slide the nut into position, an opening on the wood-facing side to insert the nut, and the bolt hole. `cylinder($fn = 6)` is a cylinder with **six flat sides**, so it matches a hex nut; `cube()` cuts rectangular slots and openings. The two arms use the same idea but in different directions (`nut_top()` and `nut_side()`). The bolt's extra clearance is a **blind hole**, so it does not break through the outside wall.

![Captive nuts and access windows](design/03_nut_pockets.png)

**Relevant OpenSCAD code:**

    Wn       = nut_flats + nut_clr;   // nut pocket width (across flats)
    Ln       = (nut_type == "hex") ? Wn / cos(30) : Wn;   // pocket length (hex vertex-to-vertex)
    pocket_h = nut_h + 0.4;           // nut-pocket depth
    skin     = t - wood_wall - pocket_h - tip_hole;   // closed outside wall
    D        = wood_wall + pocket_h;  // window depth from wood-facing surface
    Lw       = Ln + win_extra;        // window length
    hx = ply_t + bolt_edge;           // top-arm bolt X position
    vz = -(ply_t + bolt_edge);        // vertical-arm bolt Z position
    tip_x = hx + Ln / 2 + lip_len;    // top-arm window start
    tip_z = vz - Ln / 2 - lip_len;    // vertical-arm window start
    
    module nut_top() {
        z0 = wood_wall;
        if (nut_type == "hex") {
            translate([hx, 0, z0]) cylinder(d = Ln, h = pocket_h, $fn = 6);
            translate([hx, -Wn / 2, z0]) cube([Ln / 2 + lip_len + 0.02, Wn, pocket_h]);
        } else
            translate([hx - Ln / 2, -Wn / 2, z0]) cube([Ln + lip_len + 0.02, Wn, pocket_h]);
        // Window opening from the wood-facing surface.
        translate([tip_x - 0.01, -Wn / 2, -0.01]) cube([Lw + 0.01, Wn, D + 0.01]);
        // Bolt hole through retaining wall plus blind clearance behind nut.
        translate([hx, 0, -1]) cylinder(d = bolt_d + bolt_clr, h = wood_wall + 2);
        translate([hx, 0, z0 + pocket_h - 0.01]) cylinder(d = bolt_d + bolt_clr, h = tip_hole + 0.01);
    }
    
    module nut_side() {
        x0 = -D;
        if (nut_type == "hex") {
            translate([x0, 0, vz]) rotate([0, 90, 0]) cylinder(d = Ln, h = pocket_h, $fn = 6);
            translate([x0, -Wn / 2, tip_z - 0.02]) cube([pocket_h, Wn, Ln / 2 + lip_len + 0.02]);
        } else
            translate([x0, -Wn / 2, tip_z - 0.02]) cube([pocket_h, Wn, Ln + lip_len + 0.02]);
        // Window opening from the wood-facing surface.
        translate([x0, -Wn / 2, tip_z - Lw]) cube([D + 0.01, Wn, Lw + 0.01]);
        // Bolt hole through retaining wall plus blind clearance behind nut.
        translate([1, 0, vz]) rotate([0, -90, 0]) cylinder(d = bolt_d + bolt_clr, h = wood_wall + 2);
        translate([x0 + 0.01, 0, vz]) rotate([0, -90, 0]) cylinder(d = bolt_d + bolt_clr, h = tip_hole + 0.01);
    }
    
    difference() {
        body();
        nut_top();
        nut_side();
    }

### 4. Elephant-foot relief

The [Chamfer Guide](docs/chamfer-guide.html) compares the side-edge
bevel and the elephant-foot relief visually, before and after each cut.

**What is elephant foot?** The very first printed layers sometimes
spread sideways where they touch the print bed. A nominally square edge
can become slightly wider at the base. The bracket is printed on one
of its flat **side faces**, so this bulge can interfere with the surfaces
where the bracket should fit against the plywood.

The solution is not to change the entire bracket. We remove a very
small **45-degree triangle** at the edges near the print bed. The
parameter `ef = 0.6` mm sets the nominal size of this relief;
the illustration deliberately exaggerates it so you can see the cut.

![First layer bulge versus an intentional triangular relief](figures/elephant-foot-section.svg)

**Where are these triangles removed?** The bracket has three kinds of
wood-facing edges: a straight edge along the horizontal arm, a straight
edge along the vertical arm, and the rounded inside corner. Relief is
applied at **both printed side faces** (`Y = +W/2` and `Y = -W/2`).

![Wood-facing relief edge locations on the bracket](figures/elephant-foot-edges.svg)

**We now use the same hull principle as for the outer side bevels.**
The opening between the arms is a convex 2D helper shape, with a
quarter-circle boundary at the rounded inside corner. We create
one normal copy at `Y = ±(W/2 - ef)` and one copy expanded by
`ef` at `Y = ±W/2`. A `hull()` connects these two outlines.

Two **separate hulls**, one for each printed side, are necessary:
joining the two expanded outside slices in a *single* global hull
would remove material through the entire middle of the bracket.
With two local hulls, only the outer 0.6 mm on each side is affected.
At the arm ends, where this relief meets the diagonal `cs` bevel,
small additional `relief_corner_miters()` hulls finish the join.
`difference()` then subtracts the resulting cutting volumes from
`body()`. This naturally follows the straight plywood faces AND the
rounded inner corner, replacing the former individual wedge cutters.

Setting `ef = 0` disables this relief. `cs` still controls the
larger outside chamfers in Step 2. The small 2D chamfers at the arm
tips are part of Step 1, as before. The geometric regression tests
compare the complete bracket against the former cutting method.
The small differences are concentrated near relief intersections;
actual print fit must still be checked.

The following render shows the resulting bracket. The complete
cutter modules used in the source code are listed underneath.

![Elephant-foot relief](design/04_print_relief.png)

**Relevant OpenSCAD code (shortened):**

    module inside_opening_2d() {
        reach = max(5, cs + ef + 1);
        difference() {
            translate([0, -armV - reach])
                square([armH + reach, armV + reach]);
            if (r_in > 0) inside_corner_2d(r_in);
        }
    }

    module opening_layer(y, expansion = 0) {
        translate([0, y, 0]) rotate([90, 0, 0])
            linear_extrude(height = 0.002, center = true)
                offset(delta = expansion) inside_opening_2d();
    }

    module inside_relief_envelope() {
        if (ef > 0)
            for (side = [-1, 1])
                hull() {
                    opening_layer(side * (W / 2 - ef));
                    opening_layer(side * W / 2, ef);
                }
    }

    module chamfered_body() {
        difference() {
            body(); // already has the outside hull chamfers
            if (ef > 0) {
                inside_relief_envelope();
                relief_corner_miters();
            }
        }
    }

    module bracket() {
        difference() {
            chamfered_body();
            nut_top();
            nut_side();
        }
    }

### 5. Access-window plugs

**The nut windows need covers.** Each plug starts as a small side-view drawing made with `polygon()`. The shape includes a hook that slips under the lip inside the bracket. `linear_extrude()` gives the plug its width; `plug_clr` leaves a little space around it so it can fit.

`difference()` can also cut a small hole or screwdriver slot to help remove the plug. `plug_print()` places one plug on its side for printing, and `plugs_print_pair()` puts **two separate plugs** next to each other in the STL.

![Access-window plugs](design/05_access_plugs.png)

**Relevant OpenSCAD code:**

    module plug_local() {
        pc = plug_clr;
        pw = Wn - 2 * pc;
        difference() {
            rotate([90, 0, 0]) linear_extrude(height = pw, center = true)
                polygon([
                    [pc, 0], [Lw - pc, 0],
                    [Lw - pc, D - pc - plug_ch], [Lw - pc - plug_ch, D - pc],   // insertion bevel
                    [-lip_l, D - pc],                                           // bottom face and tab
                    [-lip_l, D - pc - lip_thk], [pc, D - pc - lip_thk]
                ]);
            // Extraction hole (pin/small screw) or screwdriver slot.
            if (plug_handle == "hole") translate([Lw / 2, 0, -1]) cylinder(d = 2.5, h = 5, $fn = 24);
            if (plug_handle == "slot") translate([Lw - pc - 3, -pw / 2 - 1, -1]) cube([1.2, pw + 2, 3]);
        }
    }
    
    module plug_print() {
        translate([lip_l, D, (Wn - 2 * plug_clr) / 2]) rotate([90, 0, 0]) plug_local();
    }
    
    module plugs_print_pair() {
        for (i = [0, 1])
            translate([i * (Lw + lip_l + 4), 0, 0])
                plug_print();
    }

### 6. Installed preview

**Finally, check how everything fits together.** `plugs_in_place()` moves and turns the two plugs into their windows. `wood()` draws the two plywood panels at a right angle, including bolt holes and the rounded corner.

The plywood is only there to help you see the fit: the `%` before `wood()` tells OpenSCAD to show it as a transparent background shape. **It is not included in the printed bracket STL.**

![Installed preview](design/06_installed.png)

**Relevant OpenSCAD code:**

    module plugs_in_place() {
        translate([tip_x, 0, 0]) plug_local();
        multmatrix([[0, 0, -1, 0], [0, -1, 0, 0], [-1, 0, 0, tip_z], [0, 0, 0, 1]]) plug_local();
    }
    
    module wood() {
        color("burlywood", 0.45) difference() {
            union() {
                translate([0, -wood_w / 2, -ply_t]) cube([wood_len, wood_w, ply_t]);
                translate([0, -wood_w / 2, -wood_len]) cube([ply_t, wood_w, wood_len - ply_t]);
            }
            translate([hx, 0, -ply_t - 1]) cylinder(d = bolt_d + bolt_clr, h = ply_t + 2);
            translate([-1, 0, vz]) rotate([0, 90, 0]) cylinder(d = bolt_d + bolt_clr, h = ply_t + 2);
            // Remove material at the inside corner to match the bracket radius.
            if (r_in > 0) difference() {
                translate([-1, -wood_w / 2 - 1, -r_in]) cube([r_in + 1, wood_w + 2, r_in + 1]);
                translate([r_in, 0, -r_in]) rotate([90, 0, 0]) cylinder(r = r_in, h = wood_w + 4, center = true);
            }
        }
    }
    
    // Selection from design.scad:
    else if (design_step == "06_installed") {
        color("SteelBlue") bracket();
        color("Orange") plugs_in_place();
        %wood();
    }



<span></span>

---
## Table of Contents
1. [Parts list](#Parts_list)
1. [Main Assembly](#main_assembly)


## Further reading

A separate [OpenSCAD hull() guide](docs/hull-guide.html) shows how that
operation creates sloping sides and rounded *outside* corners.
The [Polygon and rounded-corner guide](docs/polygon-guide.html) compares
the **2D square-minus-circle method now used in the bracket** with an
equivalent 3D cube-minus-cylinder approach and the former
point-based `polygon()` construction. Only the inside-corner
implementation changed; the intended shape, chamfers and other
bracket features were preserved.

## Alternative mounting arrangements

The current model uses bolts from the **inside** of the plywood into
**captured nuts** in the outside bracket. There are other possibilities:
reverse the bolts, use accessible locking flange nuts, replace hex nuts
with thin square nuts, or add a second **inside counter-bracket**.

The options, simple bolt-path diagrams, differences between nut types,
the supplied stainless-steel product references, and the bolt-length
constraints are compared in the separate
**[Mounting options and fastener comparison](docs/mounting-options.html)**.

These are design alternatives. In v0.1, the **bolt-from-inside,
captive-nut** configuration is the only implemented bolt direction;
the other arrangements require new CAD and physical testing.

## Printing and assembly

1. Print one bracket and one pair of access plugs, with each part on
   its flat side as arranged by the original designer.
2. Check M4 nut fit in both pockets; insert nuts through the windows
   and slide them to the bolt holes.
3. Engage each plug tab under its retaining lip and press the far end down.
4. Fit the bracket on the outside corner of the plywood joint and
   fasten from the inside through the plywood. Confirm bolt lengths
   against real parts; nominal M4x16 is only a starting assumption.

The CAD files below are the definitive geometry. The automatically
generated bill of materials includes the **printed bracket and one
two-plug set**. Plywood, bolts and nuts are not modeled BOM items.

<span></span>
[Top](#TOP)

---
<a name="Parts_list"></a>
## Parts list
| <span style="writing-mode: vertical-rl; text-orientation: mixed;">Main</span> | <span style="writing-mode: vertical-rl; text-orientation: mixed;">TOTALS</span> |  |
|---:|---:|:---|
|  | | **3D printed parts** |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;access_plugs.stl |
| &nbsp;&nbsp;1&nbsp; |  &nbsp;&nbsp;1&nbsp; | &nbsp;&nbsp;corner_bracket.stl |
| &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp;2&nbsp; | &nbsp;&nbsp;Total 3D printed parts count |

<span></span>
[Top](#TOP)

---
<a name="main_assembly"></a>
## Main Assembly
### 3D Printed parts

| 1 x [access_plugs.stl](stls/access_plugs.stl) | 1 x [corner_bracket.stl](stls/corner_bracket.stl) |
|---|---|
| ![access_plugs.stl](stls/access_plugs.png) | ![corner_bracket.stl](stls/corner_bracket.png) 



### Assembly instructions
![main_assembly](assemblies/main_assembly_tn.png)

Printed bracket and the pair of access-window plugs displayed side by
side. See the final design step above for their actual installed position.

![main_assembled](assemblies/main_assembled_tn.png)

<span></span>
[Top](#TOP)

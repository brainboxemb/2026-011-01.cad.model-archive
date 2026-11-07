// Outside-corner L bracket for plywood joints.
// All dimensions are in millimetres. Adjust settings in the OpenSCAD Customizer.
//
// Side view (X to the right, Z upwards), with wood inside the bracket:
//
//     ____________________        <- bracket, top arm (outside the horizontal panel)
//    /  ##################
//   |  ||==================      <- horizontal plywood panel (10 mm)
//   |  ||
//   |  ||  vertical plywood panel
//   |  ||
//    bracket, vertical arm (outside the upright panel)
//
// Bolts enter from inside the plywood and thread into captive nuts in the bracket.
// Insert a nut through the access window on the wood-facing side of the bracket,
// slide it under the 3 mm retaining wall and push it against the stop.
// Hook the plug tab under the retaining lip, then press the opposite end down.
// The plywood covers the window; the outside face of the bracket stays solid.
//
// PRINTING: put the bracket on one flat side and the plugs on their sides.
// This lets layer lines follow the part outlines for improved strength.
//
// Requires inspection.scad in this directory for the optional section view.

use <inspection.scad>

/* [Display] */
part       = "bracket"; // [bracket, plug]
show_wood  = true;     // translucent plywood preview; excluded from STL
show_plugs = false;    // display fitted plugs; excluded from STL
part_color = [0.29, 0.56, 0.72]; // color
plug_color = [0.93, 0.58, 0.22]; // color

/* [Section inspection] */
c_section_axis        = "None";     // [None, X, Y, Z]
c_section_position_mm = 0;          // [-60:0.5:60]
c_section_depth_mm    = 10;         // [0.1:0.1:80]
c_section_direction   = "Positive"; // [Positive, Negative]

/* [Plywood] */
ply_t    = 10;     // plywood thickness
wood_w   = 60;     // panel width, display only
wood_len = 80;     // panel length, display only

/* [Bracket geometry] */
W        = 20;     // bracket width
t        = 10;     // bracket wall thickness
armH     = 40;     // length of top arm from the outer plywood end
armV     = 40;     // length of vertical arm from the top of horizontal plywood
ce       = 6;      // 45-degree outer corner chamfer (6 gives 9.9 mm diagonal wall)
c        = 3;      // 45-degree chamfer at outer arm ends
cs       = 2;      // 45-degree side-edge chamfers; 0 disables

/* [Print compensation] */
ef       = 0.6;    // 45-degree elephant-foot relief on print-facing sides; 0 disables
r_in     = 2.0;    // inside corner radius: plywood must be rounded at least this much; 0 or >=1

/* [Bolt and captive nut] */
bolt_edge = 10;    // bolt position beyond the inner face of the other panel
nut_type  = "hex"; // [hex, square]
bolt_d    = 4;
bolt_clr  = 0.4;   // bolt-hole clearance
nut_flats = 7;     // M4 nut across flats; measure your actual nuts
nut_h     = 3.2;   // nominal M4 nut thickness
nut_clr   = 0.3;   // captive-nut pocket clearance
wood_wall = 3;     // load-bearing wall between plywood and nut
tip_hole  = 1;     // blind hole for extra bolt length beyond the nut
                   // (M4x16 nominal fit; outer skin = t - wood_wall - pocket_h - tip_hole)

/* [Window plug] */
plug_clr    = 0.15; // clearance around access plug
lip_len     = 2.5;  // free slot from captive nut to window for plug's hooked tab
lip_thk     = 2.4;  // tab thickness
win_extra   = 0.6;  // extra window length to allow angled plug insertion
plug_ch     = 1.0;  // 45-degree bevel on far end of plug for insertion
plug_handle = "hole"; // [hole, slot, none] hole = pin/screw opening, slot = screwdriver notch

/* [Hidden] */
$fn = 48;

// ---------- Derived dimensions ----------
Wn       = nut_flats + nut_clr;   // nut pocket width (across flats)
Ln       = (nut_type == "hex") ? Wn / cos(30) : Wn;   // pocket length (hex vertex-to-vertex)
pocket_h = nut_h + 0.4;           // nut-pocket depth
skin     = t - wood_wall - pocket_h - tip_hole;   // closed outside wall
D        = wood_wall + pocket_h;  // window depth from wood-facing surface
Lw       = Ln + win_extra;        // window length
lip_l    = lip_len - 0.2;         // plug tab length

hx = ply_t + bolt_edge;           // top-arm bolt X position
vz = -(ply_t + bolt_edge);        // vertical-arm bolt Z position
tip_x = hx + Ln / 2 + lip_len;    // top-arm window start
tip_z = vz - Ln / 2 - lip_len;    // vertical-arm window start

echo("Outer skin behind nut (mm):", skin);
echo("Window end (mm):", tip_x + Lw, " arm length:", armH);

// ---------- Plywood preview (joint corner at origin) ----------
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

// ---------- Bracket side profile ----------
// Make the inside fillet from ordinary 2D shapes, before extrusion.
// The square sits in the open part of the L, at the sharp inner corner.
// Subtracting a circle leaves only the small curved region to add.
// Keep 72 segments (5 degrees each) to match the legacy 19-point arc.
module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

// End edges also receive elephant-foot relief so the wood-facing bevel
// continues around side edges, ends, and the inside corner.
tip_top  = (ef > 0) ? [[armH - ef, 0], [armH, ef]] : [[armH, 0]];
tip_vert = (ef > 0) ? [[-ef, -armV], [0, -armV + ef]] : [[0, -armV]];

// Draw the unchanged L outline with a sharp inside corner at (0,0).
// The arm-end and outside-corner chamfers are part of this outline.
module sharp_profile() {
    polygon(concat(tip_top, [
        [armH, t - c],            // 45-degree top-arm end
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],             // 45-degree outside corner
        [-t, -armV + c],
        [-t + c, -armV]           // 45-degree vertical-arm end
    ], tip_vert, [[0, 0]]));
}

// Complete the side profile in 2D, then extrude it in profile_extrusion().
// Radius zero leaves the original sharp corner without creating a square.
module profile() {
    union() {
        sharp_profile();
        if (r_in > 0) inside_corner_2d(r_in);
    }
}

// Convex envelope of the bracket with its inside corner filled in. Side
// chamfers affect the outer edges only; the wood-facing area stays flat.
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

// Plain extruded side profile before side chamfers or pockets.
module profile_extrusion() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            profile();
}

module body() {
    intersection() {
        rotate([90, 0, 0]) linear_extrude(height = W, center = true) profile();
        if (cs > 0) side_chamfer_env();
        else rotate([90, 0, 0]) linear_extrude(height = W, center = true) outer_shape();
    }
}

// ---------- Hull-based elephant-foot relief ----------
// Keep the complete L profile unchanged through the middle of the part.
// On each printed side, hull() connects that full profile to a copy inset
// by ef. Because body() already has the larger outer side chamfer cs, the
// cs envelope remains dominant on outside edges; this envelope only adds
// the smaller print relief where body() still reaches the wood-facing edges.
//
// Using the complete profile here means the arm-end chamfers and rounded
// inside corner are part of the hull input itself. No separate corner-miter
// cutters are required.
module profile_layer(y, inset = 0) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 0.002, center = true)
                if (inset > 0)
                    offset(delta = -inset) profile();
                else
                    profile();
}

module print_relief_env() {
    if (ef > 0) {
        // Unchanged central width.
        rotate([90, 0, 0])
            linear_extrude(height = W - 2 * ef, center = true)
                profile();

        // Same construction on both printed side faces.
        for (side = [-1, 1])
            hull() {
                profile_layer(side * (W / 2 - ef));
                profile_layer(side * W / 2, ef);
            }
    } else
        profile_extrusion();
}

module chamfered_body() {
    intersection() {
        body();
        print_relief_env();
    }
}

// ---------- Captive-nut pocket with window on wood-facing side ----------
// The nut pocket lies behind wood_wall. A free slot connects the pocket
// to the access window. Slide the nut through the window towards the corner,
// then hook the plug tab into the slot.

// Top arm: bolt along Z.
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

// Vertical arm: bolt along X.
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

module bracket() {
    difference() {
        chamfered_body();
        nut_top();
        nut_side();
    }
}

// ---------- Access-window plug ----------
// Window-local coordinates: u runs along the arm towards its end (0=start),
// v is transverse (Y), and w is depth from the wood-facing surface.
// The tab at u<0 engages the slot under the retaining wall.
// Insert the tab at an angle, then press the far end flush with the wood face.
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

// Lay plugs on their sides for printing; layer lines run through each tab.
module plug_print() {
    translate([lip_l, D, (Wn - 2 * plug_clr) / 2]) rotate([90, 0, 0]) plug_local();
}

// Two separate plugs positioned for printing and documentation exports.
module plugs_print_pair() {
    for (i = [0, 1])
        translate([i * (Lw + lip_l + 4), 0, 0])
            plug_print();
}

// Show installed plugs in the access windows for visual inspection only.
module plugs_in_place() {
    translate([tip_x, 0, 0]) plug_local();
    multmatrix([[0, 0, -1, 0], [0, -1, 0, 0], [-1, 0, 0, tip_z], [0, 0, 0, 1]]) plug_local();
}

// ===== DISPLAY / PRINT-PART SELECTOR =====
if (part == "plug") {
    util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
        color(plug_color)
            plugs_print_pair();
} else {
    util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
        color(part_color) bracket();
    if (show_wood)
        %util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
            wood();
    if (show_plugs)
        %util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
            color(plug_color) plugs_in_place();
}
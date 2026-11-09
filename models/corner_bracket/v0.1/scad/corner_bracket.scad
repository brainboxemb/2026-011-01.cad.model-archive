// Outside-corner L bracket for plywood joints - bolts from the outside (M5 default).
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
// Two DIN 7991 countersunk socket-head bolts per arm enter from the OUTSIDE, with the head
// sunk slightly below the surface. They cross the plywood and are fixed on the inside with
// a washer (or flange nut) and a nut. No captive-nut pockets, windows or plugs.
//
// M5 stack per bolt: bracket 12 + plywood 10 + washer 1 + nut 4.7 + about 1 thread = 28.7 mm,
// so M5 x 30. (M4 values: head 8, washer 9 x 0.8, nut AF7 x 3.2, bolt length 30.)
// Use the bracket as a drilling template for the plywood holes.
//
// PRINTING: put the bracket on one flat side so layer lines follow the L outline.
//
// Requires inspection.scad in this directory for the optional section view.

use <inspection.scad>

/* [Display] */
show_wood     = true;     // translucent plywood preview; excluded from STL
show_hardware = false;    // bolts, washers and nuts as ghosts; excluded from STL
part_color     = [0.29, 0.56, 0.72]; // color
hardware_color = [0.65, 0.65, 0.70]; // color

/* [Section inspection] */
c_section_axis = "None";     // [None, X, Y, Z]
c_section_position_mm = 0;          // [-60:0.5:60]
c_section_depth_mm = 10;         // [0.1:0.1:80]
c_section_direction = "Positive"; // [Positive, Negative]

/* [Plywood] */
plywood_thickness = 10;     // plywood thickness
plywood_hole_diameter = 5.5; // drilled plywood hole (display only)
preview_panel_width = 60;     // panel width, display only
preview_panel_length = 80;     // panel length, display only

/* [Bracket geometry] */
bracket_width        = 24;   // bracket width across Y
wall_thickness       = 12;   // nominal arm thickness
horizontal_arm_length = 50;  // top-arm length
vertical_arm_length   = 50;  // vertical-arm length
outer_corner_chamfer  = 6;   // large 45-degree outer corner chamfer
arm_end_chamfer       = 3;   // 45-degree chamfer at both arm ends
side_edge_chamfer     = 2;   // bevel on the broad side-face outer edges; 0 disables

/* [Print compensation] */
elephant_foot_relief = 0.6; // 45-degree relief at print-facing contact edges; 0 disables
inside_corner_radius = 2.0; // plywood inside corner must match; use 0 or >= 1 mm

/* [Bolts] */
bolts_per_arm        = 2;    // [1, 2]
bolt_offset          = 10;   // first bolt: distance beyond the inner face of the other panel
bolt_spacing         = 16;   // second bolt this much further along the arm (26 mm from the inner face)
bolt_y_offset        = 0;    // top-arm bolts at +offset, vertical-arm bolts at -offset across Y; 5 gives the bolt tips more room
bolt_diameter        = 5;    // M5 (M4: 4)
bolt_clearance       = 0.4;  // clearance in the bracket's through hole
head_diameter        = 10;   // DIN 7991 head (M5: 10, M4: 8)
head_clearance       = 0.4;  // clearance on the head diameter
head_recess          = 1;    // head top sits this far below the outer surface (0 = flush)
hole_edge_relief     = 0.4;  // shallow flat edge relief; radial enlargement and depth (0 = off)
bolt_length          = 30;   // including the countersunk head

/* [Inside washer and nut] */
washer_diameter  = 10;    // M5 DIN 125: 10 (M4: 9)
washer_thickness = 1.0;   // M5: 1.0 (M4: 0.8); use 0 with a flange nut
nut_across_flats = 8;     // M5: 8 (M4: 7)
nut_thickness    = 4.7;   // M5 ISO 4032: 4.7 (DIN 934: 4.0; M4: 3.2)

/* [Hidden] */
$fn = 48;

// ---------- Derived dimensions ----------
bolt_radius = bolt_diameter / 2;
top_bolt_x  = [for (i = [0 : bolts_per_arm - 1]) plywood_thickness + bolt_offset + i * bolt_spacing];
vertical_bolt_z = [for (i = [0 : bolts_per_arm - 1]) -(plywood_thickness + bolt_offset + i * bolt_spacing)];
min_bolt_length = wall_thickness + plywood_thickness + washer_thickness + nut_thickness + 1;

// Closest approach of the bolt tips inside the corner (top-arm tip z, vertical-arm tip x).
top_tip_z      = wall_thickness + head_recess - bolt_length;
vertical_tip_x = -wall_thickness + head_recess + bolt_length;
tip_gap = min([for (x = top_bolt_x) for (z = vertical_bolt_z)
    max(max(x - bolt_radius - vertical_tip_x, top_tip_z - (z + bolt_radius)),
        2 * bolt_y_offset - bolt_diameter)]);

echo("Minimum bolt length (mm):", min_bolt_length, " bolt_length:", bolt_length);
echo("Margin between last countersink and the arm end (mm):",
     horizontal_arm_length - (top_bolt_x[bolts_per_arm - 1] + (head_diameter + head_clearance) / 2
                              + head_recess + counterbore_flare));
echo("Gap between neighbouring washers on the inside (mm):", bolt_spacing - washer_diameter);
echo("Closest approach of top-arm and vertical-arm bolt tips (mm):", tip_gap);
if (min_bolt_length > bolt_length) echo("WARNING: bolt too short for washer, nut and thread");
if (tip_gap < 0.5) echo("WARNING: bolt tips nearly touch inside the corner; shorten the bolts or increase bolt_y_offset");

// ---------- Plywood preview (joint corner at origin) ----------
module wood() {
    color("burlywood", 0.45) difference() {
        union() {
            translate([0, -preview_panel_width / 2, -plywood_thickness]) cube([preview_panel_length, preview_panel_width, plywood_thickness]);
            translate([0, -preview_panel_width / 2, -preview_panel_length]) cube([plywood_thickness, preview_panel_width, preview_panel_length - plywood_thickness]);
        }
        for (x = top_bolt_x)
            translate([x, bolt_y_offset, -plywood_thickness - 1]) cylinder(d = plywood_hole_diameter, h = plywood_thickness + 2);
        for (z = vertical_bolt_z)
            translate([-1, -bolt_y_offset, z]) rotate([0, 90, 0]) cylinder(d = plywood_hole_diameter, h = plywood_thickness + 2);
        // Remove material at the inside corner to match the bracket radius.
        if (inside_corner_radius > 0) difference() {
            translate([-1, -preview_panel_width / 2 - 1, -inside_corner_radius]) cube([inside_corner_radius + 1, preview_panel_width + 2, inside_corner_radius + 1]);
            translate([inside_corner_radius, 0, -inside_corner_radius]) rotate([90, 0, 0]) cylinder(r = inside_corner_radius, h = preview_panel_width + 4, center = true);
        }
    }
}

// ---------- Bracket side profile ----------
// Make the inside fillet from ordinary 2D shapes, before extrusion.
// The square sits in the open part of the L, at the sharp inner corner.
// Subtracting a circle leaves only the small curved region to add.
// Keep 72 segments (5 degrees each) to match the legacy 19-point arc.
module inside_corner_fill_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

// Draw the unchanged L outline with a sharp inside corner at (0,0).
// The arm-end and outside-corner chamfers are part of this outline.
module base_profile_2d() {
    // Arm end-face print relief belongs to the 2D outline, not another 3D cut.
    top_tip =
        (elephant_foot_relief > 0)
            ? [[horizontal_arm_length - elephant_foot_relief, 0],
               [horizontal_arm_length, elephant_foot_relief]]
            : [[horizontal_arm_length, 0]];

    vertical_tip =
        (elephant_foot_relief > 0)
            ? [[-elephant_foot_relief, -vertical_arm_length],
               [0, -vertical_arm_length + elephant_foot_relief]]
            : [[0, -vertical_arm_length]];

    polygon(concat(top_tip, [
        [horizontal_arm_length, wall_thickness - arm_end_chamfer],
        [horizontal_arm_length - arm_end_chamfer, wall_thickness],
        [-wall_thickness + outer_corner_chamfer, wall_thickness],
        [-wall_thickness, wall_thickness - outer_corner_chamfer],
        [-wall_thickness, -vertical_arm_length + arm_end_chamfer],
        [-wall_thickness + arm_end_chamfer, -vertical_arm_length]
    ], vertical_tip, [[0, 0]]));
}

// Complete the side profile in 2D, then extrude it in profile_body().
// Radius zero leaves the original sharp corner without creating a square.
module bracket_profile_2d() {
    union() {
        base_profile_2d();
        if (inside_corner_radius > 0) inside_corner_fill_2d(inside_corner_radius);
    }
}

// Convex envelope of the bracket with its inside corner filled in. Side
// chamfers affect the outer edges only; the wood-facing area stays flat.
module outer_chamfer_envelope_2d() {
    polygon([
        [horizontal_arm_length, -vertical_arm_length], [horizontal_arm_length, wall_thickness - arm_end_chamfer], [horizontal_arm_length - arm_end_chamfer, wall_thickness], [-wall_thickness + outer_corner_chamfer, wall_thickness],
        [-wall_thickness, wall_thickness - outer_corner_chamfer], [-wall_thickness, -vertical_arm_length + arm_end_chamfer], [-wall_thickness + arm_end_chamfer, -vertical_arm_length]
    ]);
}

module outer_side_chamfer_keep_envelope() {
    rotate([90, 0, 0]) hull() {
        linear_extrude(height = bracket_width - 2 * side_edge_chamfer, center = true) outer_chamfer_envelope_2d();
        linear_extrude(height = bracket_width, center = true) offset(delta = -side_edge_chamfer) outer_chamfer_envelope_2d();
    }
}

// Plain extruded side profile before side chamfers or pockets.
module profile_body() {
    rotate([90, 0, 0])
        linear_extrude(height = bracket_width, center = true)
            bracket_profile_2d();
}

module outer_side_chamfered_body() {
    if (side_edge_chamfer > 0)
        intersection() {
            profile_body();
            outer_side_chamfer_keep_envelope();
        }
    else
        profile_body();
}

// ---------- Elephant-foot print compensation ----------
// The main relief on each printable broad side is ONE continuous cutting
// volume. Its boundary follows the full plywood-contact path:
//
//   horizontal contact edge -> rounded inside corner -> vertical contact edge
//
// Only the small arm-tip junctions are corrected separately. Relief at the
// two arm end faces is also kept as a separate, clearly named operation.

construction_epsilon = 0.01;

// Empty space between the two arms, deliberately extended beyond both arm
// ends. This is helper geometry only; it is not printable geometry.
module inside_opening_2d() {
    reach = max(5, side_edge_chamfer + elephant_foot_relief + 1);

    difference() {
        translate([0, -vertical_arm_length - reach])
            square([
                horizontal_arm_length + reach,
                vertical_arm_length + reach
            ]);

        if (inside_corner_radius > 0)
            inside_corner_fill_2d(inside_corner_radius);
    }
}

// Thin slice of the opening at one Y position. Expanding the opening at the
// printable side face and connecting it to the normal opening one relief
// depth inward creates the full 45-degree side relief in one hull.
module inside_side_relief_layer(y, expansion = 0) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 0.002, center = true)
                offset(delta = expansion)
                    inside_opening_2d();
}

// One continuous main cut per broad print face. Two hulls are required only
// because the bracket can be printed on either side; each hull is local to
// one side and does not enlarge the opening through the middle of the part.
module inside_side_relief_cuts() {
    if (elephant_foot_relief > 0)
        for (side = [-1, 1])
            hull() {
                inside_side_relief_layer(
                    side * (bracket_width / 2 - elephant_foot_relief)
                );
                inside_side_relief_layer(
                    side * bracket_width / 2,
                    elephant_foot_relief
                );
            }
}

// Small local correction where the continuous side relief reaches the
// diagonal outer side chamfer at an arm tip.
//
// The old version built a local coordinate system with multmatrix(). That is
// mathematically general, but hard to read for two fixed 45-degree corners.
// A simple triangular prism plus ordinary rotations describes the same cut.
module arm_tip_relief_wedge(length) {
    linear_extrude(height = length)
        polygon([
            [-elephant_foot_relief - 1, -1],
            [1, -1],
            [1, elephant_foot_relief + 1]
        ]);
}

module arm_tip_relief_cuts() {
    s2 = sqrt(2) / 2;
    cut_length = side_edge_chamfer * sqrt(2) + 2;

    if (elephant_foot_relief > 0 && side_edge_chamfer > 0)
        for (mirror_side = [0, 1])
            mirror([0, mirror_side, 0]) {
                // Horizontal arm tip.
                translate([
                    horizontal_arm_length - side_edge_chamfer - s2,
                    bracket_width / 2 + s2,
                    0
                ])
                    rotate([90, 0, 45])
                        arm_tip_relief_wedge(cut_length);

                // Vertical arm tip.
                translate([
                    0,
                    bracket_width / 2 - side_edge_chamfer - s2,
                    -vertical_arm_length - s2
                ])
                    rotate([0, 45, 90])
                        arm_tip_relief_wedge(cut_length);
            }
}

module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();
        inside_side_relief_cuts();
        arm_tip_relief_cuts();
    }
}

// ---------- Countersunk bolt cuts ----------
// Local frame: origin on the outer face of the bracket, +Z pointing inwards through the
// bracket and the plywood.
module top_bolt_frame(x)      translate([x, bolt_y_offset, wall_thickness]) rotate([180, 0, 0]) children();
module vertical_bolt_frame(z) translate([-wall_thickness, -bolt_y_offset, z]) rotate([0, 90, 0]) children();

module countersunk_bolt_cut() {
    dk = head_diameter + head_clearance;        // counterbore diameter (head plus clearance)
    d0 = bolt_diameter + bolt_clearance;        // through-hole diameter
    translate([0, 0, -1]) cylinder(d = d0, h = wall_thickness + 2);
    // 45-degree cone directly under the head (head top sits at depth head_recess)
    translate([0, 0, head_recess]) cylinder(d1 = dk, d2 = d0, h = (dk - d0) / 2);
    // straight counterbore from the head top up to the outer surface
    translate([0, 0, -1]) cylinder(d = dk, h = head_recess + 1.01);
    // Small flat edge reliefs. These are intentionally cylindrical, not
    // conical chamfers: just a shallow, slightly larger circle at each face.
    if (hole_edge_relief > 0) {
        // Outside face: around the countersunk-head opening.
        translate([0, 0, -1])
            cylinder(
                d = dk + 2 * hole_edge_relief,
                h = hole_edge_relief + 1
            );

        // Inside face: where the M5 through-hole exits the bracket.
        translate([0, 0, wall_thickness - hole_edge_relief])
            cylinder(
                d = d0 + 2 * hole_edge_relief,
                h = hole_edge_relief + 1
            );
    }
}

module bolt_cuts() {
    for (x = top_bolt_x)      top_bolt_frame(x)      countersunk_bolt_cut();
    for (z = vertical_bolt_z) vertical_bolt_frame(z) countersunk_bolt_cut();
}

module bracket() {
    difference() {
        print_compensated_body();
        bolt_cuts();
    }
}

// ---------- Hardware ghosts (inspection only) ----------
module hardware_local() {
    translate([0, 0, head_recess]) {
        cylinder(d1 = head_diameter, d2 = bolt_diameter, h = (head_diameter - bolt_diameter) / 2);
        cylinder(d = bolt_diameter, h = bolt_length - head_recess);
    }
    translate([0, 0, wall_thickness + plywood_thickness]) {
        difference() {                                                   // washer
            cylinder(d = washer_diameter, h = max(washer_thickness, 0.01));
            translate([0, 0, -1]) cylinder(d = bolt_diameter + 0.2, h = washer_thickness + 2);
        }
        translate([0, 0, washer_thickness]) difference() {                // hex nut
            cylinder(d = nut_across_flats / cos(30), h = nut_thickness, $fn = 6);
            translate([0, 0, -1]) cylinder(d = bolt_diameter, h = nut_thickness + 2);
        }
    }
}

module hardware() {
    for (x = top_bolt_x)      top_bolt_frame(x)      hardware_local();
    for (z = vertical_bolt_z) vertical_bolt_frame(z) hardware_local();
}

// ===== DISPLAY SELECTOR =====
util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
    color(part_color) bracket();
if (show_wood)
    %util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
        wood();
if (show_hardware)
    %util_section_inspect(c_section_axis, c_section_position_mm, c_section_depth_mm, c_section_direction)
        color(hardware_color) hardware();

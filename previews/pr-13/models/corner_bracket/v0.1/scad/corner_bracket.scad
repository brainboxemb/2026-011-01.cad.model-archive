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
part = "bracket"; // [bracket, plug]
show_wood  = true;     // translucent plywood preview; excluded from STL
show_plugs = false;    // display fitted plugs; excluded from STL
part_color = [0.29, 0.56, 0.72]; // color
plug_color = [0.93, 0.58, 0.22]; // color

/* [Section inspection] */
c_section_axis = "None";     // [None, X, Y, Z]
c_section_position_mm = 0;          // [-60:0.5:60]
c_section_depth_mm = 10;         // [0.1:0.1:80]
c_section_direction = "Positive"; // [Positive, Negative]

/* [Plywood] */
plywood_thickness = 10;     // plywood thickness
preview_panel_width = 60;     // panel width, display only
preview_panel_length = 80;     // panel length, display only

/* [Bracket geometry] */
bracket_width        = 20;   // bracket width across Y
wall_thickness       = 10;   // nominal arm thickness
horizontal_arm_length = 40;  // top-arm length
vertical_arm_length   = 40;  // vertical-arm length
outer_corner_chamfer  = 6;   // large 45-degree outer corner chamfer
arm_end_chamfer       = 3;   // 45-degree chamfer at both arm ends
side_edge_chamfer     = 2;   // bevel on the broad side-face outer edges; 0 disables

/* [Print compensation] */
elephant_foot_relief = 0.6; // 45-degree relief at print-facing contact edges; 0 disables
inside_corner_radius = 2.0; // plywood inside corner must match; use 0 or >= 1 mm

/* [Bolt and captive nut] */
bolt_offset                 = 10;    // bolt position beyond the inner face of the other panel
nut_type                    = "hex"; // [hex, square]
bolt_diameter               = 4;
bolt_clearance              = 0.4;
nut_across_flats            = 7;     // measure actual M4 nuts
nut_thickness               = 3.2;
nut_clearance               = 0.3;
retaining_wall_thickness    = 3;     // load-bearing wall between plywood and nut
blind_bolt_clearance_depth  = 1;     // extra bolt depth behind the nut
// Nominal M4x16 is only a starting assumption; verify the real stack-up.

/* [Window plug] */
plug_clearance            = 0.15;
nut_to_window_slot_length = 2.5; // free slot used by the plug hook
plug_tab_thickness        = 2.4;
window_extra_length       = 0.6;  // allows angled plug insertion
plug_end_chamfer          = 1.0;  // insertion bevel at the far end
plug_handle               = "hole"; // [hole, slot, none]

/* [Hidden] */
$fn = 48;

// ---------- Derived dimensions ----------
nut_pocket_width = nut_across_flats + nut_clearance;   // nut pocket width (across flats)
nut_pocket_length = (nut_type == "hex") ? nut_pocket_width / cos(30) : nut_pocket_width;   // pocket length (hex vertex-to-vertex)
nut_pocket_depth = nut_thickness + 0.4;           // nut-pocket depth
outside_skin = wall_thickness - retaining_wall_thickness - nut_pocket_depth - blind_bolt_clearance_depth;   // closed outside wall
window_depth = retaining_wall_thickness + nut_pocket_depth;  // window depth from wood-facing surface
window_length = nut_pocket_length + window_extra_length;        // window length
plug_tab_length = nut_to_window_slot_length - 0.2;         // plug tab length

top_bolt_x = plywood_thickness + bolt_offset;           // top-arm bolt X position
vertical_bolt_z = -(plywood_thickness + bolt_offset);        // vertical-arm bolt Z position
top_window_start_x = top_bolt_x + nut_pocket_length / 2 + nut_to_window_slot_length;    // top-arm window start
vertical_window_start_z = vertical_bolt_z - nut_pocket_length / 2 - nut_to_window_slot_length;    // vertical-arm window start

echo("Outer skin behind nut (mm):", outside_skin);
echo("Window end (mm):", top_window_start_x + window_length, " arm length:", horizontal_arm_length);

// ---------- Plywood preview (joint corner at origin) ----------
module wood() {
    color("burlywood", 0.45) difference() {
        union() {
            translate([0, -preview_panel_width / 2, -plywood_thickness]) cube([preview_panel_length, preview_panel_width, plywood_thickness]);
            translate([0, -preview_panel_width / 2, -preview_panel_length]) cube([plywood_thickness, preview_panel_width, preview_panel_length - plywood_thickness]);
        }
        translate([top_bolt_x, 0, -plywood_thickness - 1]) cylinder(d = bolt_diameter + bolt_clearance, h = plywood_thickness + 2);
        translate([-1, 0, vertical_bolt_z]) rotate([0, 90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = plywood_thickness + 2);
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

// End edges also receive elephant-foot relief so the wood-facing bevel
// continues around side edges, ends, and the inside corner.
top_arm_inner_tip_points  = (elephant_foot_relief > 0) ? [[horizontal_arm_length - elephant_foot_relief, 0], [horizontal_arm_length, elephant_foot_relief]] : [[horizontal_arm_length, 0]];
vertical_arm_inner_tip_points = (elephant_foot_relief > 0) ? [[-elephant_foot_relief, -vertical_arm_length], [0, -vertical_arm_length + elephant_foot_relief]] : [[0, -vertical_arm_length]];

// Draw the unchanged L outline with a sharp inside corner at (0,0).
// The arm-end and outside-corner chamfers are part of this outline.
module base_profile_2d() {
    polygon(concat(top_arm_inner_tip_points, [
        [horizontal_arm_length, wall_thickness - arm_end_chamfer],            // 45-degree top-arm end
        [horizontal_arm_length - arm_end_chamfer, wall_thickness],
        [-wall_thickness + outer_corner_chamfer, wall_thickness],
        [-wall_thickness, wall_thickness - outer_corner_chamfer],             // 45-degree outside corner
        [-wall_thickness, -vertical_arm_length + arm_end_chamfer],
        [-wall_thickness + arm_end_chamfer, -vertical_arm_length]           // 45-degree vertical-arm end
    ], vertical_arm_inner_tip_points, [[0, 0]]));
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

// ---------- Elephant-foot print compensation: cut geometry ----------
// The bracket is printed on either broad side face. First-layer bulging can
// interfere with the plywood-facing edges, so we describe the small volumes
// that must be REMOVED and subtract them with difference().
//
// This deliberately follows the archive-wide design rule:
//   easy-to-describe unwanted material -> explicit cutter + difference().
//
// The relief consists of:
//   1. straight 45-degree cuts along both plywood-facing arm edges;
//   2. a revolved 45-degree cut around the rounded inside corner;
//   3. short diagonal cuts where the relief meets the outer side chamfer.
//
// The same cutter set is mirrored to both printable side faces.

module elephant_foot_wedge_profile_2d() {
    polygon([
        [bracket_width / 2 - elephant_foot_relief - 1, -1],
        [bracket_width / 2 + 1, -1],
        [bracket_width / 2 + 1, elephant_foot_relief + 1]
    ]);
}

// Local 45-degree cutter swept along one diagonal arm-tip junction.
// A, U, V and direction describe the local coordinate system.
module elephant_foot_edge_cut(A, U, V, direction, length) {
    multmatrix([
        [U[0], V[0], direction[0], A[0]],
        [U[1], V[1], direction[1], A[1]],
        [U[2], V[2], direction[2], A[2]],
        [0, 0, 0, 1]
    ])
        linear_extrude(height = length)
            polygon([
                [-elephant_foot_relief - 1, -1],
                [1, -1],
                [1, elephant_foot_relief + 1]
            ]);
}

// Complete set of small removal volumes for print-facing edge relief.
module elephant_foot_relief_cuts() {
    s2 = sqrt(2) / 2;

    if (elephant_foot_relief > 0)
        for (mirror_side = [0, 1])
            mirror([0, mirror_side, 0]) {
                // Where print relief meets the diagonal outer side chamfer.
                if (side_edge_chamfer > 0) {
                    elephant_foot_edge_cut(
                        [horizontal_arm_length - side_edge_chamfer - s2,
                         bracket_width / 2 + s2, 0],
                        [s2, s2, 0],
                        [0, 0, 1],
                        [s2, -s2, 0],
                        side_edge_chamfer * sqrt(2) + 2
                    );

                    elephant_foot_edge_cut(
                        [0,
                         bracket_width / 2 - side_edge_chamfer - s2,
                         -vertical_arm_length - s2],
                        [0, s2, -s2],
                        [-1, 0, 0],
                        [0, s2, s2],
                        side_edge_chamfer * sqrt(2) + 2
                    );
                }

                // Straight plywood-facing edge of the horizontal arm.
                translate([inside_corner_radius, 0, 0])
                    rotate([90, 0, 90])
                        linear_extrude(
                            height = horizontal_arm_length + 1 - inside_corner_radius
                        )
                            elephant_foot_wedge_profile_2d();

                // Straight plywood-facing edge of the vertical arm.
                translate([0, 0, -vertical_arm_length - 1])
                    rotate([0, 0, 90])
                        linear_extrude(
                            height = vertical_arm_length + 1 - inside_corner_radius
                        )
                            elephant_foot_wedge_profile_2d();

                // Rounded plywood-facing inside corner.
                if (inside_corner_radius >= 1)
                    translate([
                        inside_corner_radius,
                        0,
                        -inside_corner_radius
                    ])
                        rotate([90, 0, 0])
                            rotate([0, 0, 89])
                                rotate_extrude(angle = 92)
                                    polygon([
                                        [
                                            inside_corner_radius - 1,
                                            bracket_width / 2
                                                - elephant_foot_relief - 1
                                        ],
                                        [
                                            inside_corner_radius - 1,
                                            bracket_width / 2 + 1
                                        ],
                                        [
                                            inside_corner_radius
                                                + elephant_foot_relief + 1,
                                            bracket_width / 2 + 1
                                        ]
                                    ]);
            }
}

module print_compensated_body() {
    difference() {
        outer_side_chamfered_body();
        elephant_foot_relief_cuts();
    }
}

// ---------- Captive-nut pocket with window on wood-facing side ----------
// The nut pocket lies behind retaining_wall_thickness. A free slot connects the pocket
// to the access window. Slide the nut through the window towards the corner,
// then hook the plug tab into the slot.

// Top arm: bolt along Z.
module top_fastener_cut() {
    z0 = retaining_wall_thickness;
    if (nut_type == "hex") {
        translate([top_bolt_x, 0, z0]) cylinder(d = nut_pocket_length, h = nut_pocket_depth, $fn = 6);
        translate([top_bolt_x, -nut_pocket_width / 2, z0]) cube([nut_pocket_length / 2 + nut_to_window_slot_length + 0.02, nut_pocket_width, nut_pocket_depth]);
    } else
        translate([top_bolt_x - nut_pocket_length / 2, -nut_pocket_width / 2, z0]) cube([nut_pocket_length + nut_to_window_slot_length + 0.02, nut_pocket_width, nut_pocket_depth]);
    // Window opening from the wood-facing surface.
    translate([top_window_start_x - 0.01, -nut_pocket_width / 2, -0.01]) cube([window_length + 0.01, nut_pocket_width, window_depth + 0.01]);
    // Bolt hole through retaining wall plus blind clearance behind nut.
    translate([top_bolt_x, 0, -1]) cylinder(d = bolt_diameter + bolt_clearance, h = retaining_wall_thickness + 2);
    translate([top_bolt_x, 0, z0 + nut_pocket_depth - 0.01]) cylinder(d = bolt_diameter + bolt_clearance, h = blind_bolt_clearance_depth + 0.01);
}

// Vertical arm: bolt along X.
module vertical_fastener_cut() {
    x0 = -window_depth;
    if (nut_type == "hex") {
        translate([x0, 0, vertical_bolt_z]) rotate([0, 90, 0]) cylinder(d = nut_pocket_length, h = nut_pocket_depth, $fn = 6);
        translate([x0, -nut_pocket_width / 2, vertical_window_start_z - 0.02]) cube([nut_pocket_depth, nut_pocket_width, nut_pocket_length / 2 + nut_to_window_slot_length + 0.02]);
    } else
        translate([x0, -nut_pocket_width / 2, vertical_window_start_z - 0.02]) cube([nut_pocket_depth, nut_pocket_width, nut_pocket_length + nut_to_window_slot_length + 0.02]);
    // Window opening from the wood-facing surface.
    translate([x0, -nut_pocket_width / 2, vertical_window_start_z - window_length]) cube([window_depth + 0.01, nut_pocket_width, window_length + 0.01]);
    // Bolt hole through retaining wall plus blind clearance behind nut.
    translate([1, 0, vertical_bolt_z]) rotate([0, -90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = retaining_wall_thickness + 2);
    translate([x0 + 0.01, 0, vertical_bolt_z]) rotate([0, -90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = blind_bolt_clearance_depth + 0.01);
}

module bracket() {
    difference() {
        print_compensated_body();
        top_fastener_cut();
        vertical_fastener_cut();
    }
}

// ---------- Access-window plug ----------
// Window-local coordinates: u runs along the arm towards its end (0=start),
// v is transverse (Y), and w is depth from the wood-facing surface.
// The tab at u<0 engages the slot under the retaining wall.
// Insert the tab at an angle, then press the far end flush with the wood face.
module plug_local() {
    pc = plug_clearance;
    pw = nut_pocket_width - 2 * pc;
    difference() {
        rotate([90, 0, 0]) linear_extrude(height = pw, center = true)
            polygon([
                [pc, 0], [window_length - pc, 0],
                [window_length - pc, window_depth - pc - plug_end_chamfer], [window_length - pc - plug_end_chamfer, window_depth - pc],   // insertion bevel
                [-plug_tab_length, window_depth - pc],                                           // bottom face and tab
                [-plug_tab_length, window_depth - pc - plug_tab_thickness], [pc, window_depth - pc - plug_tab_thickness]
            ]);
        // Extraction hole (pin/small screw) or screwdriver slot.
        if (plug_handle == "hole") translate([window_length / 2, 0, -1]) cylinder(d = 2.5, h = 5, $fn = 24);
        if (plug_handle == "slot") translate([window_length - pc - 3, -pw / 2 - 1, -1]) cube([1.2, pw + 2, 3]);
    }
}

// Lay plugs on their sides for printing; layer lines run through each tab.
module plug_print() {
    translate([plug_tab_length, window_depth, (nut_pocket_width - 2 * plug_clearance) / 2]) rotate([90, 0, 0]) plug_local();
}

// Two separate plugs positioned for printing and documentation exports.
module plugs_print_pair() {
    for (i = [0, 1])
        translate([i * (window_length + plug_tab_length + 4), 0, 0])
            plug_print();
}

// Show installed plugs in the access windows for visual inspection only.
module plugs_in_place() {
    translate([top_window_start_x, 0, 0]) plug_local();
    multmatrix([[0, 0, -1, 0], [0, -1, 0, 0], [-1, 0, 0, vertical_window_start_z], [0, 0, 0, 1]]) plug_local();
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
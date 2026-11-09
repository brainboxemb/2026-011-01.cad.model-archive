//! # Corner bracket — v0.1
//!
//! Outside-corner bracket for two 10 mm plywood panels. The original
//! parametric design is in [corner_bracket.scad](scad/corner_bracket.scad).
//! It has two captive-nut pockets accessible from the wood-facing surfaces
//! and two removable plugs that conceal the access windows after assembly.
//!
//! **This is a work in progress.** Test-fit the M4 fasteners, nuts, printed
//! clearances, plywood corner relief and printed-part strength before use.
//! All dimensions below are millimetres.
//!
//! ## Design walkthrough
//!
//! The six pictures show how the bracket is built, from a flat drawing to the finished part. Each step first explains **what happens and why**, then shows the corresponding OpenSCAD code. You do not need to understand every line at once. The complete model is in [corner_bracket.scad](scad/corner_bracket.scad); you can explore the steps in [design.scad](design/design.scad). All dimensions are in millimetres.
//!
//! ### 1. Draw the L profile and round its inside corner in 2D
//!
//! For a visual explanation of the **arm-end and outside corner chamfers**
//! (`arm_end_chamfer` and `outer_corner_chamfer`), see the [Chamfer Guide](docs/chamfer-guide.html).
//!
//! **Start with a simple L shape.** `polygon()` connects the vertices
//! around the bracket's outline. The two arm-end bevels and the outside
//! corner chamfer are included directly. The inner corner is initially
//! sharp at `(0, 0)`.
//!
//! **Add a small rounded piece using ordinary 2D shapes.** Place a
//! `inside_corner_radius × inside_corner_radius` square just inside the sharp corner. Subtract a
//! `circle(r = inside_corner_radius)` whose centre is at `(inside_corner_radius, -inside_corner_radius)`.
//! The remaining piece curves into the corner. `union()` joins it
//! to the L without affecting the opposite edges.
//!
//! **Then give the finished 2D outline thickness.** `linear_extrude()`
//! produces the 20 mm wide bracket (`bracket_width`), and `rotate()` orients it.
//! The `$fn = 72` setting on this circle gives 5-degree steps, matching
//! the old 19-point inside radius. `inside_corner_radius = 0` leaves a sharp corner.
//!
//! ![L-shaped polygon profile](design/01_profile.png)
//!
//! **Relevant OpenSCAD code:**
//!
//!     module inside_corner_fill_2d(r) {
//!         difference() {
//!             translate([0, -r]) square([r, r]);
//!             translate([r, -r]) circle(r = r, $fn = 72);
//!         }
//!     }
//!
//!     tip_top  = (elephant_foot_relief > 0) ? [[horizontal_arm_length - elephant_foot_relief, 0], [horizontal_arm_length, elephant_foot_relief]] : [[horizontal_arm_length, 0]];
//!     tip_vert = (elephant_foot_relief > 0) ? [[-elephant_foot_relief, -vertical_arm_length], [0, -vertical_arm_length + elephant_foot_relief]] : [[0, -vertical_arm_length]];
//!
//!     module base_profile_2d() {
//!         polygon(concat(tip_top, [
//!             [horizontal_arm_length, wall_thickness - arm_end_chamfer],           // top-arm end
//!             [horizontal_arm_length - arm_end_chamfer, wall_thickness],
//!             [-wall_thickness + outer_corner_chamfer, wall_thickness],
//!             [-wall_thickness, wall_thickness - outer_corner_chamfer],            // outside corner
//!             [-wall_thickness, -vertical_arm_length + arm_end_chamfer],
//!             [-wall_thickness + arm_end_chamfer, -vertical_arm_length]          // vertical-arm end
//!         ], tip_vert, [[0, 0]]));
//!     }
//!
//!     module bracket_profile_2d() {
//!         union() {
//!             base_profile_2d();
//!             if (inside_corner_radius > 0) inside_corner_fill_2d(inside_corner_radius);
//!         }
//!     }
//!
//!     module profile_body() {
//!         rotate([90, 0, 0])
//!             linear_extrude(height = bracket_width, center = true)
//!                 bracket_profile_2d();
//!     }
//!
//! ### 2. Outer side-edge chamfers
//!
//! **New to `hull()`?** Read the [illustrated Hull Guide](docs/hull-guide.html)
//! for the underlying operation, then the [Chamfer Guide](docs/chamfer-guide.html)
//! for **nine pictures of this actual model**: the polygon bevels, both hull
//! inputs, their convex envelope, clipping to the L and the print relief.
//!
//! The sharp *side* edges get a bevel. The code first creates two versions
//! of the outside outline: one narrower in width and one with a smaller
//! perimeter. `hull()` connects them with sloping surfaces.
//! `intersection()` then trims the original L profile to that shape.
//! The two pieces still meet the plywood on flat faces. The parameter
//! `side_edge_chamfer = 2` controls this bevel; `arm_end_chamfer` and `outer_corner_chamfer` belong to the 2D
//! polygon from Step 1.
//!
//! ![Outer side-edge chamfers](design/02_edge_chamfers.png)
//!
//! **Relevant OpenSCAD code:**
//!
//!     module outer_chamfer_envelope_2d() {
//!         polygon([
//!             [horizontal_arm_length, -vertical_arm_length], [horizontal_arm_length, wall_thickness - arm_end_chamfer], [horizontal_arm_length - arm_end_chamfer, wall_thickness], [-wall_thickness + outer_corner_chamfer, wall_thickness],
//!             [-wall_thickness, wall_thickness - outer_corner_chamfer], [-wall_thickness, -vertical_arm_length + arm_end_chamfer], [-wall_thickness + arm_end_chamfer, -vertical_arm_length]
//!         ]);
//!     }
//!     
//!     module outer_side_chamfer_keep_envelope() {
//!         rotate([90, 0, 0]) hull() {
//!             linear_extrude(height = bracket_width - 2 * side_edge_chamfer, center = true) outer_chamfer_envelope_2d();
//!             linear_extrude(height = bracket_width, center = true) offset(delta = -side_edge_chamfer) outer_chamfer_envelope_2d();
//!         }
//!     }
//!     
//!     module outer_side_chamfered_body() {
//!         intersection() {
//!             rotate([90, 0, 0]) linear_extrude(height = bracket_width, center = true) bracket_profile_2d();
//!             if (side_edge_chamfer > 0) outer_side_chamfer_keep_envelope();
//!             else rotate([90, 0, 0]) linear_extrude(height = bracket_width, center = true) outer_chamfer_envelope_2d();
//!         }
//!     }
//!
//! ### 3. Captive nuts and access windows
//!
//! **Now make room for the bolts and nuts.** OpenSCAD can treat ordinary shapes as cutting tools. Put a cylinder or box where you want a hole, then use `difference()` to subtract it from the bracket.
//!
//! For each arm, the code makes four spaces: a hexagonal pocket for an M4 nut, a short slot to slide the nut into position, an opening on the wood-facing side to insert the nut, and the bolt hole. `cylinder($fn = 6)` is a cylinder with **six flat sides**, so it matches a hex nut; `cube()` cuts rectangular slots and openings. The two arms use the same idea but in different directions (`top_fastener_cut()` and `vertical_fastener_cut()`). The bolt's extra clearance is a **blind hole**, so it does not break through the outside wall.
//!
//! ![Captive nuts and access windows](design/03_nut_pockets.png)
//!
//! **Relevant OpenSCAD code:**
//!
//!     nut_pocket_width       = nut_across_flats + nut_clearance;   // nut pocket width (across flats)
//!     nut_pocket_length       = (nut_type == "hex") ? nut_pocket_width / cos(30) : nut_pocket_width;   // pocket length (hex vertex-to-vertex)
//!     nut_pocket_depth = nut_thickness + 0.4;           // nut-pocket depth
//!     outside_skin     = wall_thickness - retaining_wall_thickness - nut_pocket_depth - blind_bolt_clearance_depth;   // closed outside wall
//!     window_depth        = retaining_wall_thickness + nut_pocket_depth;  // window depth from wood-facing surface
//!     window_length       = nut_pocket_length + window_extra_length;        // window length
//!     top_bolt_x = plywood_thickness + bolt_offset;           // top-arm bolt X position
//!     vertical_bolt_z = -(plywood_thickness + bolt_offset);        // vertical-arm bolt Z position
//!     top_window_start_x = top_bolt_x + nut_pocket_length / 2 + nut_to_window_slot_length;    // top-arm window start
//!     vertical_window_start_z = vertical_bolt_z - nut_pocket_length / 2 - nut_to_window_slot_length;    // vertical-arm window start
//!     
//!     module top_fastener_cut() {
//!         z0 = retaining_wall_thickness;
//!         if (nut_type == "hex") {
//!             translate([top_bolt_x, 0, z0]) cylinder(d = nut_pocket_length, h = nut_pocket_depth, $fn = 6);
//!             translate([top_bolt_x, -nut_pocket_width / 2, z0]) cube([nut_pocket_length / 2 + nut_to_window_slot_length + 0.02, nut_pocket_width, nut_pocket_depth]);
//!         } else
//!             translate([top_bolt_x - nut_pocket_length / 2, -nut_pocket_width / 2, z0]) cube([nut_pocket_length + nut_to_window_slot_length + 0.02, nut_pocket_width, nut_pocket_depth]);
//!         // Window opening from the wood-facing surface.
//!         translate([top_window_start_x - 0.01, -nut_pocket_width / 2, -0.01]) cube([window_length + 0.01, nut_pocket_width, window_depth + 0.01]);
//!         // Bolt hole through retaining wall plus blind clearance behind nut.
//!         translate([top_bolt_x, 0, -1]) cylinder(d = bolt_diameter + bolt_clearance, h = retaining_wall_thickness + 2);
//!         translate([top_bolt_x, 0, z0 + nut_pocket_depth - 0.01]) cylinder(d = bolt_diameter + bolt_clearance, h = blind_bolt_clearance_depth + 0.01);
//!     }
//!     
//!     module vertical_fastener_cut() {
//!         x0 = -window_depth;
//!         if (nut_type == "hex") {
//!             translate([x0, 0, vertical_bolt_z]) rotate([0, 90, 0]) cylinder(d = nut_pocket_length, h = nut_pocket_depth, $fn = 6);
//!             translate([x0, -nut_pocket_width / 2, vertical_window_start_z - 0.02]) cube([nut_pocket_depth, nut_pocket_width, nut_pocket_length / 2 + nut_to_window_slot_length + 0.02]);
//!         } else
//!             translate([x0, -nut_pocket_width / 2, vertical_window_start_z - 0.02]) cube([nut_pocket_depth, nut_pocket_width, nut_pocket_length + nut_to_window_slot_length + 0.02]);
//!         // Window opening from the wood-facing surface.
//!         translate([x0, -nut_pocket_width / 2, vertical_window_start_z - window_length]) cube([window_depth + 0.01, nut_pocket_width, window_length + 0.01]);
//!         // Bolt hole through retaining wall plus blind clearance behind nut.
//!         translate([1, 0, vertical_bolt_z]) rotate([0, -90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = retaining_wall_thickness + 2);
//!         translate([x0 + 0.01, 0, vertical_bolt_z]) rotate([0, -90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = blind_bolt_clearance_depth + 0.01);
//!     }
//!     
//!     difference() {
//!         outer_side_chamfered_body();
//!         top_fastener_cut();
//!         vertical_fastener_cut();
//!     }
//!
//! ### 4. Elephant-foot relief
//!
//! The [Chamfer Guide](docs/chamfer-guide.html) compares the side-edge
//! bevel and the elephant-foot relief visually, before and after each cut.
//!
//! **What is elephant foot?** The very first printed layers sometimes
//! spread sideways where they touch the print bed. A nominally square edge
//! can become slightly wider at the base. The bracket is printed on one
//! of its flat **side faces**, so this bulge can interfere with the surfaces
//! where the bracket should fit against the plywood.
//!
//! The solution is not to change the entire bracket. We remove a very
//! small **45-degree triangle** at the edges near the print bed. The
//! parameter `elephant_foot_relief = 0.6` mm sets the nominal size of this relief;
//! the illustration deliberately exaggerates it so you can see the cut.
//!
//! ![First layer bulge versus an intentional triangular relief](figures/elephant-foot-section.svg)
//!
//! **Where are these triangles removed?** The bracket has three kinds of
//! wood-facing edges: a straight edge along the horizontal arm, a straight
//! edge along the vertical arm, and the rounded inside corner. Relief is
//! applied at **both printed side faces** (`Y = +bracket_width/2` and `Y = -bracket_width/2`).
//!
//! ![Wood-facing relief edge locations on the bracket](figures/elephant-foot-edges.svg)
//!
//! **We now use the same hull principle as for the outer side bevels.**
//! The opening between the arms is a convex 2D helper shape, with a
//! quarter-circle boundary at the rounded inside corner. We create
//! one normal copy at `Y = ±(bracket_width/2 - elephant_foot_relief)` and one copy expanded by
//! `elephant_foot_relief` at `Y = ±bracket_width/2`. A `hull()` connects these two outlines.
//!
//! Two **separate hulls**, one for each printed side, are necessary:
//! joining the two expanded outside slices in a *single* global hull
//! would remove material through the entire middle of the bracket.
//! With two local hulls, only the outer 0.6 mm on each side is affected.
//! At the arm ends, where this relief meets the diagonal `side_edge_chamfer` bevel,
//! small additional `relief_corner_miters()` hulls finish the join.
//! `difference()` then subtracts the resulting cutting volumes from
//! `outer_side_chamfered_body()`. This naturally follows the straight plywood faces AND the
//! rounded inner corner, replacing the former individual wedge cutters.
//!
//! Setting `elephant_foot_relief = 0` disables this relief. `side_edge_chamfer` still controls the
//! larger outside chamfers in Step 2. The small 2D chamfers at the arm
//! tips are part of Step 1, as before. The geometric regression tests
//! compare the complete bracket against the former cutting method.
//! The small differences are concentrated near relief intersections;
//! actual print fit must still be checked.
//!
//! The following render shows the resulting bracket. The complete
//! cutter modules used in the source code are listed underneath.

//!
//! ![Elephant-foot relief](design/04_print_relief.png)
//!
//! **Relevant OpenSCAD code (shortened):**
//!
//!     module inside_opening_2d() {
//!         reach = max(5, side_edge_chamfer + elephant_foot_relief + 1);
//!         difference() {
//!             translate([0, -vertical_arm_length - reach])
//!                 square([horizontal_arm_length + reach, vertical_arm_length + reach]);
//!             if (inside_corner_radius > 0) inside_corner_fill_2d(inside_corner_radius);
//!         }
//!     }
//!
//!     module opening_layer(y, expansion = 0) {
//!         translate([0, y, 0]) rotate([90, 0, 0])
//!             linear_extrude(height = 0.002, center = true)
//!                 offset(delta = expansion) inside_opening_2d();
//!     }
//!
//!     module inside_relief_envelope() {
//!         if (elephant_foot_relief > 0)
//!             for (side = [-1, 1])
//!                 hull() {
//!                     opening_layer(side * (bracket_width / 2 - elephant_foot_relief));
//!                     opening_layer(side * bracket_width / 2, elephant_foot_relief);
//!                 }
//!     }
//!
//!     module print_compensated_body() {
//!         difference() {
//!             outer_side_chamfered_body(); // already has the outside hull chamfers
//!             if (elephant_foot_relief > 0) {
//!                 inside_relief_envelope();
//!                 relief_corner_miters();
//!             }
//!         }
//!     }
//!
//!     module bracket() {
//!         difference() {
//!             print_compensated_body();
//!             top_fastener_cut();
//!             vertical_fastener_cut();
//!         }
//!     }
//!
//! ### 5. Access-window plugs
//!
//! **The nut windows need covers.** Each plug starts as a small side-view drawing made with `polygon()`. The shape includes a hook that slips under the lip inside the bracket. `linear_extrude()` gives the plug its width; `plug_clearance` leaves a little space around it so it can fit.
//!
//! `difference()` can also cut a small hole or screwdriver slot to help remove the plug. `plug_print()` places one plug on its side for printing, and `plugs_print_pair()` puts **two separate plugs** next to each other in the STL.
//!
//! ![Access-window plugs](design/05_access_plugs.png)
//!
//! **Relevant OpenSCAD code:**
//!
//!     module plug_local() {
//!         pc = plug_clearance;
//!         pw = nut_pocket_width - 2 * pc;
//!         difference() {
//!             rotate([90, 0, 0]) linear_extrude(height = pw, center = true)
//!                 polygon([
//!                     [pc, 0], [window_length - pc, 0],
//!                     [window_length - pc, window_depth - pc - plug_end_chamfer], [window_length - pc - plug_end_chamfer, window_depth - pc],   // insertion bevel
//!                     [-plug_tab_length, window_depth - pc],                                           // bottom face and tab
//!                     [-plug_tab_length, window_depth - pc - plug_tab_thickness], [pc, window_depth - pc - plug_tab_thickness]
//!                 ]);
//!             // Extraction hole (pin/small screw) or screwdriver slot.
//!             if (plug_handle == "hole") translate([window_length / 2, 0, -1]) cylinder(d = 2.5, h = 5, $fn = 24);
//!             if (plug_handle == "slot") translate([window_length - pc - 3, -pw / 2 - 1, -1]) cube([1.2, pw + 2, 3]);
//!         }
//!     }
//!     
//!     module plug_print() {
//!         translate([plug_tab_length, window_depth, (nut_pocket_width - 2 * plug_clearance) / 2]) rotate([90, 0, 0]) plug_local();
//!     }
//!     
//!     module plugs_print_pair() {
//!         for (i = [0, 1])
//!             translate([i * (window_length + plug_tab_length + 4), 0, 0])
//!                 plug_print();
//!     }
//!
//! ### 6. Installed preview
//!
//! **Finally, check how everything fits together.** `plugs_in_place()` moves and turns the two plugs into their windows. `wood()` draws the two plywood panels at a right angle, including bolt holes and the rounded corner.
//!
//! The plywood is only there to help you see the fit: the `%` before `wood()` tells OpenSCAD to show it as a transparent background shape. **It is not included in the printed bracket STL.**
//!
//! ![Installed preview](design/06_installed.png)
//!
//! **Relevant OpenSCAD code:**
//!
//!     module plugs_in_place() {
//!         translate([top_window_start_x, 0, 0]) plug_local();
//!         multmatrix([[0, 0, -1, 0], [0, -1, 0, 0], [-1, 0, 0, vertical_window_start_z], [0, 0, 0, 1]]) plug_local();
//!     }
//!     
//!     module wood() {
//!         color("burlywood", 0.45) difference() {
//!             union() {
//!                 translate([0, -preview_panel_width / 2, -plywood_thickness]) cube([preview_panel_length, preview_panel_width, plywood_thickness]);
//!                 translate([0, -preview_panel_width / 2, -preview_panel_length]) cube([plywood_thickness, preview_panel_width, preview_panel_length - plywood_thickness]);
//!             }
//!             translate([top_bolt_x, 0, -plywood_thickness - 1]) cylinder(d = bolt_diameter + bolt_clearance, h = plywood_thickness + 2);
//!             translate([-1, 0, vertical_bolt_z]) rotate([0, 90, 0]) cylinder(d = bolt_diameter + bolt_clearance, h = plywood_thickness + 2);
//!             // Remove material at the inside corner to match the bracket radius.
//!             if (inside_corner_radius > 0) difference() {
//!                 translate([-1, -preview_panel_width / 2 - 1, -inside_corner_radius]) cube([inside_corner_radius + 1, preview_panel_width + 2, inside_corner_radius + 1]);
//!                 translate([inside_corner_radius, 0, -inside_corner_radius]) rotate([90, 0, 0]) cylinder(r = inside_corner_radius, h = preview_panel_width + 4, center = true);
//!             }
//!         }
//!     }
//!     
//!     // Selection from design.scad:
//!     else if (design_step == "06_installed") {
//!         color("SteelBlue") bracket();
//!         color("Orange") plugs_in_place();
//!         %wood();
//!     }
//!
//!
//! ***
//!
//! ## Further reading
//!
//! A separate [OpenSCAD hull() guide](docs/hull-guide.html) shows how that
//! operation creates sloping sides and rounded *outside* corners.
//! The [Polygon and rounded-corner guide](docs/polygon-guide.html) compares
//! the **2D square-minus-circle method now used in the bracket** with an
//! equivalent 3D cube-minus-cylinder approach and the former
//! point-based `polygon()` construction. Only the inside-corner
//! implementation changed; the intended shape, chamfers and other
//! bracket features were preserved.
//!
//! ## Alternative mounting arrangements
//!
//! The current model uses bolts from the **inside** of the plywood into
//! **captured nuts** in the outside bracket. There are other possibilities:
//! reverse the bolts, use accessible locking flange nuts, replace hex nuts
//! with thin square nuts, or add a second **inside counter-bracket**.
//!
//! The options, simple bolt-path diagrams, differences between nut types,
//! the supplied stainless-steel product references, and the bolt-length
//! constraints are compared in the separate
//! **[Mounting options and fastener comparison](docs/mounting-options.html)**.
//!
//! These are design alternatives. In v0.1, the **bolt-from-inside,
//! captive-nut** configuration is the only implemented bolt direction;
//! the other arrangements require new CAD and physical testing.
//!
//! ## Printing and assembly
//!
//! 1. Print one bracket and one pair of access plugs, with each part on
//!    its flat side as arranged by the original designer.
//! 2. Check M4 nut fit in both pockets; insert nuts through the windows
//!    and slide them to the bolt holes.
//! 3. Engage each plug tab under its retaining lip and press the far end down.
//! 4. Fit the bracket on the outside corner of the plywood joint and
//!    fasten from the inside through the plywood. Confirm bolt lengths
//!    against real parts; nominal M4x16 is only a starting assumption.
//!
//! The CAD files below are the definitive geometry. The automatically
//! generated bill of materials includes the **printed bracket and one
//! two-plug set**. Plywood, bolts and nuts are not modeled BOM items.

include <NopSCADlib/core.scad>;
use <corner_bracket.scad>;

module corner_bracket_stl()
    stl("corner_bracket")
        bracket();

module access_plugs_stl()
    stl("access_plugs")
        plugs_print_pair();

//! Printed bracket and the pair of access-window plugs displayed side by
//! side. See the final design step above for their actual installed position.
module main_assembly()
    assembly("main") {
        stl_colour("SteelBlue") corner_bracket_stl();
        translate([58, 0, 0])
            stl_colour("Orange") access_plugs_stl();
    }

main_assembly();

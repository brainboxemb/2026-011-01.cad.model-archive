// Educational / experimental view of the cs/ef junction on the REAL Corner Bracket.
//
// Goal:
//   Keep the existing two local elephant-foot hulls.
//   Change as little as possible.
//   Test whether only the OUTER ef input needs to be derived from the already
//   cs-chamfered body, just as the beam experiment demonstrated.
//
// This file does NOT replace ../scad/corner_bracket.scad.
// It visualizes the current construction and the minimal experiment side by side.
//
// OpenSCAD Customizer: choose junction_step.

/* [Illustration] */
junction_step = "00_cs_body"; // [00_cs_body, 01_current_inputs, 02_current_hull, 03_current_problem, 04_inner_cs_section, 05_outer_cs_section, 06_proposed_inputs, 07_proposed_hull, 08_proposed_result, 09_compare]

/* [Display] */
show_full_bracket = false;
positive_side_only = true;

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;

// Local copies of the production defaults used only for positioning/cropping.
// The actual production modules still come from corner_bracket.scad.
armH = 40;
armV = 40;
W = 20;
cs = 2;
ef = 0.6;

y_inner = W / 2 - ef;
y_outer = W / 2;

// Keep the explanatory close-up around the horizontal arm tip where the
// current flat termination is easiest to see.
module tip_crop() {
    translate([armH - cs - ef - 4, W / 2 - cs - ef - 4, -2])
        cube([cs + ef + 8, cs + ef + 8, ef + 6]);
}

module maybe_crop() {
    if (show_full_bracket)
        children();
    else
        intersection() {
            children();
            tip_crop();
        }
}

// -----------------------------------------------------------------------------
// 1. CURRENT PRODUCTION CONSTRUCTION
// -----------------------------------------------------------------------------

// Current input A: unexpanded opening one ef inward from the printed side.
module current_inner_input(side = 1, display = false) {
    opening_layer(
        side * (W / 2 - ef),
        0
    );
}

// Current input B: the same abstract inside opening, expanded by ef at the
// printed side. This input does NOT know about the diagonal cs bevel at the arm
// tip. That is the local mismatch we are investigating.
module current_outer_input(side = 1, display = false) {
    opening_layer(
        side * W / 2,
        ef
    );
}

module current_one_side_hull(side = 1) {
    hull() {
        current_inner_input(side);
        current_outer_input(side);
    }
}

module current_relief_hulls() {
    if (positive_side_only)
        current_one_side_hull(1);
    else
        inside_relief_envelope();
}

module current_pre_miter_body() {
    difference() {
        body();
        inside_relief_envelope();
    }
}

// -----------------------------------------------------------------------------
// 2. EXTRACT THE ACTUAL cs-CHAMFERED BODY SECTIONS
// -----------------------------------------------------------------------------

// projection(cut=true) cuts at its local Z=0.
//
// Move the desired production Y section to Y=0, rotate Y onto projection Z,
// then mirror the 2D vertical axis so the result is again ordinary X/Z.
module body_section_2d(y) {
    mirror([0, 1, 0])
        projection(cut = true)
            rotate([90, 0, 0])
                translate([0, -y, 0])
                    body();
}

// Large 2D domain used only to obtain the EMPTY space around the real body
// section. It is intentionally bigger than the arm tips.
module section_domain_2d() {
    translate([-12, -armV - 12])
        square([armH + 24, armV + 24]);
}

// Stay near the same inside/opening region used by the production ef hull.
// This prevents the section complement from becoming "all space outside the
// bracket"; we only want the local opening/contact-edge neighborhood.
module opening_neighborhood_2d() {
    offset(delta = cs + ef + 3)
        inside_opening_2d();
}

// Actual empty region next to the already-cs-chamfered body at a chosen Y.
// At y_outer this includes the diagonal side-bevel geometry at the arm tip.
module cs_aware_opening_2d(y) {
    intersection() {
        opening_neighborhood_2d();
        difference() {
            section_domain_2d();
            body_section_2d(y);
        }
    }
}

module show_section_as_plate(y, side = 1) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 0.25, center = true)
                body_section_2d(y);
}

// -----------------------------------------------------------------------------
// 3. MINIMAL EXPERIMENT
// -----------------------------------------------------------------------------
//
// Keep exactly the same local-hull idea and the same Y positions.
//
// Inner input:
//   derive the opening from the real cs body at y = W/2-ef.
//
// Outer input:
//   derive the opening from the real cs body at y = W/2 FIRST,
//   THEN expand that already-cs-aware opening by ef.
//
// This is the direct bracket analogue of the successful beam experiment:
// chamfer first, then form the ef transition from the chamfered geometry.

module proposed_opening_layer(y, expansion = 0) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = eps, center = true)
                offset(delta = expansion)
                    cs_aware_opening_2d(y);
}

module proposed_inner_input(side = 1) {
    proposed_opening_layer(
        side * (W / 2 - ef),
        0
    );
}

module proposed_outer_input(side = 1) {
    proposed_opening_layer(
        side * W / 2,
        ef
    );
}

module proposed_one_side_hull(side = 1) {
    hull() {
        proposed_inner_input(side);
        proposed_outer_input(side);
    }
}

module proposed_relief_hulls() {
    if (positive_side_only) {
        proposed_one_side_hull(1);
    } else {
        proposed_one_side_hull(1);
        proposed_one_side_hull(-1);
    }
}

module proposed_body() {
    difference() {
        body();
        // Production has one local hull on each printed side.
        proposed_one_side_hull(1);
        proposed_one_side_hull(-1);
    }
}

// -----------------------------------------------------------------------------
// 4. DISPLAY SCENES
// -----------------------------------------------------------------------------

if (junction_step == "00_cs_body") {
    color("SteelBlue")
        maybe_crop()
            body();
}

else if (junction_step == "01_current_inputs") {
    color("LightSlateGray", 0.13)
        maybe_crop()
            body();

    color("SteelBlue", 0.48)
        maybe_crop()
            current_inner_input(1);

    color("DarkOrange", 0.48)
        maybe_crop()
            current_outer_input(1);
}

else if (junction_step == "02_current_hull") {
    color("LightSlateGray", 0.13)
        maybe_crop()
            body();

    color("IndianRed", 0.58)
        maybe_crop()
            current_one_side_hull(1);
}

else if (junction_step == "03_current_problem") {
    color("SteelBlue")
        maybe_crop()
            current_pre_miter_body();
}

else if (junction_step == "04_inner_cs_section") {
    color("LightSlateGray", 0.12)
        maybe_crop()
            body();

    color("SteelBlue", 0.62)
        maybe_crop()
            show_section_as_plate(y_inner);
}

else if (junction_step == "05_outer_cs_section") {
    color("LightSlateGray", 0.12)
        maybe_crop()
            body();

    color("DarkOrange", 0.62)
        maybe_crop()
            show_section_as_plate(y_outer);
}

else if (junction_step == "06_proposed_inputs") {
    color("LightSlateGray", 0.13)
        maybe_crop()
            body();

    color("SteelBlue", 0.48)
        maybe_crop()
            proposed_inner_input(1);

    color("DarkOrange", 0.48)
        maybe_crop()
            proposed_outer_input(1);
}

else if (junction_step == "07_proposed_hull") {
    color("LightSlateGray", 0.13)
        maybe_crop()
            body();

    color("SeaGreen", 0.58)
        maybe_crop()
            proposed_one_side_hull(1);
}

else if (junction_step == "08_proposed_result") {
    color("SeaGreen")
        maybe_crop()
            proposed_body();
}

else {
    // Left: current construction without the extra production miter hull.
    translate([-10, 0, 0])
        color("SteelBlue")
            maybe_crop()
                current_pre_miter_body();

    // Right: same body, same two local hull locations, but cs-aware inputs.
    translate([10, 0, 0])
        color("SeaGreen")
            maybe_crop()
                proposed_body();
}

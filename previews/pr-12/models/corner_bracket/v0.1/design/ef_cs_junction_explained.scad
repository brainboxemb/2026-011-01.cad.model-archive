// Educational / experimental view of the cs/ef junction on the REAL L-shaped bracket.
//
// Keep the picture simple:
//   - the same L-shaped body stays in the same place in every scene;
//   - hull inputs are shown transparently ON that L;
//   - then the hull result;
//   - then the resulting L.
//
// The production model is not changed here.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_current_inputs, 02_current_hull, 03_current_result, 04_proposed_inputs, 05_proposed_hull, 06_proposed_result]

/* [Display] */
show_closeup = false;

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;

armH = 40;
armV = 40;
W = 20;
cs = 2;
ef = 0.6;

// Optional close-up, but the default view remains the complete L.
module tip_crop() {
    translate([armH - cs - ef - 4, W / 2 - cs - ef - 4, -2])
        cube([cs + ef + 8, cs + ef + 8, ef + 6]);
}

module view_part() {
    if (show_closeup)
        intersection() {
            children();
            tip_crop();
        }
    else
        children();
}

// -----------------------------------------------------------------------------
// CURRENT PRODUCTION EF HULL
// -----------------------------------------------------------------------------

module current_inner_input(side = 1) {
    opening_layer(
        side * (W / 2 - ef),
        0
    );
}

module current_outer_input(side = 1) {
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

module current_pre_miter_body() {
    difference() {
        body();
        inside_relief_envelope();
    }
}

// -----------------------------------------------------------------------------
// MINIMAL CS-AWARE EXPERIMENT
// -----------------------------------------------------------------------------
//
// The structure remains exactly the same:
//   one local hull per printed side.
//
// Only the two input profiles are derived from the already-cs-chamfered body.

// Take the real X/Z section of body() at a selected Y.
module body_section_2d(y) {
    mirror([0, 1, 0])
        projection(cut = true)
            rotate([90, 0, 0])
                translate([0, -y, 0])
                    body();
}

// Restrict the complement to the same inside/contact-edge neighborhood used by
// the existing elephant-foot construction.
module section_domain_2d() {
    translate([-12, -armV - 12])
        square([armH + 24, armV + 24]);
}

module opening_neighborhood_2d() {
    offset(delta = cs + ef + 3)
        inside_opening_2d();
}

module cs_aware_opening_2d(y) {
    intersection() {
        opening_neighborhood_2d();
        difference() {
            section_domain_2d();
            body_section_2d(y);
        }
    }
}

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

module proposed_body() {
    difference() {
        body();
        proposed_one_side_hull(1);
        proposed_one_side_hull(-1);
    }
}

// -----------------------------------------------------------------------------
// SCENES — ALWAYS THE SAME L IN THE SAME POSITION
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    color("SteelBlue")
        view_part()
            body();
}

else if (junction_step == "01_current_inputs") {
    color("SteelBlue", 0.18)
        view_part()
            body();

    color("DeepSkyBlue", 0.58)
        view_part()
            current_inner_input(1);

    color("DarkOrange", 0.58)
        view_part()
            current_outer_input(1);
}

else if (junction_step == "02_current_hull") {
    color("SteelBlue", 0.18)
        view_part()
            body();

    color("IndianRed", 0.58)
        view_part()
            current_one_side_hull(1);
}

else if (junction_step == "03_current_result") {
    color("SteelBlue")
        view_part()
            current_pre_miter_body();
}

else if (junction_step == "04_proposed_inputs") {
    color("SteelBlue", 0.18)
        view_part()
            body();

    color("DeepSkyBlue", 0.58)
        view_part()
            proposed_inner_input(1);

    color("DarkOrange", 0.58)
        view_part()
            proposed_outer_input(1);
}

else if (junction_step == "05_proposed_hull") {
    color("SteelBlue", 0.18)
        view_part()
            body();

    color("SeaGreen", 0.58)
        view_part()
            proposed_one_side_hull(1);
}

else {
    color("SeaGreen")
        view_part()
            proposed_body();
}

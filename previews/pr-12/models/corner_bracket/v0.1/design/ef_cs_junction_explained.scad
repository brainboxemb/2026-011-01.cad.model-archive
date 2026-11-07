// Corner Bracket: beam-style elephant-foot experiment on the real L.
//
// The L is shown in PRINT ORIENTATION: one printed side lies horizontally.
// This makes the construction directly comparable to the beam demo.
//
// Four scenes only:
//   0. L with cs
//   1. two transparent ef input shapes
//   2. hull result
//   3. final L result
//
// Important:
// The L is split internally into its horizontal and vertical arms so each arm
// gets its own local hull. Their union preserves the concave inside corner.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_ef_inputs, 02_ef_hull, 03_result]

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;
display_thickness = 0.35;

armH = 40;
armV = 40;
t = 10;
W = 20;
ef = 0.6;

// -----------------------------------------------------------------------------
// Actual cs-aware cross-section of body() at a chosen Y.
// Returned as ordinary X/Z 2D geometry.
// -----------------------------------------------------------------------------

module body_section_2d(y) {
    mirror([0, 1, 0])
        projection(cut = true)
            rotate([90, 0, 0])
                translate([0, -y, 0])
                    body();
}

// Two overlapping masks split the concave L into two convex-ish arm regions.
// This lets us hull each arm locally instead of globally hulling the whole L.
module horizontal_arm_mask_2d() {
    translate([-t - 2, -2])
        square([armH + t + 4, t + 4]);
}

module vertical_arm_mask_2d() {
    translate([-t - 2, -armV - 2])
        square([t + 4, armV + t + 4]);
}

module arm_section_2d(y, which = "horizontal", shrink = 0) {
    offset(delta = -shrink)
        intersection() {
            body_section_2d(y);

            if (which == "horizontal")
                horizontal_arm_mask_2d();
            else
                vertical_arm_mask_2d();
        }
}

// -----------------------------------------------------------------------------
// Two ef inputs.
//
// Inner input: actual cs body one ef inward from the printed face.
// Outer input: actual cs body AT the printed face, then inset by ef.
//
// These are the direct L equivalents of the two successful beam inputs.
// -----------------------------------------------------------------------------

module input_layer(y, which, shrink = 0, thickness = eps) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                arm_section_2d(y, which, shrink);
}

module inner_input(which, display = false) {
    input_layer(
        W / 2 - ef,
        which,
        0,
        display ? display_thickness : eps
    );
}

module outer_input(which, display = false) {
    input_layer(
        W / 2,
        which,
        ef,
        display ? display_thickness : eps
    );
}

module arm_ef_hull(which) {
    hull() {
        inner_input(which);
        outer_input(which);
    }
}

// The two local hulls together form one L-shaped transition without a global
// hull across the concave inside corner.
module l_ef_hulls() {
    union() {
        arm_ef_hull("horizontal");
        arm_ef_hull("vertical");
    }
}

// Keep the existing cs body and replace only the outer ef-deep printed-side
// layer by the new beam-style transition.
module result_body_one_side() {
    union() {
        // Everything inward of the transition remains the real body().
        intersection() {
            body();
            translate([-100, -100, -100])
                cube([200, 100 + W / 2 - ef, 200]);
        }

        // New local transition at the +Y printed side.
        l_ef_hulls();
    }
}

// -----------------------------------------------------------------------------
// Display in print orientation.
//
// rotate([-90,0,0]) maps +Y to downward Z. Translate by W/2 so the +Y printed
// face lands on Z=0, just like the bottom of the beam demo.
// -----------------------------------------------------------------------------

module print_orientation() {
    translate([0, 0, W / 2])
        rotate([-90, 0, 0])
            children();
}

if (junction_step == "00_l_with_cs") {
    print_orientation()
        color("SteelBlue")
            body();
}

else if (junction_step == "01_ef_inputs") {
    print_orientation() {
        color("SteelBlue", 0.12)
            body();

        // BLUE = inner cs-aware L input.
        color("DeepSkyBlue", 0.50) {
            inner_input("horizontal", true);
            inner_input("vertical", true);
        }

        // ORANGE = outer cs-aware L input, additionally inset by ef.
        color("DarkOrange", 0.50) {
            outer_input("horizontal", true);
            outer_input("vertical", true);
        }
    }
}

else if (junction_step == "02_ef_hull") {
    print_orientation() {
        color("SteelBlue", 0.12)
            body();

        color("SeaGreen", 0.58)
            l_ef_hulls();
    }
}

else {
    print_orientation()
        color("SeaGreen")
            result_body_one_side();
}

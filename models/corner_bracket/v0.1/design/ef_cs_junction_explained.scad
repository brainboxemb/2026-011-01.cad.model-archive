// Corner Bracket: beam-style elephant-foot experiment on a clean L.
//
// IMPORTANT:
// The production body() cannot be used as the "cs only" starting point because
// corner_bracket.scad already folds ef into tip_top/tip_vert before body().
//
// This demo therefore rebuilds ONLY the clean L profile + cs side chamfer,
// with NO elephant-foot geometry at the arm tips.
//
// Four scenes only:
//   0. clean L with cs only
//   1. two transparent ef input L-shapes
//   2. local hull result
//   3. resulting L
//
// The L is shown in print orientation.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_ef_inputs, 02_ef_hull, 03_result]

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;
display_thickness = 0.35;

// Same production defaults, copied here so the baseline is explicit.
armH = 40;
armV = 40;
t = 10;
W = 20;
ce = 6;
c = 3;
cs = 2;
ef = 0.6;
r_in = 2.0;

// -----------------------------------------------------------------------------
// 0. CLEAN BASELINE: L + cs, NO ef
// -----------------------------------------------------------------------------

// Same production side profile, except the two end/contact points are sharp:
// [armH,0] and [0,-armV]. No tip_top/tip_vert elephant-foot adjustment.
module clean_sharp_profile() {
    polygon([
        [armH, 0],
        [armH, t - c],
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],
        [-t, -armV + c],
        [-t + c, -armV],
        [0, -armV],
        [0, 0]
    ]);
}

module clean_profile() {
    union() {
        clean_sharp_profile();

        if (r_in > 0)
            inside_corner_2d(r_in);
    }
}

// Same convex helper used for cs. It contains no ef.
module clean_outer_shape() {
    polygon([
        [armH, -armV],
        [armH, t - c],
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],
        [-t, -armV + c],
        [-t + c, -armV]
    ]);
}

module clean_cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = W - 2 * cs, center = true)
                clean_outer_shape();

            linear_extrude(height = W, center = true)
                offset(delta = -cs)
                    clean_outer_shape();
        }
}

module clean_body() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                clean_profile();

        clean_cs_envelope();
    }
}

// -----------------------------------------------------------------------------
// Actual cs-aware X/Z section from the CLEAN body at a chosen Y.
// -----------------------------------------------------------------------------

module clean_body_section_2d(y) {
    mirror([0, 1, 0])
        projection(cut = true)
            rotate([90, 0, 0])
                translate([0, -y, 0])
                    clean_body();
}

// Split the concave L into its two arms only for the local hull operation.
// Visually the two parts are still shown together as one L.
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
            clean_body_section_2d(y);

            if (which == "horizontal")
                horizontal_arm_mask_2d();
            else
                vertical_arm_mask_2d();
        }
}

// -----------------------------------------------------------------------------
// 1. TWO EF INPUTS — BOTH START FROM THE ALREADY-cs CLEAN L
// -----------------------------------------------------------------------------

module input_layer(y, which, shrink = 0, thickness = eps) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                arm_section_2d(y, which, shrink);
}

// Inner input: normal cs-aware L, one ef inward from the print face.
module inner_input(which, display = false) {
    input_layer(
        W / 2 - ef,
        which,
        0,
        display ? display_thickness : eps
    );
}

// Outer input: cs-aware L at the print face, made ef smaller.
// This is where the elephant-foot correction is introduced for the FIRST time.
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

module l_ef_hulls() {
    union() {
        arm_ef_hull("horizontal");
        arm_ef_hull("vertical");
    }
}

// Keep the clean cs body inward of the ef transition and replace only the
// outer +Y printed-side layer by the new local hulls.
module result_body_one_side() {
    union() {
        intersection() {
            clean_body();

            // Keep y <= W/2-ef.
            translate([-100, -100, -100])
                cube([200, 100 + W / 2 - ef, 200]);
        }

        l_ef_hulls();
    }
}

// -----------------------------------------------------------------------------
// Print orientation: +Y printed face becomes Z=0.
// -----------------------------------------------------------------------------

module print_orientation() {
    translate([0, 0, W / 2])
        rotate([-90, 0, 0])
            children();
}

// -----------------------------------------------------------------------------
// Four explanatory scenes
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    print_orientation()
        color("SteelBlue")
            clean_body();
}

else if (junction_step == "01_ef_inputs") {
    print_orientation() {
        color("SteelBlue", 0.12)
            clean_body();

        color("DeepSkyBlue", 0.50) {
            inner_input("horizontal", true);
            inner_input("vertical", true);
        }

        color("DarkOrange", 0.50) {
            outer_input("horizontal", true);
            outer_input("vertical", true);
        }
    }
}

else if (junction_step == "02_ef_hull") {
    print_orientation() {
        color("SteelBlue", 0.12)
            clean_body();

        color("SeaGreen", 0.58)
            l_ef_hulls();
    }
}

else {
    print_orientation()
        color("SeaGreen")
            result_body_one_side();
}

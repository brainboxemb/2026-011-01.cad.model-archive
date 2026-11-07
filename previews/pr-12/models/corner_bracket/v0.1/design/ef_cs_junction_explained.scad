// Corner Bracket: the SAME elephant-foot construction as the beam.
//
// Clean baseline:
//   - real L geometry;
//   - normal c / ce / cs chamfers;
//   - NO ef at the arm tips yet.
//
// Then exactly like the beam:
//   INPUT 1 = one thin L-shaped bottom plate at the print bed,
//             already carrying cs and inset by ef;
//   INPUT 2 = the complete already-cs-chamfered L volume from ef height upward.
//
// The complete concave L cannot be put through one global hull(), because that
// would fill its inside corner. Internally only, the horizontal and vertical
// arms are hulled separately and then united. The displayed inputs themselves
// remain one bottom L plate and one upper L volume.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_ef_inputs, 02_ef_hull, 03_result]

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;
display_thickness = 0.35;
display_explode = 3;

// Same production defaults, explicit so the clean baseline is unambiguous.
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

// Actual X/Z cross-section of the already-cs-chamfered clean L.
module clean_body_section_2d(y) {
    mirror([0, 1, 0])
        projection(cut = true)
            rotate([90, 0, 0])
                translate([0, -y, 0])
                    clean_body();
}

// -----------------------------------------------------------------------------
// 1. THE TWO EF INPUTS — now literally the same pattern as the beam
// -----------------------------------------------------------------------------

// INPUT 1: thin L-shaped BOTTOM PLATE.
//
// First take the real cs-aware footprint at the printed face. Only after that
// make the complete L footprint ef smaller.
module lower_plate_2d() {
    offset(delta = -ef)
        clean_body_section_2d(W / 2);
}

module lower_plate(thickness = eps) {
    translate([0, W / 2, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                lower_plate_2d();
}

// INPUT 2: the complete already-cs-chamfered L from ef above the print bed
// inward through the rest of the part.
//
// In model coordinates the +Y face is the print bed, so "ef upward" means
// retain y <= W/2-ef.
module upper_l_volume() {
    intersection() {
        clean_body();

        translate([-100, -100, -100])
            cube([200, 100 + W / 2 - ef, 200]);
    }
}

// -----------------------------------------------------------------------------
// INTERNAL ONLY: split the concave L into two arms for hull().
// -----------------------------------------------------------------------------

module horizontal_arm_mask_2d() {
    translate([-t - 2, -2])
        square([armH + t + 4, t + 4]);
}

module vertical_arm_mask_2d() {
    translate([-t - 2, -armV - 2])
        square([t + 4, armV + t + 4]);
}

module arm_mask_2d(which) {
    if (which == "horizontal")
        horizontal_arm_mask_2d();
    else
        vertical_arm_mask_2d();
}

module arm_mask_3d(which) {
    rotate([90, 0, 0])
        linear_extrude(height = 2 * W, center = true)
            arm_mask_2d(which);
}

module lower_arm_plate(which) {
    intersection() {
        lower_plate();
        arm_mask_3d(which);
    }
}

module upper_arm_volume(which) {
    intersection() {
        upper_l_volume();
        arm_mask_3d(which);
    }
}

module arm_ef_hull(which) {
    hull() {
        lower_arm_plate(which);
        upper_arm_volume(which);
    }
}

module l_ef_hulls() {
    union() {
        arm_ef_hull("horizontal");
        arm_ef_hull("vertical");
    }
}

// The two hulls already contain their upper arm volumes. Union the untouched
// upper L as well to guarantee the original concave L and inside radius remain
// complete.
module result_body_one_side() {
    union() {
        upper_l_volume();
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
// Four scenes
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    print_orientation()
        color("SteelBlue")
            clean_body();
}

else if (junction_step == "01_ef_inputs") {
    // Exploded VIEW ONLY:
    // pull the two real hull inputs apart so the lower plate is unmistakable.
    // The actual hull geometry below still uses their true positions.
    print_orientation() {
        color("DeepSkyBlue", 0.78)
            translate([0, -display_explode, 0])
                lower_plate(display_thickness);

        color("DarkOrange", 0.24)
            translate([0, display_explode, 0])
                upper_l_volume();
    }
}

else if (junction_step == "02_ef_hull") {
    print_orientation()
        color("SeaGreen")
            l_ef_hulls();
}

else {
    print_orientation()
        color("SeaGreen")
            result_body_one_side();
}

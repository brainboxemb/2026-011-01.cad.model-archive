// Corner Bracket: EXACTLY the same ef construction order as the beam.
//
// 1. Build a clean L with c / ce / cs, but NO ef.
// 2. Put that complete 3D L in print orientation.
// 3. Take a thin slab at print-bed Z=0 and project it -> bottom footprint.
// 4. offset(-ef) that footprint -> lower plate.
// 5. Take the complete print-oriented L from Z=ef upward -> upper volume.
// 6. hull lower + upper locally per arm to preserve the concave inside corner.
//
// This avoids the earlier mistake of building a loose X/Z section and then
// rotating it afterward.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_lower_plate, 02_upper_volume, 03_ef_inputs, 04_ef_hull, 05_result]

/* [Hidden] */
use <../scad/corner_bracket.scad>

$fn = 48;
eps = 0.02;
display_thickness = 1.0;
display_explode = 4;

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
// Clean model-space L: normal chamfers, NO elephant-foot geometry.
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

// -----------------------------------------------------------------------------
// Put the COMPLETE 3D L in print coordinates first.
// +Y printed face becomes print-bed Z=0.
// -----------------------------------------------------------------------------

module print_body() {
    translate([0, 0, W / 2])
        rotate([-90, 0, 0])
            clean_body();
}

// -----------------------------------------------------------------------------
// Same bottom-footprint construction as the BEAM demo.
// -----------------------------------------------------------------------------

module bottom_footprint_2d() {
    projection()
        intersection() {
            print_body();

            // Tiny slab crossing the actual print bed.
            translate([-100, -100, -eps / 2])
                cube([200, 200, eps]);
        }
}

// Lower hull input: real print-bed footprint, already carrying cs,
// then inset by ef.
module lower_plate(thickness = eps) {
    linear_extrude(height = thickness)
        offset(delta = -ef)
            bottom_footprint_2d();
}

// Upper hull input: the complete already-cs-chamfered PRINT-ORIENTED L
// from ef above the bed upward.
module upper_l_volume() {
    intersection() {
        print_body();

        translate([-100, -100, ef])
            cube([200, 200, W + 20]);
    }
}

// -----------------------------------------------------------------------------
// Internal split only for hull(): preserve the concave inside L corner.
// In print coordinates the original X/Z profile is now the XY footprint.
// -----------------------------------------------------------------------------

module horizontal_arm_mask_2d() {
    translate([-t - 2, -2])
        square([armH + t + 4, t + 4]);
}

module vertical_arm_mask_2d() {
    translate([-t - 2, -armV - 2])
        square([t + 4, armV + t + 4]);
}

module arm_mask_3d(which) {
    linear_extrude(height = W + 20)
        if (which == "horizontal")
            horizontal_arm_mask_2d();
        else
            vertical_arm_mask_2d();
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

module result_body_one_side() {
    union() {
        upper_l_volume();
        l_ef_hulls();
    }
}

// -----------------------------------------------------------------------------
// Scenes
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    color("SteelBlue")
        print_body();
}

else if (junction_step == "01_lower_plate") {
    color("DeepSkyBlue")
        lower_plate(display_thickness);
}

else if (junction_step == "02_upper_volume") {
    color("DarkOrange")
        upper_l_volume();
}

else if (junction_step == "03_ef_inputs") {
    color("DeepSkyBlue")
        translate([0, 0, -display_explode])
            lower_plate(display_thickness);

    color("DarkOrange", 0.40)
        translate([0, 0, display_explode])
            upper_l_volume();
}

else if (junction_step == "04_ef_hull") {
    color("SeaGreen")
        l_ef_hulls();
}

else {
    color("SeaGreen")
        result_body_one_side();
}

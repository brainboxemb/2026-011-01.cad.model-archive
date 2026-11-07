// Corner Bracket: beam-style cs/ef experiment in the ORIGINAL bracket coordinates.
//
// The important correction in this version:
//
//   * the bracket is NOT rebuilt on an XY print bed;
//   * the real print-facing side is the L-shaped X/Z face at Y = +W/2;
//   * the blue ef input is therefore a complete thin L plate ON that side;
//   * the orange input is the already-cs-chamfered body starting ef inward.
//
// This is the direct equivalent of the beam:
//   beam   : bottom plate at Z=0        + upper cs body from Z=ef
//   bracket: side L plate at Y=+W/2     + upper cs body from Y=W/2-ef inward
//
// Only the final hull operation is split internally per arm so a global convex
// hull cannot close the concave inside corner.
//
// The production corner_bracket.scad is NOT changed by this experiment.

/* [Illustration] */
junction_step = "00_l_with_cs"; // [00_l_with_cs, 01_ef_inputs, 02_ef_hull, 03_result]

/* [Geometry] */
armH = 40;
armV = 40;
t = 10;
W = 20;
ce = 6;
c = 3;
cs = 2;
ef = 0.6;
r_in = 2.0;

/* [Hidden] */
$fn = 48;
$vpr = [75, 0, 180];
eps = 0.02;
display_thickness = 0.35;

// -----------------------------------------------------------------------------
// Clean L side profile: production geometry with c / ce / r_in, but NO ef.
// -----------------------------------------------------------------------------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r])
            square([r, r]);

        translate([r, -r])
            circle(r = r, $fn = 72);
    }
}

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

// Convex helper used only for the existing cs side chamfer.
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

// Same cs envelope construction as the production bracket.
module cs_envelope() {
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

        cs_envelope();
    }
}

// -----------------------------------------------------------------------------
// ef INPUT 1: complete L plate on the REAL print-facing side Y=+W/2.
// -----------------------------------------------------------------------------

// At the outer side face the cs envelope is exactly the -cs inset of the
// convex outer helper, intersected with the actual concave L profile.
module side_face_with_cs_2d() {
    intersection() {
        clean_profile();

        offset(delta = -cs)
            clean_outer_shape();
    }
}

// The elephant-foot plate is that complete cs-aware L face, then inset by ef.
module ef_side_plate_2d() {
    offset(delta = -ef)
        side_face_with_cs_2d();
}

module ef_input_side_plate(thickness = eps) {
    translate([0, W / 2, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                ef_side_plate_2d();
}

// -----------------------------------------------------------------------------
// ef INPUT 2: complete already-cs-chamfered body starting ef inward.
// -----------------------------------------------------------------------------

module ef_input_inner_body() {
    intersection() {
        clean_body();

        // Keep everything from the opposite side up to Y=W/2-ef.
        translate([-100, -100, -100])
            cube([
                200,
                100 + W / 2 - ef,
                200
            ]);
    }
}

// -----------------------------------------------------------------------------
// Local arm hulls.
//
// The visible inputs remain:
//   one complete blue L plate;
//   one complete orange cs body.
//
// Internally only, split the concave L into its two arms before hull().
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
    rotate([90, 0, 0])
        linear_extrude(height = 2 * W, center = true)
            if (which == "horizontal")
                horizontal_arm_mask_2d();
            else
                vertical_arm_mask_2d();
}

module side_plate_arm(which) {
    intersection() {
        ef_input_side_plate();
        arm_mask_3d(which);
    }
}

module inner_body_arm(which) {
    intersection() {
        ef_input_inner_body();
        arm_mask_3d(which);
    }
}

module arm_ef_hull(which) {
    hull() {
        side_plate_arm(which);
        inner_body_arm(which);
    }
}

module ef_hulls() {
    union() {
        arm_ef_hull("horizontal");
        arm_ef_hull("vertical");
    }
}

module result_body() {
    union() {
        ef_input_inner_body();
        ef_hulls();
    }
}

// -----------------------------------------------------------------------------
// Four scenes.
// The camera looks almost straight at the +Y L side, matching the face the
// user marked in red, while still showing a little part thickness.
// -----------------------------------------------------------------------------

if (junction_step == "00_l_with_cs") {
    color("SteelBlue")
        clean_body();
}

else if (junction_step == "01_ef_inputs") {
    // BLUE: the complete L-shaped plate on Y=+W/2.
    color("DeepSkyBlue", 0.85)
        ef_input_side_plate(display_thickness);

    // ORANGE: the complete cs body beginning ef inward behind that plate.
    color("DarkOrange", 0.30)
        ef_input_inner_body();
}

else if (junction_step == "02_ef_hull") {
    color("SeaGreen", 0.75)
        ef_hulls();
}

else {
    color("SeaGreen")
        result_body();
}

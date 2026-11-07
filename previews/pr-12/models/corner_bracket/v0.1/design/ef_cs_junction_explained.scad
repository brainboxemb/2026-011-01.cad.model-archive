// Corner Bracket: continuous L elephant-foot construction.
//
// Construction order:
//
//   1. Make ONE continuous L-shaped sheet along the complete inside:
//      horizontal -> inside radius -> vertical.
//   2. Shape that complete sheet with the EXISTING cs hull.
//      This adjusts the sheet at the side/end corners without splitting the L.
//   3. Use that cs-shaped L sheet as the basis for the complete elephant-foot.
//
// This file deliberately stops before the final ef hull until step 2 is
// visually accepted.

/* [Demo] */
scene = "00_cs_body"; // [00_cs_body, 01_raw_L_sheet, 02_cs_hull_inputs, 03_cs_shaped_L, 04_cs_shaped_L_with_body]

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
$fn = 72;
sheet_thickness = 0.35;

// -----------------------------------------------------------------------------
// Clean bracket geometry, NO ef.
// -----------------------------------------------------------------------------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

module profile_2d() {
    union() {
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

        if (r_in > 0)
            inside_corner_2d(r_in);
    }
}

module outer_shape_2d() {
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

module raw_body() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            profile_2d();
}

// -----------------------------------------------------------------------------
// The normal cs hull, exactly the same construction used by the bracket body.
// -----------------------------------------------------------------------------

module cs_input_inner() {
    rotate([90, 0, 0])
        linear_extrude(height = W - 2 * cs, center = true)
            outer_shape_2d();
}

module cs_input_outer() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            offset(delta = -cs)
                outer_shape_2d();
}

module cs_hull() {
    hull() {
        cs_input_inner();
        cs_input_outer();
    }
}

module cs_body() {
    intersection() {
        raw_body();
        cs_hull();
    }
}

// -----------------------------------------------------------------------------
// ONE continuous inside L sheet, including r_in.
// -----------------------------------------------------------------------------

module inside_opening_2d() {
    difference() {
        // Open quadrant ends exactly on X=0 and Z=0.
        translate([0, -armV - 5])
            square([armH + 5, armV + 5]);

        if (r_in > 0)
            inside_corner_2d(r_in);
    }
}

module inner_L_band_2d() {
    difference() {
        offset(delta = sheet_thickness)
            inside_opening_2d();

        inside_opening_2d();
    }
}

module clipped_inner_L_band_2d() {
    intersection() {
        inner_L_band_2d();

        translate([-sheet_thickness, -armV])
            square([armH + sheet_thickness, armV + sheet_thickness]);
    }
}

module raw_inner_L_sheet() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            clipped_inner_L_band_2d();
}

// Step 2:
// The complete continuous L sheet is shaped by the SAME cs hull as the body.
// This is the first hull operation relevant to the ef construction.
module cs_shaped_inner_L_sheet() {
    intersection() {
        raw_inner_L_sheet();
        cs_hull();
    }
}

// -----------------------------------------------------------------------------
// Scenes.
// -----------------------------------------------------------------------------

$vpr = [90, 0, 0];

if (scene == "00_cs_body") {
    color("SteelBlue")
        cs_body();
}

else if (scene == "01_raw_L_sheet") {
    color("DeepSkyBlue", 0.90)
        raw_inner_L_sheet();
}

else if (scene == "02_cs_hull_inputs") {
    // Show the continuous L sheet as the object being shaped.
    color("DeepSkyBlue", 0.75)
        raw_inner_L_sheet();

    // Show the two existing cs hull inputs transparently.
    color("SteelBlue", 0.18)
        cs_input_inner();

    color("DarkOrange", 0.18)
        cs_input_outer();
}

else if (scene == "03_cs_shaped_L") {
    // This is the important intermediate result:
    // one continuous rounded L, now with the cs corner geometry applied.
    color("DeepSkyBlue", 0.92)
        cs_shaped_inner_L_sheet();
}

else {
    color("DeepSkyBlue", 0.82)
        cs_shaped_inner_L_sheet();

    color("DarkOrange", 0.22)
        cs_body();
}

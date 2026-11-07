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
scene = "00_cs_body"; // [00_cs_body, 01_raw_L_sheet, 02_cs_hull_inputs, 03_cs_shaped_L, 04_ef_inputs, 05_ef_relief, 06_final_body]

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
// Elephant-foot step.
//
// Start from the already cs-shaped continuous L.
//
// The second ef input is made from the SAME continuous inside opening, expanded
// by ef.  That moves the complete contact boundary into the bracket while
// preserving the horizontal face, rounded corner and vertical face as one
// continuous profile.
//
// Both inputs are then limited by the existing cs hull, so the side/end corner
// treatment established in step 2 is retained.
// -----------------------------------------------------------------------------

module ef_expanded_L_band_2d() {
    difference() {
        offset(delta = sheet_thickness)
            offset(delta = ef)
                inside_opening_2d();

        offset(delta = ef)
            inside_opening_2d();
    }
}

module clipped_ef_expanded_L_band_2d() {
    intersection() {
        ef_expanded_L_band_2d();

        translate([-ef - sheet_thickness, -armV])
            square([
                armH + ef + sheet_thickness,
                armV + ef + sheet_thickness
            ]);
    }
}

module ef_expanded_L_sheet() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                clipped_ef_expanded_L_band_2d();

        cs_hull();
    }
}


// Beam equivalent of "upper body from ef upward":
// keep the COMPLETE already-cs-chamfered bracket, but remove everything within
// ef of the continuous inside L boundary.
module ef_inner_clearance() {
    rotate([90, 0, 0])
        linear_extrude(height = W + 2, center = true)
            offset(delta = ef)
                inside_opening_2d();
}

module ef_upper_body() {
    difference() {
        cs_body();
        ef_inner_clearance();
    }
}


// Beam-equivalent thin input:
// move the complete continuous inner boundary ef INTO the bracket material.
// This gives the hull a real size/position difference, just like the beam's
// offset(-ef) bottom footprint.
module ef_inset_L_band_2d() {
    difference() {
        offset(delta = ef + sheet_thickness)
            inside_opening_2d();

        offset(delta = ef)
            inside_opening_2d();
    }
}

module ef_inset_L_sheet() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                ef_inset_L_band_2d();

        cs_hull();
    }
}

// The raw hull between two complete concave L shapes is convex and would fill
// the open inside corner with a diagonal triangle.
//
// Keep one continuous L construction by restricting that raw hull to the
// corridor swept by the inside boundary from 0 .. ef.  This corridor includes
// the horizontal face, the complete rounded r_in corner and the vertical face.
module ef_corridor_2d() {
    intersection() {
        difference() {
            offset(delta = ef + sheet_thickness)
                inside_opening_2d();

            inside_opening_2d();
        }

        translate([-ef - sheet_thickness, -armV])
            square([
                armH + ef + sheet_thickness,
                armV + ef + sheet_thickness
            ]);
    }
}

module ef_corridor() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            ef_corridor_2d();
}

module ef_raw_hull() {
    hull() {
        ef_inset_L_sheet();
        ef_upper_body();
    }
}

// Final ef transition:
// raw hull, but only inside the continuous rounded-L corridor and the
// previously accepted cs envelope.
module ef_hull() {
    intersection() {
        ef_raw_hull();
        ef_corridor();
        cs_hull();
    }
}

// -----------------------------------------------------------------------------
// Apply the ef relief directly to the existing cs body.
// -----------------------------------------------------------------------------

module final_body() {
    difference() {
        cs_body();
        ef_hull();
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
    color("DeepSkyBlue", 0.75)
        raw_inner_L_sheet();

    color("SteelBlue", 0.18)
        cs_input_inner();

    color("DarkOrange", 0.18)
        cs_input_outer();
}

else if (scene == "03_cs_shaped_L") {
    color("DeepSkyBlue", 0.92)
        cs_shaped_inner_L_sheet();
}

else if (scene == "04_ef_inputs") {
    // Blue: continuous thin L shifted ef INTO the bracket material.
    color("DeepSkyBlue", 0.82)
        ef_inset_L_sheet();

    // Orange: complete already-cs-chamfered body beginning beyond the ef
    // transition zone.
    color("DarkOrange", 0.28)
        ef_upper_body();
}

else if (scene == "05_ef_relief") {
    color("SeaGreen", 0.90)
        ef_hull();

    color("DarkOrange", 0.15)
        cs_body();
}

else {
    color("SteelBlue")
        final_body();
}

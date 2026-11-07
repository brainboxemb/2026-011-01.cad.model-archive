// Corner Bracket: unified L-profile elephant-foot experiment.
//
// The ef input is ONE continuous L-shaped profile following the complete
// inside of the bracket:
//
//   horizontal inside face
//        -> rounded inside corner r_in
//        -> vertical inside face
//
// No horizontal/vertical split is shown in this explanation.

/* [Demo] */
scene = "00_cs_body"; // [00_cs_body, 01_inner_L_profile, 02_inner_L_sheet, 03_inner_L_with_body]

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

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = W - 2 * cs, center = true)
                outer_shape_2d();

            linear_extrude(height = W, center = true)
                offset(delta = -cs)
                    outer_shape_2d();
        }
}

module cs_body() {
    intersection() {
        raw_body();
        cs_envelope();
    }
}

// -----------------------------------------------------------------------------
// ONE continuous inner L profile, including the rounded inside corner.
//
// This is deliberately constructed as a thin 2D band along the complete
// wood-contact boundary. It is only an explanatory input shape for now.
// -----------------------------------------------------------------------------

module inner_path_opening_2d() {
    // The open quadrant ends EXACTLY on the two wood-contact faces:
    //   X = 0   for the vertical inside face
    //   Z = 0   for the horizontal inside face
    //
    // Extending beyond the arm tips is fine, but extending above Z=0 is not:
    // that would move the horizontal boundary away from the real bracket.
    difference() {
        translate([0, -armV - 5])
            square([armH + 5, armV + 5]);

        if (r_in > 0)
            inside_corner_2d(r_in);
    }
}

// Thin band following the full inside boundary:
// horizontal -> rounded corner -> vertical.
module inner_L_profile_2d() {
    difference() {
        offset(delta = sheet_thickness)
            inner_path_opening_2d();

        inner_path_opening_2d();
    }
}

// Clip the explanatory band to the real bracket extents.
module clipped_inner_L_profile_2d() {
    intersection() {
        inner_L_profile_2d();

        translate([-sheet_thickness, -armV])
            square([armH + sheet_thickness, armV + sheet_thickness]);
    }
}

// Extrude the one-piece L profile over the bracket width.
// In front view this reads as one bent sheet with the real rounded corner.
module inner_L_sheet() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            clipped_inner_L_profile_2d();
}

// -----------------------------------------------------------------------------
// Scenes.
// -----------------------------------------------------------------------------

$vpr = [90, 0, 0];

if (scene == "00_cs_body") {
    color("SteelBlue")
        cs_body();
}

else if (scene == "01_inner_L_profile") {
    color("DeepSkyBlue")
        clipped_inner_L_profile_2d();
}

else if (scene == "02_inner_L_sheet") {
    color("DeepSkyBlue", 0.88)
        inner_L_sheet();
}

else {
    color("DeepSkyBlue", 0.80)
        inner_L_sheet();

    color("DarkOrange", 0.24)
        cs_body();
}

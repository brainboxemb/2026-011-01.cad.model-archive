// Corner Bracket: same construction as the beam.
//
// FIRST put the bracket on its flat L-shaped print side.
// AFTER that, use exactly the beam coordinates:
//
//   X/Y = complete L footprint on the print bed
//   Z   = bracket width / print height
//
// So ef is again:
//   bottom L footprint at Z=0
//   +
//   already-cs-chamfered L from Z=ef upward
//
// No side-profile explanation is used after print_orientation().

/* [Illustration] */
junction_step = "00_print_orientation"; // [00_print_orientation, 01_bottom_L, 02_upper_L, 03_ef_inputs]

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
eps = 0.02;
display_thickness = 0.35;

// ---------- original bracket geometry: NO ef ----------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

module clean_profile() {
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
        if (r_in > 0) inside_corner_2d(r_in);
    }
}

module outer_shape() {
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

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = W - 2 * cs, center = true)
                outer_shape();
            linear_extrude(height = W, center = true)
                offset(delta = -cs)
                    outer_shape();
        }
}

module original_cs_body() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                clean_profile();
        cs_envelope();
    }
}

// ---------- PUT THE COMPLETE BRACKET ON ITS L-SHAPED SIDE ----------
//
// Original +Y side is at Y=+W/2.
// rotate([-90,0,0]) maps original +Y to new -Z.
// translate upward by W/2 makes that side exactly new Z=0.
//
// From this point onward the geometry has the SAME meaning as the beam:
// the full L is a horizontal XY footprint and width W runs upward in Z.

module print_body() {
    translate([0, 0, W/2])
        rotate([-90, 0, 0])
            original_cs_body();
}

// ---------- SAME ef inputs as beam ----------

module bottom_L_footprint_2d() {
    projection()
        intersection() {
            print_body();
            translate([-100, -100, -eps/2])
                cube([200, 200, eps]);
        }
}

module ef_input_bottom(thickness = eps) {
    linear_extrude(height = thickness)
        offset(delta = -ef)
            bottom_L_footprint_2d();
}

module ef_input_upper() {
    intersection() {
        print_body();
        translate([-100, -100, ef])
            cube([200, 200, W + 20]);
    }
}

// ---------- scenes ----------

$vpr = [55, 0, 35];

if (junction_step == "00_print_orientation") {
    // Complete bracket already lying on its flat L-shaped side.
    color("SteelBlue")
        print_body();
}

else if (junction_step == "01_bottom_L") {
    // This must be a complete horizontal L plate: the BOTTOM of the bracket.
    color("DeepSkyBlue")
        ef_input_bottom(display_thickness);
}

else if (junction_step == "02_upper_L") {
    // Complete cs-chamfered bracket, simply clipped below Z=ef.
    color("DarkOrange")
        ef_input_upper();
}

else {
    // Same two inputs as the beam, in their REAL positions.
    color("DeepSkyBlue", 0.70)
        ef_input_bottom(display_thickness);

    color("DarkOrange", 0.28)
        ef_input_upper();
}

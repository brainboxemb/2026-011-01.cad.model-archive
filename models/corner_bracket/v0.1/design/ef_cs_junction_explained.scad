// Corner Bracket: minimal cs/ef input experiment.
//
// STOP HERE until these two L-shaped input layers are visually correct.
//
// Original bracket coordinates:
//   X/Z = the L side profile
//   Y   = bracket width
//
// The print-facing L side is Y = +W/2.
// No XY "print bed" conversion is used.

/* [Illustration] */
junction_step = "00_cs_body"; // [00_cs_body, 01_outer_L, 02_inner_L, 03_both_Ls]

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

// ---------- clean L profile: c/ce/r_in, but NO ef ----------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
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

// ---------- normal cs body, same principle as production ----------

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

module clean_body() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = W, center = true)
                clean_profile();

        cs_envelope();
    }
}

// ---------- the TWO L layers we need to understand first ----------

// Actual cs-aware L shape on the OUTER print-facing side Y=+W/2.
// At that side the cs envelope uses offset(-cs).
module outer_side_L_2d() {
    intersection() {
        clean_profile();
        offset(delta = -cs)
            outer_shape();
    }
}

// The outer ef input: same complete L side, then ef smaller.
module outer_ef_L_2d() {
    offset(delta = -ef)
        outer_side_L_2d();
}

// The inner ef input at Y=W/2-ef.
// This is still a COMPLETE L profile. The cs inset is slightly smaller here
// than at the outer face because we are ef inward along the 45-degree cs ramp.
module inner_side_L_2d() {
    intersection() {
        clean_profile();
        offset(delta = -(cs - ef))
            outer_shape();
    }
}

// Thin X/Z layer at a chosen Y. This is deliberately a side layer, not a
// horizontal footprint.
module xz_layer(profile = "outer", y = W/2, thickness = eps) {
    translate([0, y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, center = true)
                if (profile == "outer")
                    outer_ef_L_2d();
                else
                    inner_side_L_2d();
}

// ---------- scenes ----------

// Camera: almost straight onto the +Y side, but with enough perspective to
// distinguish the two Y positions when both are shown.
$vpr = [82, 0, 0];

if (junction_step == "00_cs_body") {
    color("SteelBlue")
        clean_body();
}

else if (junction_step == "01_outer_L") {
    // This MUST be the complete L face the user marked in red.
    color("DeepSkyBlue")
        xz_layer("outer", W/2, display_thickness);
}

else if (junction_step == "02_inner_L") {
    // Complete L one ef inward.
    color("DarkOrange")
        xz_layer("inner", W/2 - ef, display_thickness);
}

else {
    // Both complete L inputs in their real Y positions.
    color("DeepSkyBlue", 0.65)
        xz_layer("outer", W/2, display_thickness);

    color("DarkOrange", 0.45)
        xz_layer("inner", W/2 - ef, display_thickness);
}

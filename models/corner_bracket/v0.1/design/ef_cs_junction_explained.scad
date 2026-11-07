// Corner Bracket: beam-style generic elephant-foot experiment.
//
// This version follows examples/hull_operations/v0.1/scad/hull_operations.scad
// literally:
//
//   1. Build the complete 3D bracket with cs.
//   2. Take its ACTUAL horizontal bottom footprint.
//   3. inset that footprint by ef.
//   4. keep the already-cs body from ef above the bottom upward.
//   5. hull those two 3D inputs.
//
// ef is therefore NOT applied to the L side profile.

/* [Demo] */
scene = "00_cs_result"; // [00_cs_result, 01_ef_inputs, 02_combined_result]

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
reach = 12;

// ---------- Base bracket, NO ef ----------

module inside_corner_2d(r) {
    difference() {
        translate([0, -r]) square([r, r]);
        translate([r, -r]) circle(r = r, $fn = 72);
    }
}

module bracket_profile_2d() {
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

module bracket_outer_2d() {
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

module bracket_raw() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            bracket_profile_2d();
}

// Same cs construction as production, but without production ef.
module cs_outline_2d() {
    // Extend downward so cs controls the side/end edges but does not define
    // the generic bottom relief itself; same principle as the beam demo.
    polygon([
        [armH, -armV - reach],
        [armH, t - c],
        [armH - c, t],
        [-t + ce, t],
        [-t, t - ce],
        [-t, -armV - reach]
    ]);
}

module cs_input_inner() {
    rotate([90, 0, 0])
        linear_extrude(height = W - 2 * cs, center = true)
            cs_outline_2d();
}

module cs_input_outer() {
    rotate([90, 0, 0])
        linear_extrude(height = W, center = true)
            offset(delta = -cs)
                cs_outline_2d();
}

module cs_hull() {
    hull() {
        cs_input_inner();
        cs_input_outer();
    }
}

module cs_body() {
    intersection() {
        bracket_raw();
        cs_hull();
    }
}

// ---------- ef: literal beam construction on the GLOBAL BOTTOM ----------

bottom_z = -armV;

// Actual XY footprint of the already-cs bracket at its lowest Z plane.
module cs_bottom_footprint_2d() {
    projection()
        intersection() {
            translate([0, 0, -bottom_z])
                cs_body();

            translate([-reach, -W, -eps / 2])
                cube([armH + t + 2 * reach, W * 2, eps]);
        }
}

// Lower ef input: actual cs bottom footprint, then ef inset.
module ef_input_bottom() {
    translate([0, 0, bottom_z])
        linear_extrude(height = eps)
            offset(delta = -ef)
                cs_bottom_footprint_2d();
}

// Upper ef input: the already-cs bracket from ef above its bottom upward.
module ef_input_upper_chamfered() {
    intersection() {
        cs_body();

        translate([-reach, -W, bottom_z + ef])
            cube([
                armH + t + 2 * reach,
                W * 2,
                armV + t + reach
            ]);
    }
}

module combined_hull() {
    hull() {
        ef_input_bottom();
        ef_input_upper_chamfered();
    }
}

module combined_body() {
    intersection() {
        bracket_raw();
        combined_hull();
    }
}

// ---------- scenes ----------

$vpr = [62, 0, 35];

if (scene == "00_cs_result") {
    color("SteelBlue")
        cs_body();
}

else if (scene == "01_ef_inputs") {
    color("SteelBlue", 0.55)
        ef_input_bottom();

    color("DarkOrange", 0.28)
        ef_input_upper_chamfered();
}

else {
    color("SteelBlue")
        combined_body();
}

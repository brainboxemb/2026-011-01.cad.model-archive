// Corner Bracket: derive ef from the working beam construction.
//
// Key idea:
//   the L bracket is TWO local beam cases at 90 degrees.
//
// Horizontal arm:
//   beam-style ef from its underside Z=0.
//
// Vertical arm:
//   same beam-style ef after rotating that arm so its inside face X=0
//   becomes a local Z=0 underside.
//
// Nothing special is invented for the L itself.
// The only special problem is how the two otherwise-working beam solutions
// meet at the inside corner.

/* [Demo] */
scene = "00_cs_body"; // [00_cs_body, 01_horizontal_inputs, 02_horizontal_hull, 03_vertical_inputs, 04_vertical_hull, 05_both_hulls]

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
display_gap = 3;

// -----------------------------------------------------------------------------
// Clean bracket with the normal cs geometry, NO ef.
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

module cs_outline_2d() {
    offset(delta = 0)
        outer_shape_2d();
}

module cs_envelope() {
    rotate([90, 0, 0])
        hull() {
            linear_extrude(height = W - 2 * cs, center = true)
                cs_outline_2d();

            linear_extrude(height = W, center = true)
                offset(delta = -cs)
                    cs_outline_2d();
        }
}

module cs_body() {
    intersection() {
        raw_body();
        cs_envelope();
    }
}

// -----------------------------------------------------------------------------
// Split ONLY for the explanation.
// Each arm is now treated exactly like the working beam demo.
// -----------------------------------------------------------------------------

module horizontal_arm() {
    intersection() {
        cs_body();

        // top/right arm, including a tiny overlap at the corner
        translate([-eps, -W, -eps])
            cube([armH + 2 * eps, 2 * W, t + 2 * eps]);
    }
}

module vertical_arm() {
    intersection() {
        cs_body();

        // down/left arm, including a tiny overlap at the corner
        translate([-t - eps, -W, -armV - eps])
            cube([t + 2 * eps, 2 * W, armV + 2 * eps]);
    }
}

// -----------------------------------------------------------------------------
// HORIZONTAL ARM = literal beam construction on Z=0.
// -----------------------------------------------------------------------------

module h_bottom_footprint_2d() {
    projection()
        intersection() {
            horizontal_arm();

            translate([-reach, -W, -eps / 2])
                cube([armH + 2 * reach, 2 * W, eps]);
        }
}

module h_ef_bottom() {
    linear_extrude(height = eps)
        offset(delta = -ef)
            h_bottom_footprint_2d();
}

module h_ef_upper() {
    intersection() {
        horizontal_arm();

        translate([-reach, -W, ef])
            cube([armH + 2 * reach, 2 * W, t + reach]);
    }
}

module h_ef_hull() {
    hull() {
        h_ef_bottom();
        h_ef_upper();
    }
}

// -----------------------------------------------------------------------------
// VERTICAL ARM = SAME construction after a 90-degree rotation.
//
// rotate([0,90,0]) maps original X=0 to local Z=0 and original X<0 to
// local Z>0. After the beam operation, rotate back.
// -----------------------------------------------------------------------------

module vertical_arm_local() {
    rotate([0, 90, 0])
        vertical_arm();
}

module v_bottom_footprint_2d() {
    projection()
        intersection() {
            vertical_arm_local();

            translate([-armV - reach, -W, -eps / 2])
                cube([armV + 2 * reach, 2 * W, eps]);
        }
}

module v_ef_bottom_local() {
    linear_extrude(height = eps)
        offset(delta = -ef)
            v_bottom_footprint_2d();
}

module v_ef_upper_local() {
    intersection() {
        vertical_arm_local();

        translate([-armV - reach, -W, ef])
            cube([armV + 2 * reach, 2 * W, t + reach]);
    }
}

module v_ef_hull_local() {
    hull() {
        v_ef_bottom_local();
        v_ef_upper_local();
    }
}

module v_ef_bottom() {
    rotate([0, -90, 0])
        v_ef_bottom_local();
}

module v_ef_upper() {
    rotate([0, -90, 0])
        v_ef_upper_local();
}

module v_ef_hull() {
    rotate([0, -90, 0])
        v_ef_hull_local();
}

// -----------------------------------------------------------------------------
// Scenes.
// Keep the whole L visible as a translucent reference.
// -----------------------------------------------------------------------------

$vpr = [90, 0, 0];

if (scene == "00_cs_body") {
    color("SteelBlue")
        cs_body();
}

else if (scene == "01_horizontal_inputs") {
    color("LightGray", 0.18)
        cs_body();

    // Display only: move the blue lower input downward so the two beam
    // inputs are visually separate. h_ef_hull() still uses the real position.
    color("DeepSkyBlue", 0.85)
        translate([0, 0, -display_gap])
            h_ef_bottom();

    color("DarkOrange", 0.42)
        h_ef_upper();
}

else if (scene == "02_horizontal_hull") {
    color("LightGray", 0.18)
        cs_body();

    color("SeaGreen", 0.80)
        h_ef_hull();
}

else if (scene == "03_vertical_inputs") {
    color("LightGray", 0.18)
        cs_body();

    // Display only: move the blue lower input to the right, i.e. outward
    // from the vertical arm's local beam bottom X=0.
    color("DeepSkyBlue", 0.85)
        translate([display_gap, 0, 0])
            v_ef_bottom();

    color("DarkOrange", 0.42)
        v_ef_upper();
}

else if (scene == "04_vertical_hull") {
    color("LightGray", 0.18)
        cs_body();

    color("SeaGreen", 0.80)
        v_ef_hull();
}

else {
    color("LightGray", 0.18)
        cs_body();

    color("SeaGreen", 0.75)
        h_ef_hull();

    color("DarkSeaGreen", 0.75)
        v_ef_hull();
}
